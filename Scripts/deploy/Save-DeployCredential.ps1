<#
.SYNOPSIS
    Saves a SQL login for deployments, encrypted for your Windows account only.

.DESCRIPTION
    Run it yourself, once per environment, and again after the password changes. Claude never
    runs it, never asks for the password, and never opens the saved file.

.EXAMPLE
    .\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod

.NOTES
    The file is %APPDATA%\SosaFam\DeployCredentials\<Name>.xml. On Windows, Export-Clixml
    encrypts the password with DPAPI, so only your account on this computer can read it.
    Use a login made for this project and environment (db_owner on SOS_FAMILY only, not sa).
    Never put the password in a command, a file in this repository, an environment variable or chat.
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$Name
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DeployCommon.ps1')

$credential = Get-Credential -Message "SQL login for the SosaFam '$Name' deployments"
if (-not $credential) {
    Write-Host 'Canceled. Nothing saved.'
    exit 1
}

New-Item -ItemType Directory -Force -Path $script:CredentialFolder | Out-Null
$path = Join-Path $script:CredentialFolder "$Name.xml"
$credential | Export-Clixml -Path $path
Write-Host "Saved login '$($credential.UserName)' as '$Name' in $path"
Write-Host "Use it with: -CredentialName $Name"
