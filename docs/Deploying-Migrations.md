# Deploying migrations

| | Server | Database | Login |
|---|---|---|---|
| **Dev** | the SQL Server on Andres's PC (`localhost` by default) | `SOS_FAMILY` | Windows auth (your account) |
| **Prod** | the family's SQL Server | `SOS_FAMILY` | a saved SQL deploy login or Windows auth, see [The Prod login](#the-prod-login) |

A migration always goes to Dev first; the API is then built and tested against Dev; only after the PRs merge does it go to Prod.

Each change goes out through its own wrapper, `Scripts/deploy/Deploy_<Change>.ps1`. `Deploy_Migrations.ps1` applies everything pending and is only for catching Dev up: it refuses any server that isn't local.

You need the .NET 8 SDK (the wrappers call the runner in `src/SosaFam.Database`) and PowerShell 7 or Windows PowerShell 5.1.

## What a wrapper does

A wrapper names its exact migrations (its plan) and calls the runner with them. Around that it:

- stops if a migration it depends on isn't recorded in `dbo.SchemaVersion`;
- with `-WhatIf`, lists what would run and changes nothing;
- for Prod, asks you to type `<server>/<database>` (or takes it from `-ConfirmTarget`);
- afterwards checks each migration is recorded and runs its post-checks (`[ok]` or `[FAIL]`).

Copy `Scripts/deploy/_TEMPLATE_Deploy_Change.ps1` to make one, and fill in the plan, prerequisites and post-checks.

## Deploying to Dev

1. **Get the migration.** Use a branch or worktree that has the new `Migrations/YYYYMMDD_HHMM_*.sql` and its wrapper. To test an unmerged branch without disturbing your main checkout:
   ```powershell
   cd D:\CodeBaseNVL9\sosa-fam-database
   git fetch origin <branch>
   git worktree add ..\sosa-fam-database-<feature> origin/<branch>
   cd ..\sosa-fam-database-<feature>
   ```
2. **Preview.** Connects with Windows auth to `localhost` / `SOS_FAMILY`, checks prerequisites and lists what would run.
   ```powershell
   .\Scripts\deploy\Deploy_<Change>.ps1 -Environment Dev -WhatIf
   ```
   Add `-ServerInstance <name>` if your instance isn't the default one (for example `localhost\SQLEXPRESS`).
3. **Run.** The same command without `-WhatIf`. Every post-check must be `[ok]`.
4. **Test the API** against Dev (sosa-fam-api: `dotnet test` with `SOSAFAM_TEST_DB` set, and a manual run of the app).
5. **Clean up** after the PR merges: `git worktree remove ..\sosa-fam-database-<feature>` and `git pull` in the main checkout.

A migration runs in one transaction with `XACT_ABORT ON`, so one that fails part-way rolls back and isn't recorded. Fix it on the branch and rerun: recorded migrations are skipped, so a rerun is safe.

To check a migration against a copy of the data, restore a backup of `SOS_FAMILY` as `SOS_FAMILY_TEST` and pass `-Database SOS_FAMILY_TEST`. Drop the copy afterwards.

### Catching Dev up

```powershell
.\Scripts\deploy\Deploy_Migrations.ps1 -WhatIf
.\Scripts\deploy\Deploy_Migrations.ps1
```

`-MigrationFilter <name>` runs one migration; `-MigrationFilter 20261125*` runs every pending migration from that day.

### Building an empty database

```powershell
sqlcmd -S localhost -E -Q "CREATE DATABASE [SOS_FAMILY]"
.\Scripts\deploy\Deploy_Baseline.ps1 -Environment Dev
.\Scripts\deploy\Deploy_Migrations.ps1
```

`Deploy_Baseline.ps1` creates `dbo.SchemaVersion` and the baseline (sign-in, households, row-level security, the API role, grocery lists). On a database the old DbUp runner built (it has `dbo.SchemaVersions`), it only creates `dbo.SchemaVersion` and records the five baseline migrations as already applied; nothing else changes. `20261125_1849_DropDBO_SchemaVersions` then removes the old `dbo.SchemaVersions`.

### The API's login

Created once per environment by an admin, never in a migration or in this repository:

```sql
CREATE LOGIN [sosafam_api_login] WITH PASSWORD = '<strong password>';
USE [SOS_FAMILY];
CREATE USER [sosafam_api_user] FOR LOGIN [sosafam_api_login];
ALTER ROLE [sosafam_api] ADD MEMBER [sosafam_api_user];
```

The API reads its connection string from .NET user secrets (Dev) or the host's secret store (Prod).

### Troubleshooting

| Message | What to do |
|---|---|
| `dotnet` is not recognized | Install the .NET 8 SDK. |
| Stopping: prerequisites are not applied | Deploy the listed migrations first, with their own wrappers. |
| The migration ran but did not record itself | The migration is missing its `dbo.SchemaVersion` insert. Fix the migration (it rolled back only if it threw; check the objects). |
| No saved login 'Prod' | `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod` |
| Login failed (Prod) | The saved password is out of date: rerun `Save-DeployCredential.ps1 -Name Prod`. |
| Deploy_Migrations.ps1 is for your local Dev instance only | Use the change's own wrapper. |

## Deploying to Prod

1. **Merge first.** Run from the main checkout, on `main`, in sync with `origin/main`, with no uncommitted changes to the migration.
2. **Dev.** It is already on Dev with every post-check `[ok]`.
3. **Backup.** Confirm a current, restorable backup of Prod `SOS_FAMILY`.
4. **Preview.**
   ```powershell
   .\Scripts\deploy\Deploy_<Change>.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf
   ```
   It must list only the migration(s) you mean to deploy, and no missing prerequisites.
5. **Run.** The same command without `-WhatIf`. Type `<server>/SOS_FAMILY` at the prompt.
6. **Check** the post-checks. Keep the console output with the PR.
7. **Then the apps.** Release the API version that uses the change only after the migration is on Prod.

The first Prod deployment is `Deploy_Baseline.ps1 -Environment Prod ...` into an empty `SOS_FAMILY`, followed by each change's wrapper in order.

## The Prod login

Never put a password on a command line, in a file in this repository, or in chat.

- **Saved login (recommended):** run `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod` once. It's saved to `%APPDATA%\SosaFam\DeployCredentials\Prod.xml`, encrypted with Windows DPAPI so only your Windows account on that PC can read it. Wrappers load it with `-CredentialName Prod`, decrypt it in memory, and pass the connection string to the runner's process only, clearing it when the run ends. Rerun after the password changes.
- **Prompt:** `-Credential (Get-Credential)` instead of `-CredentialName`.
- **Windows authentication:** if your Windows account is a `db_owner` of Prod `SOS_FAMILY`, pass `-WindowsAuth` instead of a credential.
- Don't keep the password in an environment variable: every process you start inherits it.

## When Claude runs it

Claude runs the wrapper through a Remote Control session on your PC, which uses your saved `Prod` login; it never reads or prints the password. Before touching Prod it shows you the exact command and the `-WhatIf` result, and it runs the real deploy only after your explicit go for that change. Your go is also what lets it pass `-ConfirmTarget '<server>/SOS_FAMILY'`. If anything fails it stops and reports; it doesn't retry or roll back on its own.
