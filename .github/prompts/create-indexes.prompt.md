---
agent: 'agent'
description: 'Analyze a table and add indexes with a migration'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Table name**: ${input:tableName:e.g. PantryItems}
**Schema**: ${input:schema:e.g. PAN}
**Query patterns**: ${input:queryPatterns:How the API queries it}

Read `Tables/<schema>/<tableName>.sql` and `Indexes/<schema>/<tableName>_Indexes.sql`, explain each index you recommend, then write `Migrations/<timestamp>_AddIndexes<SCHEMA>_<tableName>.sql` and update `Indexes/<schema>/<tableName>_Indexes.sql`.

Name `IX_<Table>_<Columns>`; guard with `IF NOT EXISTS (SELECT 1 FROM sys.indexes ...)`; most selective column first; `INCLUDE` to cover; filtered (`WHERE [IsDeleted] = 0`) where useful; `HouseholdId` leads most indexes because row-level security filters on it. Give queries whose plans should use each index.
