<#
.SYNOPSIS
    Shared code for the Deploy_*.ps1 wrappers. Dot-source it; don't run it.

.DESCRIPTION
    Builds the connection string (Windows auth for Dev, a saved SQL login for Prod), runs the
    migration runner (src/SosaFam.Database) for exactly the wrapper's migrations, and runs the
    wrapper's post-checks. The password never appears on a command line, in a file or in an
    environment variable: it is decrypted in memory, written to the runner's standard input
    (--connection-stdin), and used in-process by the post-checks.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:RunnerProject = Join-Path $script:RepoRoot 'src/SosaFam.Database'
$script:CredentialFolder = if ($env:APPDATA) { Join-Path $env:APPDATA 'SosaFam\DeployCredentials' } else { Join-Path $HOME '.sosafam/deploy-credentials' }

function Get-SosaFamCredential {
    param([Parameter(Mandatory)][string]$Name)
    $path = Join-Path $script:CredentialFolder "$Name.xml"
    if (-not (Test-Path $path)) {
        throw "No saved login '$Name'. Run .\Scripts\deploy\Save-DeployCredential.ps1 -Name $Name first."
    }
    Import-Clixml -Path $path
}

function New-SosaFamConnectionString {
    param(
        [Parameter(Mandatory)][string]$ServerInstance,
        [Parameter(Mandatory)][string]$Database,
        [pscredential]$Credential
    )
    $parts = @("Server=$ServerInstance", "Database=$Database", 'TrustServerCertificate=True', 'Application Name=SosaFam.Deploy')
    if ($Credential) {
        $parts += "User Id=$($Credential.UserName)"
        $parts += "Password=$($Credential.GetNetworkCredential().Password)"
    } else {
        $parts += 'Integrated Security=True'
    }
    $parts -join ';'
}

function Build-SosaFamRunner {
    # Build before the connection string exists, so no build process (or MSBuild node left
    # running afterwards) can ever see it.
    Write-Host 'Building the migration runner...'
    & dotnet build $script:RunnerProject -c Release -nologo -v quiet | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Building the migration runner failed (exit code $LASTEXITCODE)." }
    $dll = Join-Path $script:RunnerProject 'bin/Release/net8.0/SosaFam.Database.dll'
    if (-not (Test-Path $dll)) { throw "Built runner not found at $dll." }
    $dll
}

function Invoke-SosaFamRunner {
    param([Parameter(Mandatory)][string]$RunnerDll, [Parameter(Mandatory)][string]$ConnectionString, [string[]]$Arguments = @())
    # The connection string goes to the runner's standard input only: never an argument
    # (visible in the process list) and never an environment variable (inherited by children).
    $ConnectionString | & dotnet $RunnerDll --connection-stdin @Arguments | Out-Host
    return $LASTEXITCODE
}

function Invoke-SosaFamScalar {
    param([Parameter(Mandatory)][string]$ConnectionString, [Parameter(Mandatory)][string]$Query)
    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $command.ExecuteScalar()
    } finally {
        $connection.Dispose()
    }
}

function Invoke-SosaFamDeployment {
    <#
    .PARAMETER Plan       Exact migration names this wrapper deploys, in order.
    .PARAMETER Requires   Migrations that must already be applied.
    .PARAMETER PostChecks Ordered hashtable: description => SQL that returns 1 when the check passes.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('Dev', 'Prod')][string]$Environment,
        [Parameter(Mandatory)][string]$ServerInstance,
        [Parameter(Mandatory)][string]$Database,
        [Parameter(Mandatory)][string[]]$Plan,
        [string[]]$Requires = @(),
        [System.Collections.IDictionary]$PostChecks = @{},
        [string]$CredentialName,
        [pscredential]$Credential,
        [string]$ConfirmTarget,
        [switch]$WindowsAuth,
        [switch]$WhatIf
    )

    if ($Credential -and $CredentialName) { throw 'Use -Credential or -CredentialName, not both.' }
    if ($WindowsAuth -and ($Credential -or $CredentialName)) { throw 'Use -WindowsAuth or a credential, not both.' }

    if ($Environment -eq 'Prod' -and -not $Credential -and -not $WindowsAuth) {
        if (-not $CredentialName) { throw 'Prod needs -CredentialName Prod, -Credential (Get-Credential), or -WindowsAuth.' }
        $Credential = Get-SosaFamCredential -Name $CredentialName
    } elseif ($CredentialName -and -not $Credential) {
        $Credential = Get-SosaFamCredential -Name $CredentialName
    }

    $target = "$ServerInstance/$Database"
    $runnerDll = Build-SosaFamRunner
    $connectionString = New-SosaFamConnectionString -ServerInstance $ServerInstance -Database $Database -Credential $Credential

    Write-Host "Environment: $Environment    Target: $target"
    Write-Host 'Plan:'
    $Plan | ForEach-Object { Write-Host "  $_" }

    $runnerArgs = @()
    $Plan | ForEach-Object { $runnerArgs += @('--filter', $_) }
    $Requires | ForEach-Object { $runnerArgs += @('--require', $_) }

    if ($WhatIf) {
        $code = Invoke-SosaFamRunner -RunnerDll $runnerDll -ConnectionString $connectionString -Arguments ($runnerArgs + '--what-if')
        if ($code -ne 0) { throw "Preview failed (exit code $code)." }
        Write-Host 'Preview only. Nothing changed.'
        return
    }

    if ($Environment -eq 'Prod') {
        $typed = if ($ConfirmTarget) { $ConfirmTarget } else { Read-Host "Type $target to deploy to Prod" }
        if ($typed -ne $target) { throw "Target not confirmed ('$typed' is not '$target'). Nothing changed." }
    }

    $code = Invoke-SosaFamRunner -RunnerDll $runnerDll -ConnectionString $connectionString -Arguments $runnerArgs
    if ($code -ne 0) { throw "Deployment failed (exit code $code). See the output above." }

    Write-Host 'Post-checks:'
    $failed = 0
    foreach ($name in $Plan) {
        $q = "SELECT COUNT(*) FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'$($name.Replace("'", "''"))' AND [Success] = 1"
        $ok = [int](Invoke-SosaFamScalar -ConnectionString $connectionString -Query $q) -ge 1
        Write-Host ("  [{0}] {1} recorded in dbo.SchemaVersion" -f ($(if ($ok) { 'ok' } else { 'FAIL' })), $name)
        if (-not $ok) { $failed++ }
    }
    foreach ($check in $PostChecks.GetEnumerator()) {
        $ok = [int](Invoke-SosaFamScalar -ConnectionString $connectionString -Query $check.Value) -eq 1
        Write-Host ("  [{0}] {1}" -f ($(if ($ok) { 'ok' } else { 'FAIL' })), $check.Key)
        if (-not $ok) { $failed++ }
    }
    if ($failed -gt 0) { throw "$failed post-check(s) failed." }
    Write-Host "Done: $target is up to date for this change." -ForegroundColor Green
}
