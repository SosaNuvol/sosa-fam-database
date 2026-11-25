<#
.SYNOPSIS
    Drops the old DbUp journal dbo.SchemaVersions (migration 20261125_1849_DropDBO_SchemaVersions).

.EXAMPLE
    .\Scripts\deploy\Deploy_DropDBO_SchemaVersions.ps1 -Environment Dev -WhatIf
    .\Scripts\deploy\Deploy_DropDBO_SchemaVersions.ps1 -Environment Dev
    .\Scripts\deploy\Deploy_DropDBO_SchemaVersions.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf
#>
param(
    [Parameter(Mandatory)][ValidateSet('Dev', 'Prod')][string]$Environment,
    [string]$ServerInstance = 'localhost',
    [string]$Database = 'SOS_FAMILY',
    [string]$CredentialName,
    [pscredential]$Credential,
    [string]$ConfirmTarget,
    [switch]$WindowsAuth,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DeployCommon.ps1')

$plan = @(
    '20261125_1849_DropDBO_SchemaVersions'
)

$requires = @(
    '00000000_0000_CreateSchemaVersionTable'
)

$postChecks = [ordered]@{
    'Old DbUp table dbo.SchemaVersions is gone' = "SELECT CASE WHEN OBJECT_ID(N'[dbo].[SchemaVersions]', N'U') IS NULL THEN 1 ELSE 0 END"
    'All six baseline migrations still recorded' = "SELECT CASE WHEN COUNT(*) = 6 THEN 1 ELSE 0 END FROM [dbo].[SchemaVersion] WHERE [MigrationName] LIKE N'00000000[_]000[0-5][_]%' AND [Success] = 1"
}

Invoke-SosaFamDeployment -Environment $Environment -ServerInstance $ServerInstance -Database $Database `
    -Plan $plan -Requires $requires -PostChecks $postChecks -CredentialName $CredentialName `
    -Credential $Credential -ConfirmTarget $ConfirmTarget -WindowsAuth:$WindowsAuth -WhatIf:$WhatIf
