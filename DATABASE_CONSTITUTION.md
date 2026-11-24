# Sosa Fam Database Constitution

> These are the binding rules for every change to the Sosa Fam database, by a person or an agent. They follow the Solasta database standards, adapted to Sosa Fam's households and row-level security. When a guide or template disagrees with this file, this file wins.

**Version:** 1.0.0 · **Ratified:** 2026-11-24 · **Applies to:** `SOS_FAMILY` (Dev and Prod)

---

## Article I: Principles

1. **Single source of truth.** `Migrations/` is the history of the database. The object folders (`Tables/`, `Functions/`, ...) document the current state.
2. **Immutable history.** Never edit a migration that has run in any environment. Fix forward with a new migration that has a later timestamp.
3. **Idempotent.** Every script is safe to run twice: `IF OBJECT_ID(...) IS NULL`, `IF COL_LENGTH(...) IS NULL`, `IF NOT EXISTS (SELECT 1 FROM sys.indexes ...)`. Seed data uses `MERGE` or a guarded `INSERT`.
4. **Atomic.** One migration is one logical change, in one transaction with `XACT_ABORT ON` and `TRY...CATCH`. If any part fails, all of it rolls back.
5. **Documented first.** No SQL file without its header block. Every migration has a rollback block.
6. **Households stay apart.** Every household-owned row is protected by row-level security in the database itself, not only by the API (Article VIII).

## Article II: Prohibitions

Never write code that does any of these.

**Security**
- Passwords, keys, connection strings, server names or logins in any file in this repository.
- Dynamic SQL built by concatenating input. Use `sp_executesql` with parameters.
- `GRANT CONTROL`, `db_owner` or `sa` for the API. The API's login is only a member of `sosafam_api`.
- Real people's data as samples. Use `jane@example.test`, "Test household".
- A household-owned table without `HouseholdId` and the `security.HouseholdIsolation` predicates.
- Setting the `IsSystem` session key from anything a user can send.

**Quality**
- `SELECT *` in a view, function or procedure.
- `TEXT`, `NTEXT`, `IMAGE`, `DATETIME`, `FLOAT` for money.
- Unqualified object names. Always `[schema].[Object]`, in square brackets.
- A procedure without `SET NOCOUNT ON` and `TRY...CATCH`, or data changes outside a transaction.
- Cursors or `NOLOCK` without a comment that justifies them.
- A column without an explicit `NULL` or `NOT NULL`.

**Structure**
- Unrelated changes in one migration, or several objects in one object file (seed rows for one table are fine).
- A file in the wrong folder.
- A migration without the `dbo.SchemaVersion` check, the `dbo.SchemaVersion` insert, or the rollback block.
- A primary key column ending in `Id`, or a foreign key column ending in `ID` (Article V).

## Article III: Every file

Object files start with this block and are idempotent:

```sql
/*******************************************************************************
 * Object Type:
 * Schema:
 * Name:
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/
```

Migrations start with this block, then follow [`Migrations/_TEMPLATE_Migration.sql`](Migrations/_TEMPLATE_Migration.sql) exactly:

```sql
/*
Migration: YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>
Author:
Date:
Description:
Dependencies:
Rollback:
Expected impact:
*/
```

A migration body sets `ANSI_NULLS`, `QUOTED_IDENTIFIER`, `ANSI_PADDING`, `ANSI_WARNINGS`, `ARITHABORT` and `CONCAT_NULL_YIELDS_NULL` ON, `NUMERIC_ROUNDABORT` OFF and `XACT_ABORT` ON; opens `BEGIN TRANSACTION` / `BEGIN TRY`; declares `@MigrationName` and `@StartedAt`; skips if `dbo.SchemaVersion` already has the name with `Success = 1`; guards every statement; inserts its `dbo.SchemaVersion` row last; and ends with a `ROLLBACK SCRIPT` comment block.

## Article IV: Data types

| Use | Not | Why |
|---|---|---|
| `NVARCHAR(n)` | `VARCHAR` | Unicode. Exception: `Proxy` and `PartKey` are `VARCHAR` (ASCII by definition). |
| `DATETIME2(7)`, `DATETIMEOFFSET(7)` for audit dates | `DATETIME` | Precision and range |
| `DECIMAL(19,4)` for money, `DECIMAL(10,2)` for quantities | `FLOAT` | Exact |
| `BIT` | `INT` flags | Boolean |
| `INT IDENTITY(1,1)` primary keys | `UNIQUEIDENTIFIER` | Unless justified in the header. See Article VI for the Proxy-ID the API shows. |
| `UNIQUEIDENTIFIER` for `HouseholdId` and user ids | | Households and Identity users are GUID-keyed |
| `NVARCHAR(MAX)`, `VARBINARY(MAX)` | `NTEXT`, `IMAGE` | Deprecated |

