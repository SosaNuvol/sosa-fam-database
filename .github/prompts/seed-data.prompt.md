---
agent: 'agent'
description: 'Create an idempotent seed data script with MERGE'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Table name**: ${input:tableName:e.g. PantryUnits}
**Schema**: ${input:schema:e.g. PAN}
**Values**: ${input:seedValues:One per line}

Files: `Migrations/<timestamp>_Seed<SCHEMA>_<tableName>.sql` and `Data/<schema>/<tableName>_data.sql`.

`MERGE` on explicit IDs from 1 (`SET IDENTITY_INSERT` around it for identity keys); update changed rows, insert missing ones, never delete. Household-owned rows can't be seeded globally: seed reference tables only. Give a `SELECT` that shows every seeded row.
