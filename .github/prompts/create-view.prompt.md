---
agent: 'agent'
description: 'Create a view with its migration and current-state file'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**View name**: ${input:viewName:vw<Name>, e.g. vwLowStock}
**Schema**: ${input:schema:e.g. PAN}
**Description**: ${input:description:What does it expose?}
**Source tables**: ${input:sourceTables:Tables or views it reads}

Files: `Migrations/<timestamp>_Create<SCHEMA>_<viewName>.sql` (with `EXEC(N'CREATE OR ALTER VIEW ...')`) and `Views/<schema>/<viewName>.sql` (`CREATE OR ALTER VIEW`, header with Dependencies).

Explicit columns only, no `SELECT *`; filter `IsDeleted = 0` where it applies; alias computed columns. Views inherit row-level security from their tables. Give a `SELECT TOP 10` to check it.
