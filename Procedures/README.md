# Procedures

Stored procedures, one per file: `Procedures/<schema>/sp<Name>.sql`.

## Template

```sql
/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: <schema>
 * Name: sp<Name>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 * Parameters:
 *   @Param1 -
 * Returns: 0 on success; errors are thrown.
 * Example:
 *   EXEC [<schema>].[sp<Name>] @Param1 = 1;
 ******************************************************************************/

CREATE OR ALTER PROCEDURE [<schema>].[sp<Name>]
    @Param1 INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- logic

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
```

## Rules

1. Prefix `sp` (no underscore: `sp_` names are looked up in `master` first).
2. `SET NOCOUNT ON`, `TRY...CATCH`, a transaction around data changes, `RETURN 0`.
3. Validate parameters; raise with `THROW 50000+`.
4. The household comes from the session context and row-level security, never from a parameter that widens access.
5. Grant `EXECUTE` to `sosafam_api`.
