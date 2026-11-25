# Triggers

Triggers, one per file: `Triggers/<schema>/tr_<Table>_<Event>.sql` (generated audit triggers: `trgAutoGen_<Table>_CUD.sql`).

## Template

```sql
/*******************************************************************************
 * Object Type: Trigger
 * Schema: <schema>
 * Name: tr_<Table>_<Event>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 * Fires On: AFTER UPDATE on [<schema>].[<Table>]
 ******************************************************************************/

CREATE OR ALTER TRIGGER [<schema>].[tr_<Table>_AfterUpdate]
ON [<schema>].[<Table>]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- set-based over inserted / deleted; never assume one row
END
GO
```

## Rules

1. Keep triggers small and set-based; no recursion.
2. Use a constraint or procedure instead when one will do, and say in the header why a trigger is needed.
3. Tables with triggers need EF Core told about them in the API (`HasTrigger`), or inserts that use `OUTPUT` fail.
