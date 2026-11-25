---
agent: 'agent'
description: 'Create a trigger for a table'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Table name**: ${input:tableName:e.g. PantryItems}
**Schema**: ${input:tableSchema:e.g. PAN}
**Trigger**: ${input:triggerType:what it does, e.g. keep ModifiedDate current}

Files: `Migrations/<timestamp>_Create<SCHEMA>_tr_<tableName>_<Event>.sql` and `Triggers/<schema>/tr_<tableName>_<Event>.sql` (`CREATE OR ALTER TRIGGER`, header with Fires On).

`SET NOCOUNT ON`; set-based over `inserted` / `deleted` (never assume one row); keep it light; no recursion. Prefer a constraint or a procedure when one will do, and say why a trigger is needed. Give DML that proves it fires.
