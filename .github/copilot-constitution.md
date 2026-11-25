# Sosa Fam Database: Agent Constitution

> Binding rules for GitHub Copilot, Claude and any other agent that writes, suggests or reviews code in this repository. They restate [DATABASE_CONSTITUTION.md](../DATABASE_CONSTITUTION.md) as instructions. If anything here seems to conflict with it, DATABASE_CONSTITUTION.md wins.

## Article I: Inviolable principles

1. `Migrations/` is the source of truth. Object folders are current-state documentation. Answer history questions from migrations.
2. Never modify an existing migration. If asked to "fix" one, write a corrective migration with a later timestamp.
3. Every script is idempotent: existence checks on every DDL statement, `MERGE` or guarded `INSERT` for data.
4. One migration is one logical change, inside `BEGIN TRANSACTION` with `TRY...CATCH` and `XACT_ABORT ON`.
5. No SQL file without its header block. No migration without its rollback block.
6. Every household-owned table gets `HouseholdId`, the `security.HouseholdIsolation` predicates, a test and a `sosafam_api` grant, in the same migration.

## Article II: Absolute prohibitions

- Credentials, connection strings, server names, logins or database names in code or docs. (`SOS_FAMILY` and `localhost` appear only as defaults in deploy scripts and the runbook.)
- Concatenated dynamic SQL; `GRANT CONTROL`; `sa`/`db_owner` for the API; PII as sample data.
- Setting `SESSION_CONTEXT(N'IsSystem')` from user input, or a household-owned table outside the security policy.
- `SELECT *` in views, functions or procedures; `TEXT`, `NTEXT`, `IMAGE`, `DATETIME`; unqualified names; missing `NULL`/`NOT NULL`; procedures without `SET NOCOUNT ON` and `TRY...CATCH`; DML outside a transaction; cursors or `NOLOCK` without a justifying comment.
- Several unrelated changes in one migration; several objects in one file; files in the wrong folder.
- A migration without the `dbo.SchemaVersion` check, the `dbo.SchemaVersion` insert, or the rollback block.
- A primary key column named `...Id` (must be `...ID`) or a foreign key column named `...ID` (must be `...Id`).

## Article III: Mandatory patterns

- Migrations follow [`Migrations/_TEMPLATE_Migration.sql`](../Migrations/_TEMPLATE_Migration.sql) exactly: header (`Migration`, `Author`, `Date`, `Description`, `Dependencies`, `Rollback`, `Expected impact`), SET options, transaction, `@MigrationName` and `@StartedAt`, the skip check, guarded statements, the `dbo.SchemaVersion` insert, `CATCH ... ROLLBACK ... THROW`, and the `ROLLBACK SCRIPT` block.
- Objects that must start a batch (views, functions, procedures, triggers, security policy changes) are created inside the migration with `EXEC(N'...')` under an existence guard.
- Tables follow Article VI of the database constitution: column order, the audit tail, an index per foreign key, Proxy-ID columns for rows the API exposes.
- Procedures: header with parameters, returns and an example; `SET NOCOUNT ON`; `TRY...CATCH`; a transaction around DML; `RETURN 0` on success; errors re-thrown with `THROW`.

## Article IV: Data types

`NVARCHAR` (not `VARCHAR`, except `Proxy` and `PartKey`), `DATETIME2(7)` / `DATETIMEOFFSET(7)` (not `DATETIME`), `DECIMAL(19,4)` for money, `BIT` for flags, `INT IDENTITY(1,1)` primary keys, `UNIQUEIDENTIFIER` for `HouseholdId` and user ids, `NVARCHAR(MAX)` / `VARBINARY(MAX)` instead of deprecated types.

## Article V: Naming law

