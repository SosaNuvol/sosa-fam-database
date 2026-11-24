# Quickstart

## 1. Tools

- .NET 8 SDK
- SQL Server 2016 or later (row-level security), or Docker for a local one
- PowerShell 7 (or Windows PowerShell 5.1) for the deploy wrappers
- `sqlcmd` for running tests

A throwaway SQL Server in Docker:

```bash
docker run -d --name sosafam-sql -e ACCEPT_EULA=Y -e 'MSSQL_SA_PASSWORD=<dev password>' -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
```

## 2. Build a database

```bash
dotnet run --project src/SosaFam.Database -- --ensure-database "Server=localhost,1433;Database=Scratch;User Id=sa;Password=<dev password>;TrustServerCertificate=True"
```

Or on Windows against your Dev instance:

```powershell
.\Scripts\deploy\Deploy_Baseline.ps1 -Environment Dev -WhatIf
.\Scripts\deploy\Deploy_Baseline.ps1 -Environment Dev
```

Check what is applied:

```bash
dotnet run --project src/SosaFam.Database -- --list "<connection string>"
```

## 3. Make your first change

1. Open an issue describing the change.
2. Branch: `git checkout -b <area>/<short-name>`.
3. Get a UTC timestamp: `date -u +%Y%m%d_%H%M` (PowerShell: `(Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmm')`).
4. Copy `Migrations/_TEMPLATE_Migration.sql` to `Migrations/<timestamp>_<Verb><SCHEMA>_<What>.sql` and fill it in.
5. Add or update the current-state file(s): `Tables/<schema>/<Table>.sql`, `Indexes/...`, and for household data `SecurityPolicies/security/HouseholdIsolation.sql` and the isolation test.
6. Copy `Scripts/deploy/_TEMPLATE_Deploy_Change.ps1` to `Deploy_<Change>.ps1` and fill in the plan and post-checks.
7. Test on a scratch database: run the runner twice (the second run must skip), run `Scripts/Tests/`.
8. Commit (`[Feature]: ...` with `- Migration:` and `- Affects:` lines), push, open a PR that closes the issue.
9. After review, deploy to Dev with the wrapper; after merge, to Prod.

## 4. Where to look next

[DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md) for the rules, [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for names and templates, [docs/Deploying-Migrations.md](docs/Deploying-Migrations.md) for deployments.
