<#
.SYNOPSIS
    Builds the baseline (SchemaVersion table, auth, core, row-level security, API role, grocery
    lists) in an empty database, or records it in a database the old DbUp runner built.

.EXAMPLE
    .\Scripts\deploy\Deploy_Baseline.ps1 -Environment Dev -WhatIf
    .\Scripts\deploy\Deploy_Baseline.ps1 -Environment Dev
    .\Scripts\deploy\Deploy_Baseline.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf
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
    '00000000_0000_CreateSchemaVersionTable',
    '00000000_0001_Baseline_AuthIdentity',
    '00000000_0002_Baseline_CoreHouseholds',
    '00000000_0003_Baseline_CoreRowLevelSecurity',
    '00000000_0004_Baseline_AppRole',
    '00000000_0005_Baseline_FamilyGroceryLists'
)

$postChecks = [ordered]@{
    'Table auth.AspNetUsers exists'              = "SELECT CASE WHEN OBJECT_ID(N'[auth].[AspNetUsers]', N'U') IS NULL THEN 0 ELSE 1 END"
    'Table core.Households exists'               = "SELECT CASE WHEN OBJECT_ID(N'[core].[Households]', N'U') IS NULL THEN 0 ELSE 1 END"
    'Table family.GroceryItems exists'           = "SELECT CASE WHEN OBJECT_ID(N'[family].[GroceryItems]', N'U') IS NULL THEN 0 ELSE 1 END"
    'Policy security.HouseholdIsolation is on'   = "SELECT COUNT(*) FROM sys.security_policies WHERE [name] = N'HouseholdIsolation' AND [is_enabled] = 1"
    'Role sosafam_api exists'                    = "SELECT CASE WHEN DATABASE_PRINCIPAL_ID(N'sosafam_api') IS NULL THEN 0 ELSE 1 END"
}

Invoke-SosaFamDeployment -Environment $Environment -ServerInstance $ServerInstance -Database $Database `
    -Plan $plan -PostChecks $postChecks -CredentialName $CredentialName -Credential $Credential `
    -ConfirmTarget $ConfirmTarget -WindowsAuth:$WindowsAuth -WhatIf:$WhatIf
