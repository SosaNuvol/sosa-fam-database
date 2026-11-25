# Development guide

How to work on the Sosa Fam database day to day. The rules are in [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md); this guide shows how to apply them.

## Reading order

1. [QUICKSTART.md](QUICKSTART.md)
2. [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md)
3. [STRUCTURE.md](STRUCTURE.md)
4. [docs/Deploying-Migrations.md](docs/Deploying-Migrations.md)
5. [.github/ProxyID-PrefixRegistry.md](.github/ProxyID-PrefixRegistry.md) before your first Proxy-enabled table

## The loop

```
issue → branch → migration → current-state files → deploy wrapper → scratch test → PR → Dev → API test → merge → Prod
```

## Writing a migration

1. Timestamp in UTC. Two migrations in the same minute? Add a minute to the later one.
2. Name it for what it does: `Create`, `Add`, `Alter`, `Drop`, `Rename`, `Seed`, `Backfill`, `Grant`, then the schema code, then the object: `20261125_1400_CreatePAN_PantryItems`.
3. Copy `Migrations/_TEMPLATE_Migration.sql`. Keep its structure exactly; fill every header line (`Dependencies` names the migrations it needs; `Expected impact` says what users or the API will notice, and whether it locks a big table).
4. Guard each statement so a half-applied database can still run it.
5. Statements that must start a batch (`CREATE VIEW/FUNCTION/PROCEDURE/TRIGGER`, `ALTER SECURITY POLICY`) go in `EXEC(N'...')` under a guard. Double every single quote inside.
6. Write the rollback block: the exact SQL that undoes it, refusing to drop data that has rows.
7. One logical change per migration. A new schema, its tables and its policy entries for one feature are one change; a new table and an unrelated column are two.

## Common changes

**New schema for an app.** Register the code in `Schemas/README.md`; migration `CreatePAN_Schema` creates it and grants `sosafam_api`; add `Schemas/PAN/schema.sql` and update `Grants/`.

**New household table.** Use the template in [.github/copilot-instructions.md](.github/copilot-instructions.md). Then the four household steps: predicates, policy file, test, grant.

**New column.** `IF COL_LENGTH(...) IS NULL ALTER TABLE ... ADD ...`. For `NOT NULL` on a table with rows: add with a named default, or add `NULL`, backfill, then `ALTER COLUMN ... NOT NULL`. Update the table file.

**Rename.** `EXEC sp_rename` under a guard, in its own migration, with the API change ready to ship right after. Prefer add-new, copy, switch the API, drop-old across releases.

**Changing a row-level security function.** The policy is schema-bound to it. In one migration: drop the predicates that use it, alter the function, add the predicates back. Update both current-state files and run the isolation test.

**Procedures, views, functions.** Create with `CREATE OR ALTER` in the migration and keep the current-state file identical.

## Working with the API

- The API (sosa-fam-api) maps tables with EF Core and sets `SESSION_CONTEXT` on each connection. A new table needs its EF entity, a global household query filter (`IHouseholdScoped`), and endpoints behind the household route filter.
- New tables keep the database's column names; the API maps them, it does not rename them.
- Ship order: migration to Dev → API against Dev → merge both → migration to Prod → API to Prod.

## Testing

- Every migration: run the runner twice on a scratch database; the second run must report nothing to apply.
- Household tables: extend `Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql` so household B can neither see nor change household A's rows in the new table.
- Procedures: a test script in `Scripts/Tests/Procedures/<schema>/<sp>_Tests.sql` that sets the session context, calls it, and checks the result.
- The API's integration tests (`SOSAFAM_TEST_DB`) run against a database built by the runner.

## Where Sosa Fam differs from Solasta

| Topic | Solasta | Sosa Fam | Why |
|---|---|---|---|
| Tenant | `ACC.DealerTenants`, tenant-guard triggers | `core.Households`, SQL Server row-level security | RLS filters every query and blocks cross-household writes in one place |
| Session | `ACC.spSessionContextCreate` | The API sets `UserId`, `HouseholdId`, `IsSystem` read-only | Same idea, set by the API's connection interceptor |
| Runner | `Deploy_Migrations.ps1` with `Invoke-Sqlcmd` | `src/SosaFam.Database` (.NET) called by the PowerShell wrappers | Runs on Windows, Linux and CI the same way |
| Security policies | none | `SecurityPolicies/` folder, deployed after functions | Needed for RLS |
| Baseline | `20260313_0845_Baseline_*` | `00000000_0000` to `00000000_0005` | The first five scripts predate the standards |
