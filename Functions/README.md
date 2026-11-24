# Functions

Functions, one per file: `Functions/<schema>/fx<Name>.sql`.

## Template (inline table-valued)

```sql
/*******************************************************************************
 * Object Type: Function
 * Schema: <schema>
 * Name: fx<Name>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

CREATE OR ALTER FUNCTION [<schema>].[fx<Name>] (@Param1 INT)
RETURNS TABLE
AS
RETURN
(
    SELECT [Column1], [Column2]
    FROM [<schema>].[<Table>]
    WHERE [<Singular>ID] = @Param1
);
GO
```

## Rules

1. Prefix `fx`; header lists Parameters and Returns.
2. Prefer inline table-valued functions; scalar functions in a `WHERE` clause run once per row.
3. Functions never change data.
4. The row-level security predicates (`security.fn_*`, baseline names) are schema-bound to the policy: see `SecurityPolicies/README.md` before changing one.