## Article V: Naming

**Files**

| Object | Folder and file | Example |
|---|---|---|
| Migration | `Migrations/YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql` (UTC) | `20261125_1400_CreatePAN_PantryItems.sql` |
| Table | `Tables/<schema>/<Table>.sql` | `Tables/PAN/PantryItems.sql` |
| Indexes | `Indexes/<schema>/<Table>_Indexes.sql` | `Indexes/PAN/PantryItems_Indexes.sql` |
| View | `Views/<schema>/vw<Name>.sql` | `Views/PAN/vwLowStock.sql` |
| Function | `Functions/<schema>/fx<Name>.sql` | `Functions/UTL/fxGetPartKey.sql` |
| Procedure | `Procedures/<schema>/sp<Name>.sql` | `Procedures/PAN/spPantryItemConsume.sql` |
| Trigger | `Triggers/<schema>/tr_<Table>_<Event>.sql`, generated audit `trgAutoGen_<Table>_CUD.sql` | `tr_PantryItems_AfterUpdate.sql` |
| Alias type / table type | `Types/<schema>/uddt_<Name>.sql`, `Types/<schema>/udtt<Name>.sql` | `udttPantryItemIds.sql` |
| Security policy | `SecurityPolicies/<schema>/<Policy>.sql` | `SecurityPolicies/security/HouseholdIsolation.sql` |
| Grants | `Grants/<schema>/grant_<role>_permissions.sql` | `grant_sosafam_api_permissions.sql` |
| Seed data | `Data/<schema>/<Table>_data.sql` | `Data/PAN/PantryUnits_data.sql` |
| Unit test | `Scripts/Tests/<ObjectType>/<schema>/<Object>_Tests.sql` | `Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql` |

Migration verbs: `Create`, `Add`, `Alter`, `Drop`, `Rename`, `Seed`, `Backfill`, `Grant`. `<SCHEMA>` is the schema code in capitals (`CORE`, `FAMILY`, `PAN`).

**SQL objects**

| Object | Pattern | Example |
|---|---|---|
| Primary key | `PK_<Table>` | `PK_PantryItems` |
| Foreign key | `FK_<ChildTable>_<ParentTable>` | `FK_PantryItems_Households` |
| Unique | `UQ_<Table>_<Columns>` | `UQ_PantryItems_HouseholdId_Barcode` |
| Check | `CK_<Table>_<Column>` | `CK_PantryItems_Quantity` |
| Default | `DF_<Table>_<Column>` | `DF_PantryItems_IsActive` |
| Index | `IX_<Table>_<Columns>` | `IX_PantryItems_HouseholdId` |
| View, function, procedure | `[schema].[vw...]`, `[schema].[fx...]`, `[schema].[sp...]` | `[PAN].[spPantryItemConsume]` |

**Columns** are PascalCase and never abbreviated.
- Primary key: the singular table name + `ID` (capital D). `PantryItems` → `PantryItemID`.
- Foreign key: the singular referenced table name + `Id` (lower-case d). `PantryItems` → `PantryItemId`, `Households` → `HouseholdId`.
- The casing difference is deliberate: `XxxID` is the key of its own table, `XxxId` points at another table.

**Schemas.** New schemas use a three-letter upper-case code registered in [`Schemas/README.md`](Schemas/README.md) (for example `PAN` for the food storage app, `UTL` for utilities, `MAC` for the Proxy-ID catalog). The baseline schemas `auth`, `core`, `family` and `security` keep their names.

## Article VI: Tables

Every new table has:
1. Explicit `NULL` / `NOT NULL` on every column, and named `PK_`, `FK_`, `UQ_`, `CK_`, `DF_` constraints.
2. Columns in this order: primary key, foreign keys, business columns, then the audit tail.
3. The audit tail, exactly:
   ```sql
   [IsActive]     BIT               NOT NULL CONSTRAINT [DF_<Table>_IsActive]    DEFAULT (1),
   [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_<Table>_IsDeleted]   DEFAULT (0),
   [ModifiedDate] DATETIMEOFFSET(7) NULL,
   [ModifiedById] UNIQUEIDENTIFIER  NULL,
   [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_<Table>_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
   [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
   [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_<Table>_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
   ```
   A table with no identity column also ends with `[DEX_ROW] BIGINT IDENTITY(1,1) NOT NULL`. Actor ids are `auth.AspNetUsers.Id` values; the API supplies them and maintains `ModifiedDate`, `ModifiedById` and `DEX_ROW_TS` on updates. Deletes are soft (`IsDeleted = 1`) unless the header says why not.
