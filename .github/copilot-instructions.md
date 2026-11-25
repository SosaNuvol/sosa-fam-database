# Agent Instructions for the Sosa Fam Database

> **Important:** also follow the [agent constitution](copilot-constitution.md). The constitution holds the rules and prohibitions; this file holds the patterns and templates. When they conflict, the constitution wins, and [DATABASE_CONSTITUTION.md](../DATABASE_CONSTITUTION.md) wins over both.

## Project overview

The SQL Server database behind every Sosa Fam app: the family data-sharing app (grocery lists today) and the food storage app. Households are the tenants; SQL Server row-level security keeps them apart. The API ([sosa-fam-api](https://github.com/SosaNuvol/sosa-fam-api)) connects as a login in the `sosafam_api` role and sets the session context on every connection.

- Dev: `SOS_FAMILY` on the owner's local SQL Server. Prod: `SOS_FAMILY` on the family's SQL Server (later).
- Migrations are run by `src/SosaFam.Database` (the runner) through the PowerShell wrappers in `Scripts/deploy/`.

## Core principles

1. **Two-level layout:** `<ObjectType>/<schema>/<Object>.sql`.
2. **Migrations:** `Migrations/YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql` in UTC; immutable once run anywhere; idempotent; recorded in `dbo.SchemaVersion`.
3. **Households:** every household-owned table is in `security.HouseholdIsolation`.

## Templates

### New household-owned table (migration body)

```sql
/*
Migration: 20261125_1400_CreatePAN_PantryItems
Author: <name>
Date: 2026-11-25
Description: Creates PAN.PantryItems, the food a household keeps in storage.
Dependencies: 00000000_0005_Baseline_FamilyGroceryLists, 20261125_1330_CreatePAN_Schema
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact: One new empty table, added to security.HouseholdIsolation.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1400_CreatePAN_PantryItems';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[PAN].[PantryItems]', N'U') IS NULL
    BEGIN
        CREATE TABLE [PAN].[PantryItems]
        (
            [PantryItemID] INT              IDENTITY(1,1) NOT NULL,
            [HouseholdId]  UNIQUEIDENTIFIER NOT NULL,
            [StoreId]      UNIQUEIDENTIFIER NULL,
            [Proxy]        VARCHAR(100)     NOT NULL,
            [PartKey]      VARCHAR(6)       NOT NULL,
            [Name]         NVARCHAR(120)    NOT NULL,
            [Quantity]     DECIMAL(10,2)    NOT NULL CONSTRAINT [DF_PantryItems_Quantity] DEFAULT (0),
            [IsActive]     BIT               NOT NULL CONSTRAINT [DF_PantryItems_IsActive]    DEFAULT (1),
            [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_PantryItems_IsDeleted]   DEFAULT (0),
            [ModifiedDate] DATETIMEOFFSET(7) NULL,
            [ModifiedById] UNIQUEIDENTIFIER  NULL,
            [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_PantryItems_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
            [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_PantryItems_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT [PK_PantryItems] PRIMARY KEY CLUSTERED ([PantryItemID] ASC),
            CONSTRAINT [FK_PantryItems_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_PantryItems_Stores] FOREIGN KEY ([StoreId]) REFERENCES [core].[Stores] ([Id]),
            CONSTRAINT [UQ_PantryItems_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_PantryItems_Quantity] CHECK ([Quantity] >= 0)
        );
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_PantryItems_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[PantryItems]'))
        CREATE NONCLUSTERED INDEX [IX_PantryItems_HouseholdId] ON [PAN].[PantryItems] ([HouseholdId]) WHERE [IsDeleted] = 0;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_PantryItems_StoreId' AND [object_id] = OBJECT_ID(N'[PAN].[PantryItems]'))
        CREATE NONCLUSTERED INDEX [IX_PantryItems_StoreId] ON [PAN].[PantryItems] ([StoreId]);

    -- Households stay apart (DATABASE_CONSTITUTION.md, Article VIII)
    IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[PantryItems]'))
        EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
            ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems],
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems] AFTER INSERT,
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems] AFTER UPDATE;');

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates PAN.PantryItems', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Refuses to lose data: only when the table is empty.
IF NOT EXISTS (SELECT 1 FROM [PAN].[PantryItems])
BEGIN
    ALTER SECURITY POLICY [security].[HouseholdIsolation]
        DROP FILTER PREDICATE ON [PAN].[PantryItems],
        DROP BLOCK PREDICATE ON [PAN].[PantryItems] AFTER INSERT,
        DROP BLOCK PREDICATE ON [PAN].[PantryItems] AFTER UPDATE;
    DROP TABLE [PAN].[PantryItems];
    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1400_CreatePAN_PantryItems';
END
*/
```

Notes:
- Only one cascade path may reach a table. If a child already cascades from a parent that cascades from `core.Households`, its own `FK_<Table>_Households` must be `NO ACTION` (see `family.GroceryItems`).
- Granting a new schema: `GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[PAN] TO [sosafam_api];` in the schema's migration and in `Grants/`.

### Current-state table file (`Tables/<schema>/<Table>.sql`)

```sql
/*******************************************************************************
 * Object Type: Table
 * Schema: PAN
 * Name: PantryItems
 * Description: Food a household keeps in storage.
 * Dependencies: core.Households, core.Stores, security.HouseholdIsolation
 * Author: <name>
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created
 ******************************************************************************/

IF OBJECT_ID(N'[PAN].[PantryItems]', N'U') IS NULL
BEGIN
    CREATE TABLE [PAN].[PantryItems]
    (
        -- the same columns and constraints as the migration, in their current state
    );
END
GO
```

### View

```sql
/*******************************************************************************
 * Object Type: View
 * Schema: PAN
 * Name: vwLowStock
 * Description: Pantry items at or below their reorder level.
 * Dependencies: PAN.PantryItems
 * Author: <name>
 * Created: YYYY-MM-DD
 ******************************************************************************/

CREATE OR ALTER VIEW [PAN].[vwLowStock]
AS
    SELECT
        [P].[PantryItemID],
        [P].[HouseholdId],
        [P].[Name],
        [P].[Quantity]
    FROM
        [PAN].[PantryItems] AS [P]
    WHERE
        [P].[IsDeleted] = 0
        AND [P].[Quantity] <= [P].[ReorderLevel];
GO
```

Views read through row-level security, so they only ever return the session's household.

### Stored procedure

```sql
/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: PAN
 * Name: spPantryItemConsume
 * Description: Takes a quantity out of a pantry item.
 * Parameters:
 *   @PantryItemProxy - the item's Proxy-ID
 *   @Quantity        - amount used (> 0)
 * Returns: 0 on success; errors are thrown.
 * Dependencies: PAN.PantryItems
 * Author: <name>
 * Created: YYYY-MM-DD
 * Example:
 *   EXEC [PAN].[spPantryItemConsume] @PantryItemProxy = 'PAIT:31773:...', @Quantity = 1;
 ******************************************************************************/

CREATE OR ALTER PROCEDURE [PAN].[spPantryItemConsume]
    @PantryItemProxy VARCHAR(100),
    @Quantity        DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @Quantity IS NULL OR @Quantity <= 0
            THROW 50001, N'Quantity must be greater than zero.', 1;

        BEGIN TRANSACTION;

        UPDATE [PAN].[PantryItems]
        SET [Quantity] = [Quantity] - @Quantity,
            [ModifiedDate] = SYSDATETIMEOFFSET(),
            [ModifiedById] = CAST(SESSION_CONTEXT(N'UserId') AS UNIQUEIDENTIFIER),
            [DEX_ROW_TS] = SYSUTCDATETIME()
        WHERE [Proxy] = @PantryItemProxy AND [IsDeleted] = 0;

        IF @@ROWCOUNT = 0
            THROW 50002, N'Pantry item not found.', 1;

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
```

### Function

```sql
CREATE OR ALTER FUNCTION [UTL].[fxGetPartKey] ()
RETURNS VARCHAR(6)
AS
BEGIN
    -- see .github/ProxyID-PrefixRegistry.md
    ...
END
GO
```

Prefer inline table-valued functions (`RETURNS TABLE AS RETURN (...)`) over multi-statement ones.

### Seed data

```sql
MERGE INTO [PAN].[PantryUnits] AS [Target]
USING (VALUES (1, N'each'), (2, N'lb'), (3, N'oz')) AS [Source] ([PantryUnitID], [Name])
ON [Target].[PantryUnitID] = [Source].[PantryUnitID]
WHEN MATCHED THEN UPDATE SET [Target].[Name] = [Source].[Name]
WHEN NOT MATCHED BY TARGET THEN INSERT ([PantryUnitID], [Name]) VALUES ([Source].[PantryUnitID], [Source].[Name]);
```

Wrap with `SET IDENTITY_INSERT ... ON/OFF` when the key is an identity. Never delete rows in a seed.

## Proxy-ID pattern

A Proxy-ID is `{Prefix}:{PartKey}:{GUID}`, for example `PAIT:31773:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8`. The API shows only the proxy, never the integer key.

| Segment | Source |
|---|---|
| `Prefix` | 4 characters from the `*Types` table's `Prefix` column (or a fixed registered prefix for tables without subtypes) |
| `PartKey` | `[UTL].[fxGetPartKey]()`: hex of `YYYYMM`, e.g. `31773` for November 2026 |
| `GUID` | `CAST(NEWID() AS NVARCHAR(36))`, appended by the caller |

Read [ProxyID-PrefixRegistry.md](ProxyID-PrefixRegistry.md) before any Proxy-enabled table: it has the registry, the onboarding checklist and the infrastructure objects. The first Proxy-enabled migration creates `UTL.fxGetPartKey`, `MAC.vwTableTypesAndPrefixes`, `MAC.fxGeneratePrefixParts`, `MAC.fxGeneratePrefixProxy` and `MAC.fxGetPrefixTypeIdFromProxy` in its own migration first.

Lookups by proxy validate both `PartKey` and type:

```sql
INNER JOIN [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy) AS [PX]
    ON  [PX].[PartKey] = [E].[PartKey]
    AND [PX].[TypeId]  = [E].[PantryItemTypeId]
WHERE [E].[Proxy] = @Proxy
```

Never: `Proxy`/`PartKey` on a `*Types` table; `PartKey` as `INT`; hard-coded prefixes in procedures; unregistered prefixes; changing a seeded prefix.

## What not to do

Never modify deployed migrations; never `SELECT *`; never commit untested; never mix unrelated changes; never skip error handling or headers; never hard-code servers, logins or passwords; never leave a household table outside the policy; never forget to update both the migration and the current-state file.

## When asked to add database objects

1. Pick the schema (`core`, `family`, `PAN`, `UTL`, `MAC`, ...). New schema? Register it in `Schemas/README.md` and create it in its own migration.
2. Write the migration (template above).
3. Write or update the current-state file(s).
4. Household data? Policy predicates, `SecurityPolicies/security/HouseholdIsolation.sql`, the isolation test, the grant.
5. Write `Scripts/deploy/Deploy_<Change>.ps1`.
6. Test on a scratch database: apply, apply again (skips), run `Scripts/Tests/`.
7. Issue + PR, commit as `[Type]: ...` with `- Migration:` and `- Affects:`.

## Response format

Show the migration, the current-state file(s), where each goes, test queries, dependencies and rollback steps.

## Testing reminders

Run migrations twice; check `dbo.SchemaVersion`; run the isolation test; try the rollback block on a scratch copy; look at execution plans for new queries.
