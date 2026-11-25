<#
.SYNOPSIS
    Deploys the food storage app's core tables: the UTL, MAC and PAN schemas, the Proxy-ID
    infrastructure, and PAN.Locations, PAN.Products, PAN.StockLevels and PAN.StockChanges
    (migrations 20261125_1900 to 20261125_1907).

.EXAMPLE
    .\Scripts\deploy\Deploy_PantryCore.ps1 -Environment Dev -WhatIf
    .\Scripts\deploy\Deploy_PantryCore.ps1 -Environment Dev
    .\Scripts\deploy\Deploy_PantryCore.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf
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
    '20261125_1900_CreateUTL_Schema'
    '20261125_1901_CreateMAC_Schema'
    '20261125_1902_CreatePAN_Schema'
    '20261125_1903_CreateMAC_ProxyIdInfrastructure'
    '20261125_1904_CreatePAN_Locations'
    '20261125_1905_CreatePAN_Products'
    '20261125_1906_CreatePAN_StockLevels'
    '20261125_1907_CreatePAN_StockChanges'
)

$requires = @(
    '00000000_0004_Baseline_AppRole'
    '00000000_0005_Baseline_FamilyGroceryLists'
)

$postChecks = [ordered]@{
    'Schemas UTL, MAC and PAN exist' = "SELECT CASE WHEN COUNT(*) = 3 THEN 1 ELSE 0 END FROM sys.schemas WHERE [name] IN (N'UTL', N'MAC', N'PAN')"
    'Proxy-ID objects exist' = "SELECT CASE WHEN COUNT(*) = 5 THEN 1 ELSE 0 END FROM sys.objects WHERE [object_id] IN (OBJECT_ID(N'[UTL].[fxGetPartKey]'), OBJECT_ID(N'[MAC].[vwTableTypesAndPrefixes]'), OBJECT_ID(N'[MAC].[fxGeneratePrefixParts]'), OBJECT_ID(N'[MAC].[fxGeneratePrefixProxy]'), OBJECT_ID(N'[MAC].[fxGetPrefixTypeIdFromProxy]'))"
    'PartKey is the hex of the current UTC year and month' = "SELECT CASE WHEN [UTL].[fxGetPartKey]() = SUBSTRING(CONVERT(VARCHAR(10), CAST((YEAR(SYSUTCDATETIME()) * 100) + MONTH(SYSUTCDATETIME()) AS VARBINARY(4)), 1), 6, 6) THEN 1 ELSE 0 END"
    'Four PAN tables exist' = "SELECT CASE WHEN COUNT(*) = 4 THEN 1 ELSE 0 END FROM sys.tables WHERE SCHEMA_NAME([schema_id]) = N'PAN' AND [name] IN (N'Locations', N'Products', N'StockLevels', N'StockChanges')"
    'Every PAN table is in security.HouseholdIsolation (filter + 2 block predicates)' = "SELECT CASE WHEN COUNT(*) = 12 THEN 1 ELSE 0 END FROM sys.security_predicates WHERE OBJECT_SCHEMA_NAME([target_object_id]) = N'PAN'"
    'sosafam_api can use PAN' = "SELECT CASE WHEN COUNT(*) = 4 THEN 1 ELSE 0 END FROM sys.database_permissions WHERE [class_desc] = N'SCHEMA' AND [major_id] = SCHEMA_ID(N'PAN') AND [grantee_principal_id] = DATABASE_PRINCIPAL_ID(N'sosafam_api') AND [state] = 'G'"
}

Invoke-SosaFamDeployment -Environment $Environment -ServerInstance $ServerInstance -Database $Database `
    -Plan $plan -Requires $requires -PostChecks $postChecks -CredentialName $CredentialName `
    -Credential $Credential -ConfirmTarget $ConfirmTarget -WindowsAuth:$WindowsAuth -WhatIf:$WhatIf
