<#
.SYNOPSIS
    Applies every pending migration. DEV ONLY: for catching a Dev database up.

.DESCRIPTION
    Use a change's own Deploy_<Change>.ps1 wrapper for anything that goes to Prod. This script
    refuses to run against Prod because it would apply every pending migration at once.

.EXAMPLE
    .\Scripts\deploy\Deploy_Migrations.ps1 -WhatIf
    .\Scripts\deploy\Deploy_Migrations.ps1
    .\Scripts\deploy\Deploy_Migrations.ps1 -MigrationFilter 20261125_1400_CreatePAN_PantryItems
#>
param(
    [string]$ServerInstance = 'localhost',
    [string]$Database = 'SOS_FAMILY',
    [string[]]$MigrationFilter = @(),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DeployCommon.ps1')

if ($ServerInstance -notmatch '^(localhost|\.|\(local\)|127\.0\.0\.1)(\\|,|$)' -and $ServerInstance -ne $env:COMPUTERNAME) {
    throw "Deploy_Migrations.ps1 is for your local Dev instance only. Use the change's Deploy_*.ps1 wrapper for $ServerInstance."
}

$connectionString = New-SosaFamConnectionString -ServerInstance $ServerInstance -Database $Database
$runnerArgs = @()
$MigrationFilter | ForEach-Object { $runnerArgs += @('--filter', $_) }
if ($WhatIf) { $runnerArgs += '--what-if' }

$runnerDll = Build-SosaFamRunner
$code = Invoke-SosaFamRunner -RunnerDll $runnerDll -ConnectionString $connectionString -Arguments $runnerArgs
exit $code