| Object | File | SQL name |
|---|---|---|
| Migration | `Migrations/YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql` (UTC) | `@MigrationName` = file name without `.sql` |
| Table | `Tables/<schema>/<Table>.sql` | `[schema].[Table]` (plural) |
| View | `Views/<schema>/vw<Name>.sql` | `[schema].[vw<Name>]` |
| Function | `Functions/<schema>/fx<Name>.sql` | `[schema].[fx<Name>]` |
| Procedure | `Procedures/<schema>/sp<Name>.sql` | `[schema].[sp<Name>]` |
| Trigger | `Triggers/<schema>/tr_<Table>_<Event>.sql` | `[schema].[tr_<Table>_<Event>]`, generated audit `trgAutoGen_<Table>_CUD` |
| Types | `Types/<schema>/uddt_<Name>.sql`, `udtt<Name>.sql` | |
| Indexes | `Indexes/<schema>/<Table>_Indexes.sql` | `IX_<Table>_<Columns>` |
| Constraints | inline in the table, or `Constraints/<schema>/<Name>.sql` | `PK_<Table>`, `FK_<Child>_<Parent>`, `UQ_<Table>_<Cols>`, `CK_<Table>_<Col>`, `DF_<Table>_<Col>` |
| Security policy | `SecurityPolicies/<schema>/<Policy>.sql` | |
| Grants | `Grants/<schema>/grant_<role>_permissions.sql` | |
| Data | `Data/<schema>/<Table>_data.sql` | |
| Test | `Scripts/Tests/<ObjectType>/<schema>/<Object>_Tests.sql` | |

Columns are PascalCase. PK = singular table + `ID`; FK = singular referenced table + `Id`.

## Article VI: File placement and schemas

Folders by object type, then schema: `Schemas/`, `Types/`, `Tables/`, `Indexes/`, `Constraints/`, `Sequences/`, `Views/`, `Functions/`, `SecurityPolicies/`, `Procedures/`, `Triggers/`, `Grants/`, `Data/`, `Migrations/` (flat), `Scripts/deploy/`, `Scripts/Rollback/`, `Scripts/Tests/`.

| Schema | Type | Purpose |
|---|---|---|
| `auth` | Baseline | Sign-in (ASP.NET Core Identity, refresh tokens) |
| `core` | Baseline | Households, members, invites, stores |
| `security` | Baseline | Row-level security predicates and policy |
| `family` | Baseline | Family data-sharing app (grocery lists) |
| `PAN` | Domain (reserved) | Food storage app (pantry) |
| `MAC` | Infrastructure (reserved) | Proxy-ID catalog: `vwTableTypesAndPrefixes`, `fxGeneratePrefixParts`, ... |
| `UTL` | Infrastructure (reserved) | Scalar utilities: `fxGetPartKey`, ... |
| `dbo` | Infrastructure | `SchemaVersion` only |

New schemas are three upper-case letters and must be added to [`Schemas/README.md`](../Schemas/README.md) first.

**Every new object = two files:** the migration in `Migrations/` and the current-state file in `<ObjectType>/<schema>/`. A change to an object = a new migration plus an update to its current-state file.

## Article VII: Deployment order

Schemas → Types → Tables → Indexes → Constraints → Sequences → Views → Functions → Security policies → Procedures → Triggers → Grants → Data.

## Article VIII: Response protocol

When asked to create or change database objects:
1. **Placement.** Object type → folder; schema → subfolder; UTC timestamp for the migration (`date -u +%Y%m%d_%H%M`).
2. **Migration file** with every constitutional requirement.
3. **Current-state file(s)** with the header.
4. **Households.** If the table holds household data: policy predicates, the policy file, the isolation test, the grant.
5. **Deploy wrapper.** `Scripts/deploy/Deploy_<Change>.ps1` from `_TEMPLATE_Deploy_Change.ps1`, with the plan, prerequisites and post-checks.
6. **Verification.** Test queries, dependencies, rollback steps. Run the migration twice on a scratch database (the second run must skip), run `Scripts/Tests/`, and check `dbo.SchemaVersion`.
7. **Process.** An issue in the repository and a PR that closes it. Commit as `[Type]: ...` with `- Migration:` and `- Affects:` lines.

## Article IX: Deployments

- Dev (`SOS_FAMILY` on the owner's PC) first, through the change's wrapper with `-WhatIf`, then for real. Every post-check must be `[ok]`.
- Never run `Deploy_Migrations.ps1` against Prod (it refuses anything but a local instance).
- Prod only after the PR merges, from `main`, after the owner confirms a restorable backup and replies with an explicit go for that exact command. Use the saved `Prod` credential; never request, print or store a password. If anything fails, stop and report: no automatic retry or rollback.

## Amendments

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-11-24 | Adopted from the Solasta Copilot constitution, adapted for Sosa Fam |

> When in doubt, choose the safer, more documented, more idempotent path.
