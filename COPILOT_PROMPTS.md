# Prompts and helper queries

Ready-made prompts for AI agents (Copilot, Claude) and the diagnostic queries we use. The agent rules are in [.github/copilot-constitution.md](.github/copilot-constitution.md); the reusable prompt files are in [.github/prompts/](.github/prompts/).

## Prompts for common tasks

**New household table**
```
Create a table PAN.PantryItems for the food storage app: name, quantity (decimal), unit,
best-before date (optional), the store it is usually bought at (core.Stores), reorder level.
It is household-owned and the API exposes it. Follow the constitution: migration,
current-state files, policy predicates, isolation test, Proxy-ID prefix, deploy wrapper.
```

**Add a column**
```
Add an optional Location (NVARCHAR(60)) to PAN.PantryItems. Write the migration and update
the table file.
```

**Procedure**
```
Create PAN.spPantryItemConsume that takes a pantry item's Proxy-ID and a quantity, refuses
to go below zero, and stamps ModifiedDate/ModifiedById from the session context.
```

**View**
```
Create PAN.vwLowStock listing pantry items at or below their reorder level, with the store
name, excluding deleted rows.
```

**Seed data**
```
Seed PAN.PantryUnits with each, lb, oz, kg, g, l, ml, can, box using MERGE.
```

**Indexes**
```
The API lists a household's pantry items by name and filters by store. Recommend indexes
for PAN.PantryItems and write the migration.
```

## Diagnostic queries

**Applied migrations**
```sql
SELECT [MigrationName], [Description], [AppliedDate], [AppliedBy], [Success], [ExecutionTimeMs]
FROM [dbo].[SchemaVersion]
ORDER BY [MigrationName];
```

**Tables outside the household policy** (should list only `auth.*`, `dbo.SchemaVersion` and type/lookup tables)
```sql
SELECT SCHEMA_NAME([T].[schema_id]) AS [SchemaName], [T].[name] AS [TableName]
FROM sys.tables AS [T]
WHERE [T].[is_ms_shipped] = 0
  AND NOT EXISTS (SELECT 1 FROM sys.security_predicates AS [P] WHERE [P].[target_object_id] = [T].[object_id])
ORDER BY [SchemaName], [TableName];
```

**Tables with a HouseholdId but no filter predicate** (must be empty)
```sql
SELECT SCHEMA_NAME([T].[schema_id]) AS [SchemaName], [T].[name] AS [TableName]
FROM sys.tables AS [T]
INNER JOIN sys.columns AS [C] ON [C].[object_id] = [T].[object_id] AND [C].[name] = N'HouseholdId'
WHERE NOT EXISTS (SELECT 1 FROM sys.security_predicates AS [P]
                  WHERE [P].[target_object_id] = [T].[object_id] AND [P].[predicate_type_desc] = N'FILTER');
```

**Tables without a primary key**
```sql
SELECT SCHEMA_NAME([T].[schema_id]) AS [SchemaName], [T].[name] AS [TableName]
FROM sys.tables AS [T]
WHERE NOT EXISTS (SELECT 1 FROM sys.key_constraints AS [K] WHERE [K].[parent_object_id] = [T].[object_id] AND [K].[type] = 'PK')
  AND [T].[is_ms_shipped] = 0;
```

**Foreign keys without an index**
```sql
SELECT OBJECT_SCHEMA_NAME([FK].[parent_object_id]) AS [SchemaName], OBJECT_NAME([FK].[parent_object_id]) AS [TableName],
       [FK].[name] AS [ForeignKey], COL_NAME([FKC].[parent_object_id], [FKC].[parent_column_id]) AS [ColumnName]
FROM sys.foreign_keys AS [FK]
INNER JOIN sys.foreign_key_columns AS [FKC] ON [FKC].[constraint_object_id] = [FK].[object_id] AND [FKC].[constraint_column_id] = 1
WHERE NOT EXISTS (SELECT 1 FROM sys.index_columns AS [IC]
                  WHERE [IC].[object_id] = [FKC].[parent_object_id] AND [IC].[column_id] = [FKC].[parent_column_id] AND [IC].[key_ordinal] = 1);
```

**New tables missing the audit tail**
```sql
SELECT SCHEMA_NAME([T].[schema_id]) AS [SchemaName], [T].[name] AS [TableName]
FROM sys.tables AS [T]
WHERE [T].[is_ms_shipped] = 0
  AND SCHEMA_NAME([T].[schema_id]) NOT IN (N'auth', N'core', N'family', N'dbo')   -- baseline schemas
  AND (SELECT COUNT(*) FROM sys.columns AS [C] WHERE [C].[object_id] = [T].[object_id]
       AND [C].[name] IN (N'IsActive', N'IsDeleted', N'ModifiedDate', N'ModifiedById', N'CreatedDate', N'CreatedById', N'DEX_ROW_TS')) < 7;
```

**Table sizes**
```sql
SELECT SCHEMA_NAME([T].[schema_id]) AS [SchemaName], [T].[name] AS [TableName], SUM([P].[rows]) AS [RowCount],
       SUM([A].[total_pages]) * 8 AS [TotalKB]
FROM sys.tables AS [T]
INNER JOIN sys.partitions AS [P] ON [P].[object_id] = [T].[object_id] AND [P].[index_id] IN (0, 1)
INNER JOIN sys.allocation_units AS [A] ON [A].[container_id] = [P].[partition_id]
GROUP BY [T].[schema_id], [T].[name]
ORDER BY [TotalKB] DESC;
```

**Missing indexes the engine suggests**
```sql
SELECT OBJECT_NAME([D].[object_id]) AS [TableName], [D].[equality_columns], [D].[inequality_columns], [D].[included_columns],
       [S].[avg_user_impact], [S].[user_seeks]
FROM sys.dm_db_missing_index_details AS [D]
INNER JOIN sys.dm_db_missing_index_groups AS [G] ON [G].[index_handle] = [D].[index_handle]
INNER JOIN sys.dm_db_missing_index_group_stats AS [S] ON [S].[group_handle] = [G].[index_group_handle]
WHERE [D].[database_id] = DB_ID()
ORDER BY [S].[avg_user_impact] * [S].[user_seeks] DESC;
```

## Checking a migration file before commit

```powershell
param([string]$MigrationFile)
$content = Get-Content $MigrationFile -Raw
$name = [IO.Path]::GetFileNameWithoutExtension($MigrationFile)
$checks = @{
    'file name'           = $name -match '^\d{8}_\d{4}_[A-Za-z]+_[A-Za-z0-9]+$'
    'header'              = $content -match '/\*\s*Migration:'
    'transaction'         = $content -match 'BEGIN TRANSACTION'
    'SchemaVersion check' = $content -match 'FROM \[dbo\]\.\[SchemaVersion\]'
    'SchemaVersion insert'= $content -match 'INSERT INTO \[dbo\]\.\[SchemaVersion\]'
    'name matches'        = $content -match [regex]::Escape("@MigrationName NVARCHAR(255) = N'$name'")
    'rollback block'      = $content -match 'ROLLBACK SCRIPT'
}
$checks.GetEnumerator() | ForEach-Object { '{0,-22} {1}' -f $_.Key, $(if ($_.Value) { 'ok' } else { 'MISSING' }) }
```

## Questions worth asking an agent

- What happens to the API if this migration runs before the API release?
- Does this table hold household data, and is every path covered by the policy?
- What is the safest way to add this `NOT NULL` column to a table with rows?
- Which index will the API's list query use?
