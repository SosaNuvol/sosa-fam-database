# Views

Views, one per file: `Views/<schema>/vw<Name>.sql`.

## Template

```sql
/*******************************************************************************
 * Object Type: View
 * Schema: <schema>
 * Name: vw<Name>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

CREATE OR ALTER VIEW [<schema>].[vw<Name>]
AS
    SELECT
        [T].[<Singular>ID],
        [T].[Name]
    FROM
        [<schema>].[<Table>] AS [T]
    WHERE
        [T].[IsDeleted] = 0;
GO
```

## Rules

1. Prefix `vw`; explicit columns, never `SELECT *`; list dependencies in the header.
2. Views read through row-level security, so they return only the session's household.
3. In a migration, create it with `EXEC(N'CREATE OR ALTER VIEW ...')`.
