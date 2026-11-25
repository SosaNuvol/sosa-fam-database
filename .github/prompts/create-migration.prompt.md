---
agent: 'agent'
description: 'Create a standalone migration for any schema change (add column, rename, drop, alter, backfill)'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

Create a migration:

**Description**: ${input:description:The change in plain English, e.g. Add BestBefore to PAN.PantryItems}
**Migration name**: ${input:migrationName:<Verb><SCHEMA>_<What>, e.g. AddPAN_PantryItemsBestBefore}

## Requirements

One file: `Migrations/<timestamp>_<migrationName>.sql`, UTC timestamp, copied from `Migrations/_TEMPLATE_Migration.sql` and filled in completely (header with Dependencies, Rollback and Expected impact).

- Guard every statement: `IF COL_LENGTH(N'[schema].[Table]', N'Column') IS NULL`, `IF OBJECT_ID(...)`, `IF NOT EXISTS (SELECT 1 FROM sys.indexes ...)`.
- Adding a `NOT NULL` column to a table with rows: add it `NULL` (or with a named default), backfill, then make it `NOT NULL`. Say so in the header.
- Never edit an existing migration.
- Update the current-state file(s) for every object the migration changes.
- Add or update `Scripts/deploy/Deploy_<Change>.ps1`.

Then give a query that confirms the change.
