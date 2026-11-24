# Scripts

```
Scripts/
├── deploy/      Deployment: one wrapper per change, the shared module, credentials
├── Rollback/    Rollback scripts too long for a migration's ROLLBACK SCRIPT block
└── Tests/       Unit tests: Tests/<ObjectType>/<schema>/<Object>_Tests.sql
```

## deploy/

| File | What it does |
|---|---|
| `DeployCommon.ps1` | Shared code: connection strings, saved logins, preview, Prod confirmation, post-checks |
| `Save-DeployCredential.ps1` | Saves a SQL login, encrypted for your Windows account (`-Name Prod`) |
| `Deploy_Migrations.ps1` | Applies everything pending. Local Dev only. |
| `Deploy_Baseline.ps1` | The `00000000_*` baseline, for a new database or one the old DbUp runner built |
| `_TEMPLATE_Deploy_Change.ps1` | Copy to `Deploy_<Change>.ps1` for each new change |

Every wrapper takes `-Environment Dev|Prod`, `-ServerInstance`, `-Database`, `-CredentialName` or `-Credential`, `-ConfirmTarget` and `-WhatIf`. See [docs/Deploying-Migrations.md](../docs/Deploying-Migrations.md).

## Rollback/

Name: `Rollback_<MigrationName>.sql`. Header, transaction, refuse to drop data that has rows, delete the migration's `dbo.SchemaVersion` row last. Run only with a backup, and on Prod only with an explicit go.

## Tests/

Each test is a plain `sqlcmd` script that sets up its own data, checks with `THROW` on failure, cleans up, and prints `PASS: ...`. Run with `sqlcmd -b` so a failure sets the exit code. Today: `Tests/Policies/security/HouseholdIsolation_Tests.sql`.
