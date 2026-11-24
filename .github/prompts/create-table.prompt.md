---
agent: 'agent'
description: 'Create a new table with its migration, current-state file, household isolation and deploy wrapper'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

Create a new table:

**Table name**: ${input:tableName:Plural PascalCase, e.g. PantryItems}
**Schema**: ${input:schema:Schema code, e.g. PAN, family, core}
**Description**: ${input:description:What the table stores}
**Household-owned?**: ${input:household:yes or no (almost always yes)}

## Files

1. `Migrations/<timestamp>_Create<SCHEMA>_<tableName>.sql` with the current UTC time (`date -u +%Y%m%d_%H%M`), following `Migrations/_TEMPLATE_Migration.sql` exactly.
2. `Tables/<schema>/<tableName>.sql` (current state, with the header block).
3. `Indexes/<schema>/<tableName>_Indexes.sql` for every non-key index.
4. `Scripts/deploy/Deploy_<Change>.ps1` from `_TEMPLATE_Deploy_Change.ps1`.

## The table

- `[<Singular>ID] INT IDENTITY(1,1) NOT NULL` with `PK_<tableName>`.
- Foreign keys named `<Singular>Id` with `FK_<tableName>_<Parent>`, each with an index.
- `[Proxy] VARCHAR(100)` and `[PartKey] VARCHAR(6)` if the API exposes rows; register the prefix in `.github/ProxyID-PrefixRegistry.md` first.
- Business columns with explicit `NULL`/`NOT NULL`, named `DF_`/`CK_`/`UQ_` constraints.
- The audit tail from DATABASE_CONSTITUTION.md Article VI, exactly.

## If household-owned

- `[HouseholdId] UNIQUEIDENTIFIER NOT NULL`, `FK_<tableName>_Households` to `[core].[Households] ([Id])`, an index on it.
- In the migration: add the filter and `AFTER INSERT` / `AFTER UPDATE` block predicates to `[security].[HouseholdIsolation]`; update `SecurityPolicies/security/HouseholdIsolation.sql`; add a check to `Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql`.
- Grant `sosafam_api` access if the schema is new.

Ask me for column details you need. Then give queries that confirm the table, its columns, its indexes and its predicates.
