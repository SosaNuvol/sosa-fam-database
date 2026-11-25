# Passwordless production deploys with a saved credential

Adapted for sosa-fam-database from the deploy standard used in our other projects. [Deploying-Migrations.md](Deploying-Migrations.md) has the step-by-step deploy; this page covers the Prod login.

## The idea

You save the Prod SQL login once on your PC. Every Prod deploy loads it with `-CredentialName Prod`. Nobody types or pastes the password again, and Claude never sees it.

## Set it up (once per PC)

1. Create a login for this project and environment only, for example `sosafam_deploy`, and make it `db_owner` of Prod `SOS_FAMILY` only. Don't use `sa` and don't reuse another project's login.
2. Save it:
   ```powershell
   .\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod
   ```
   It's saved to `%APPDATA%\SosaFam\DeployCredentials\Prod.xml` with `Export-Clixml`, which encrypts the password with Windows DPAPI: only your Windows account on this PC can read it. Copying the file to another PC or account doesn't work.
3. Preview a deploy to check it:
   ```powershell
   .\Scripts\deploy\Deploy_Baseline.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf
   ```

## How the password is handled

- Decrypted in memory only, inside the deploy script.
- The runner is built **before** the connection string exists, so no build process or leftover MSBuild node can inherit it.
- The connection string goes to the runner on standard input (`--connection-stdin`). It is never a command-line argument (visible in the process list), never an environment variable (inherited by every child process), and never written to a file.
- Post-checks use it in-process through `System.Data.SqlClient`.
- Never `sqlcmd.exe -P`. Never `SOSAFAM_DB_CONNECTION` for Prod.
- Pass `-Credential` or `-CredentialName`, not both; the script refuses.

## The Prod guard

Every Prod deploy is a `-WhatIf` preview first, then the real run, which asks you to type `<server>/SOS_FAMILY`. `-ConfirmTarget '<server>/SOS_FAMILY'` answers that prompt and is only used after your explicit go.

## Rules for Claude

- Prod only through a Remote Control session on your PC, using your saved `Prod` login.
- Never read, print, log or copy the password, and never open the `.xml` file.
- Never ask for the password in chat. If the login is missing or rejected, ask you to run `Save-DeployCredential.ps1 -Name Prod` yourself.
- Before Prod: Dev first, PR merged, deploy from `main` in sync with `origin/main`, and a current backup of Prod `SOS_FAMILY`.
- Show you the exact command and the `-WhatIf` output, then wait for your explicit go. That go is what allows `-ConfirmTarget`.
- On any failure: stop and report. No retry, no rollback on its own.

## Check, rotate, revoke

- **Check it exists:** `Test-Path "$env:APPDATA\SosaFam\DeployCredentials\Prod.xml"` (don't open it).
- **Rotate:** change the login's password in SQL Server, then rerun `Save-DeployCredential.ps1 -Name Prod`.
- **Revoke:** delete `Prod.xml`, and disable or drop the login in SQL Server.

## Troubleshooting

| Message | What to do |
|---|---|
| No saved login 'Prod' | Run `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod`. |
| Login failed for user ... | The saved password is out of date or the login lacks access: rerun `Save-DeployCredential.ps1 -Name Prod`, and check the login is `db_owner` of `SOS_FAMILY`. |
| Key not valid for use in specified state | The file was saved by another Windows account or PC: save it again on this one. |
| Use -Credential or -CredentialName, not both. | Pass only one. |
| Canceled. Nothing saved. | You closed the login prompt; run it again. |

## Security notes

- One login per project and environment, with only the rights the deploy needs.
- The saved file protects against other accounts and other PCs, not against code running as you. Only run deploy scripts from this repository's `main`.
- Never commit `.xml` credential files; they live outside the repository.
