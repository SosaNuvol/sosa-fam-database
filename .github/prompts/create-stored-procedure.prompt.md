---
agent: 'agent'
description: 'Create a stored procedure with full error handling and documentation'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Procedure name**: ${input:procedureName:sp<Name>, e.g. spPantryItemConsume}
**Schema**: ${input:schema:e.g. PAN}
**Description**: ${input:description:What does it do?}

## Files

1. `Migrations/<timestamp>_Create<SCHEMA>_<procedureName>.sql`, creating the procedure with `EXEC(N'CREATE OR ALTER PROCEDURE ...')` inside the template.
2. `Procedures/<schema>/<procedureName>.sql` with `CREATE OR ALTER PROCEDURE`.

## The procedure

- Header: Object Type, Schema, Name, Description, Parameters, Returns, Dependencies, Author, Created, Example.
- `SET NOCOUNT ON`; parameter validation with `THROW 5xxxx`; `TRY...CATCH`; a transaction around DML; `RETURN 0`; `IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW;` in the catch.
- Tables under row-level security already only show the session's household; never accept a HouseholdId parameter to widen access.
- Grant `EXECUTE` to `sosafam_api` in the migration and in `Grants/`.

Ask me for parameters and business rules if needed, then give a sample `EXEC`.
