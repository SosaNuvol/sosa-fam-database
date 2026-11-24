# Quick reference

## Names

| What | Pattern | Example |
|---|---|---|
| Migration file | `YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql` (UTC) | `20261125_1400_CreatePAN_PantryItems.sql` |
| New schema | three upper-case letters | `PAN` |
| Table | plural PascalCase | `PantryItems` |
| Primary key column | singular + `ID` | `PantryItemID` |
| Foreign key column | singular + `Id` | `PantryItemId`, `HouseholdId` |
| Constraints | `PK_<T>`, `FK_<Child>_<Parent>`, `UQ_<T>_<Cols>`, `CK_<T>_<Col>`, `DF_<T>_<Col>` | `FK_PantryItems_Households` |
| Index | `IX_<T>_<Cols>` | `IX_PantryItems_HouseholdId` |
| View / function / procedure | `vw<Name>` / `fx<Name>` / `sp<Name>` | `spPantryItemConsume` |
| Trigger | `tr_<T>_<Event>`, generated `trgAutoGen_<T>_CUD` | `tr_PantryItems_AfterUpdate` |
| Types | `uddt_<Name>`, `udtt<Name>` | `udttPantryItemProxies` |
| Proxy-ID | `{Prefix}:{PartKey}:{GUID}` | `PAIT:31773:E2CD...0EB8` |

## Audit tail (every new table, in this order, last)

```sql
[IsActive]     BIT               NOT NULL CONSTRAINT [DF_<T>_IsActive]    DEFAULT (1),
[IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_<T>_IsDeleted]   DEFAULT (0),
[ModifiedDate] DATETIMEOFFSET(7) NULL,
[ModifiedById] UNIQUEIDENTIFIER  NULL,
[CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_<T>_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
[CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
[DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_<T>_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
-- [DEX_ROW] BIGINT IDENTITY(1,1) NOT NULL   only when the table has no identity column
```

## Household table checklist

`HouseholdId UNIQUEIDENTIFIER NOT NULL` → `FK_<T>_Households` → `IX_<T>_HouseholdId` → policy predicates in the migration → `SecurityPolicies/security/HouseholdIsolation.sql` → isolation test → grant.

```sql
EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems] AFTER UPDATE;');
```

## Existence guards

```sql
IF SCHEMA_ID(N'PAN') IS NULL EXEC(N'CREATE SCHEMA [PAN]');
IF OBJECT_ID(N'[PAN].[PantryItems]', N'U') IS NULL ...
IF COL_LENGTH(N'[PAN].[PantryItems]', N'BestBefore') IS NULL ALTER TABLE ... ADD ...;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_...' AND [object_id] = OBJECT_ID(N'[PAN].[PantryItems]')) CREATE INDEX ...;
IF OBJECT_ID(N'[PAN].[spX]', N'P') IS NULL EXEC(N'CREATE PROCEDURE ...');   -- or EXEC(N'CREATE OR ALTER ...')
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[PantryItems]')) ...
```

## Commands

| Task | Command |
|---|---|
| UTC timestamp | `date -u +%Y%m%d_%H%M` / `(Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmm')` |
| What is applied | `dotnet run --project src/SosaFam.Database -- --list "<cs>"` |
| Preview | `dotnet run --project src/SosaFam.Database -- --what-if "<cs>"` |
| Apply all (scratch) | `dotnet run --project src/SosaFam.Database -- --ensure-database "<cs>"` |
| One migration | `... -- --filter 20261125_1400_CreatePAN_PantryItems "<cs>"` |
| Dev deploy of a change | `.\Scripts\deploy\Deploy_<Change>.ps1 -Environment Dev [-WhatIf]` |
| Catch Dev up | `.\Scripts\deploy\Deploy_Migrations.ps1 [-WhatIf]` |
| Prod deploy | `.\Scripts\deploy\Deploy_<Change>.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod [-WhatIf]` |
| Isolation test | `sqlcmd ... -b -i Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql` |

## Applied migrations

```sql
SELECT [MigrationName], [AppliedDate], [AppliedBy], [Success], [ExecutionTimeMs]
FROM [dbo].[SchemaVersion]
ORDER BY [MigrationName];
```

## Session context the API sets

| Key | Type | Meaning |
|---|---|---|
| `UserId` | `uniqueidentifier` | The signed-in user |
| `HouseholdId` | `uniqueidentifier` | The household the request acts in |
| `IsSystem` | `bit` | 1 only when creating a household or accepting an invite |
