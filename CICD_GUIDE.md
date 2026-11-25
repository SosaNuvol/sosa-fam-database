# CI/CD guide

There is no pipeline yet. This is the plan, so it can be added without changing how anyone works.

## Pull request checks (GitHub Actions)

On every PR that touches `Migrations/`, object folders, `Scripts/` or `src/`:

1. **Build** the runner: `dotnet build src/SosaFam.Database`.
2. **Lint** migrations:
   - file names match `^\d{8}_\d{4}_[A-Za-z]+_[A-Za-z0-9]+\.sql$` (the baseline `00000000_000x_Baseline_*` names are allowed);
   - each new migration has the header, `BEGIN TRANSACTION`, the `SchemaVersion` check and insert, and `ROLLBACK SCRIPT`;
   - `@MigrationName` equals the file name;
   - no existing migration changed (`git diff --name-status origin/main -- Migrations/` shows only `A`);
   - no `SELECT *`, `DATETIME `, `TEXT`, `NTEXT`, `IMAGE` in new SQL.
3. **Apply** to SQL Server in a service container:
   ```yaml
   services:
     mssql:
       image: mcr.microsoft.com/mssql/server:2022-latest
       env: { ACCEPT_EULA: Y, MSSQL_SA_PASSWORD: ${{ secrets.CI_SA_PASSWORD }} }
       ports: ["1433:1433"]
   ```
   Run the runner with `--ensure-database`, then again (it must apply nothing).
4. **Test**: every file in `Scripts/Tests/` with `sqlcmd -b`.
5. **Current state matches**: build a second database from the current-state files in deployment order and compare the catalog (columns, indexes, constraints, predicates, grants) with the migrated one.

The SA password for CI lives in a repository secret, never in the workflow file.

## Deployments

Deployments stay manual and go through the wrappers ([docs/Deploying-Migrations.md](docs/Deploying-Migrations.md)): Dev on Andres's PC, Prod after merge with a backup and an explicit go. A later pipeline may run the Prod wrapper from a protected environment that requires approval, using the same `-WhatIf` preview first.
