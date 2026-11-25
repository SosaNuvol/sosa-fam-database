<#
.SYNOPSIS
    Deploys <change>: copy this file to Deploy_<Change>.ps1 and fill in the plan and checks.

.EXAMPLE
    .\Scripts\deploy\Deploy_<Change>.ps1 -Environment Dev -WhatIf
    .\Scripts\deploy\Deploy_<Change>.ps1 -Environment Dev
    .\Scripts\deploy\Deploy_<Change>.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf
#>
param(
    [Parameter(Mandatory)][ValidateSet('Dev', 'Prod')][string]$Environment,
    [string]$ServerInstance = 'localhost',
    [string]$Database = 'SOS_FAMILY',
    [string]$CredentialName,
    [pscredential]$Credential,
    [string]$ConfirmTarget,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DeployCommon.ps1')

# The exact migration file names (without .sql) this change deploys, in order.
$plan = @(
    'YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>'
)

# Migrations that must already be applied.
$requires = @(
    '00000000_0005_Baseline_FamilyGroceryLists'
)

# Each query returns 1 when the check passes.
$postChecks = [ordered]@{
    'Table <schema>.<Table> exists' = "SELECT CASE WHEN OBJECT_ID(N'[<schema>].[<Table>]', N'U') IS NULL THEN 0 ELSE 1 END"
}

Invoke-SosaFamDeployment -Environment $Environment -ServerInstance $ServerInstance -Database $Database `
    -Plan $plan -Requires $requires -PostChecks $postChecks -CredentialName $CredentialName `
    -Credential $Credential -ConfirmTarget $ConfirmTarget -WhatIf:$WhatIf