4. An index on every foreign key column.
5. **Proxy-ID** for any row the API exposes: `[Proxy] VARCHAR(100) NOT NULL` (`UQ_<Table>_Proxy`) and `[PartKey] VARCHAR(6) NOT NULL`, generated as `{Prefix}:{PartKey}:{GUID}` with a prefix registered in [`.github/ProxyID-PrefixRegistry.md`](.github/ProxyID-PrefixRegistry.md). The API shows the proxy, never the integer key.

## Article VII: Deployment order

1. Schemas 2. Types 3. Tables 4. Indexes 5. Constraints 6. Sequences 7. Views 8. Functions 9. Security policies 10. Procedures 11. Triggers 12. Grants 13. Data

Security policies come after the predicate functions they use and before anything that reads protected tables.

## Article VIII: Households (Sosa Fam)

Households are the tenants. Every household-owned table:
1. Has `[HouseholdId] UNIQUEIDENTIFIER NOT NULL` with `FK_<Table>_Households` to `[core].[Households]` and an index on it.
2. Is added to `[security].[HouseholdIsolation]` in the same migration, with a filter predicate and `AFTER INSERT` and `AFTER UPDATE` block predicates (`[security].[fn_HouseholdAccess]([HouseholdId])`), and the current-state file [`SecurityPolicies/security/HouseholdIsolation.sql`](SecurityPolicies/security/HouseholdIsolation.sql) is updated.
3. Is covered by a check in [`Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql`](Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql).
4. Is reachable by the API only through the `sosafam_api` role (a grant in the migration and in `Grants/`).

The API sets `SESSION_CONTEXT` keys `UserId`, `HouseholdId` and `IsSystem` read-only on every connection. Only two API paths may set `IsSystem = 1`: creating a household and accepting an invite.

## Article IX: Error handling

Procedures:

```sql
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- logic
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
```

Migrations use the template's `BEGIN CATCH IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW; END CATCH`.

## Article X: Security

- Parameterize: `EXEC sp_executesql N'... WHERE [PantryItemID] = @Id', N'@Id INT', @Id = @PantryItemId;`
- Least privilege: schema-level `SELECT, INSERT, UPDATE, DELETE` (and `EXECUTE` where procedures are used) for `sosafam_api`; nothing on `dbo`.
- Logins and passwords are created per environment and kept outside the repository: .NET user secrets for the API, a saved credential for deployments.

## Article XI: Performance

Explicit column lists; an index for every foreign key; covering or filtered indexes (`WHERE [IsDeleted] = 0`) for the API's hot queries; no leading-wildcard `LIKE` without a reason; review execution plans for complex queries.

## Article XII: Process

- Every change starts with a GitHub issue and goes in through a pull request that closes it (project rule for all Sosa Fam repositories).
- Commit messages: `[Type]: Brief description`, then `- Migration: <name>` and `- Affects: <objects>` lines. Types: `Feature`, `Fix`, `Refactor`, `Docs`, `Chore`, `Data`.
- A migration goes to Dev first (through its `Scripts/deploy/Deploy_<Change>.ps1` wrapper), then the API is built and tested against Dev, and only after the PRs merge does it go to Prod. See [docs/Deploying-Migrations.md](docs/Deploying-Migrations.md).

## Baseline exceptions

The five baseline migrations (`00000000_0001` to `00000000_0005`) were applied to `SOS_FAMILY` before these rules. They stay as they are, because changing them would mean rewriting deployed history and the API's data model:

| Object | Differs from the rules in |
|---|---|
| All baseline tables | `UNIQUEIDENTIFIER` keys named `Id`; no audit tail (they use `CreatedAt`); some FK names include the column (`FK_Members_Households_HouseholdId`); some unique indexes use `UX_` |
| `auth.AspNetUser*` | Shape owned by ASP.NET Core Identity |
| `security.fn_*` | `fn_` prefix instead of `fx` |
| Schemas `auth`, `core`, `family`, `security` | Lower-case names |
| `GroceryItems.ProductId` | Loose reference without a foreign key, by design (it points into the food storage app) |

Any rework of these objects is a new migration that brings the object fully in line.

## Amendments

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-11-24 | Adopted from the Solasta database standards, with Article VIII added for households |
