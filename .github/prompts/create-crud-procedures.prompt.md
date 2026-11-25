---
agent: 'agent'
description: 'Generate a full set of CRUD stored procedures for an existing table'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Table name**: ${input:tableName:e.g. PantryItems}
**Schema**: ${input:schema:e.g. PAN}

| Procedure | Purpose |
|---|---|
| `sp<Singular>GetByProxy` | One row by Proxy-ID (validate PartKey and type) |
| `sp<Singular>GetAll` | Rows with `@PageNumber` / `@PageSize` (`OFFSET` / `FETCH NEXT`), excluding `IsDeleted = 1` |
| `sp<Singular>Create` | Insert; generate the Proxy-ID; return the proxy |
| `sp<Singular>Update` | Update by proxy; set ModifiedDate, ModifiedById, DEX_ROW_TS |
| `sp<Singular>Delete` | Soft delete (`IsDeleted = 1`, `IsActive = 0`) |

Read `Tables/<schema>/<tableName>.sql` first. One migration creates all five; one file per procedure in `Procedures/<schema>/`. Get procedures use no transaction. Actor ids come from `SESSION_CONTEXT(N'UserId')`. Give sample `EXEC` calls.
