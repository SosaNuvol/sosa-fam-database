<#
.SYNOPSIS
    Saves a SQL login for deployments, encrypted for your Windows account only.

.EXAMPLE
    .\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod

.NOTES
    The file is %APPDATA%\SosaFam\DeployCredentials\<Name>.xml. On Windows, Export-Clixml
    encrypts the password with DPAPI, so only your account on this computer can read it.
    Rerun after the password changes. Never put the password in a command, a file in this
    repository, an environment variable or chat.
#>
param([Parameter(Mandatory)][string]$Name)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DeployCommon.ps1')

$credential = Get-Credential -Message "SQL login for the '$Name' deployments"
New-Item -ItemType Directory -Force -Path $script:CredentialFolder | Out-Null
$path = Join-Path $script:CredentialFolder "$Name.xml"
$credential | Export-Clixml -Path $path
Write-Host "Saved login '$($credential.UserName)' as '$Name' in $path"
