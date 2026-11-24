# Data

Seed and reference data, one file per table: `Data/<schema>/<Table>_data.sql`.

## Template

```sql
/*******************************************************************************
 * Object Type: Data Script (Seed/Reference Data)
 * Schema: <schema>
 * Name: <Table>_data
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY
    MERGE INTO [<schema>].[<Table>] AS [Target]
    USING (VALUES
        (1, N'Value one'),
        (2, N'Value two')
    ) AS [Source] ([<Singular>ID], [Name])
    ON [Target].[<Singular>ID] = [Source].[<Singular>ID]
    WHEN MATCHED THEN UPDATE SET [Target].[Name] = [Source].[Name]
    WHEN NOT MATCHED BY TARGET THEN INSERT ([<Singular>ID], [Name]) VALUES ([Source].[<Singular>ID], [Source].[Name]);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
```

## Rules

1. `MERGE` on explicit IDs; `SET IDENTITY_INSERT` around it for identity keys.
2. Never delete rows in a seed.
3. Only reference data shared by every household. Household data is never seeded.
4. No real people's data.
