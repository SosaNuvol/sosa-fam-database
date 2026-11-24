---
agent: 'agent'
description: 'Create a user-defined table type with its migration'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Type name**: ${input:typeName:udtt<Name>, e.g. udttPantryItemProxies}
**Schema**: ${input:schema:e.g. PAN}
**Description**: ${input:description:What rows it carries}
**Usage**: ${input:usage:Which procedure takes it as READONLY}

Files: `Migrations/<timestamp>_Create<SCHEMA>_<typeName>.sql` and `Types/<schema>/<typeName>.sql`.

Types cannot be altered: the migration drops and recreates only if no procedure uses it, otherwise it creates a new type. Guard with `sys.table_types`. Explicit `NULL`/`NOT NULL`, a primary key or unique constraint, no audit columns. Grant `EXECUTE ON TYPE::` to `sosafam_api`. Give a test that declares, fills and selects from it.
