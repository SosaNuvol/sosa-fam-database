/*
Migration: YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>
Author:
Date: YYYY-MM-DD
Description:
Dependencies:
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact:
*/

-- Copy this file to Migrations/YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql (UTC time), then
-- replace every placeholder. The runner skips files that start with an underscore.

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- === MIGRATION LOGIC ===
    -- Guard every statement: IF OBJECT_ID(...) IS NULL, IF COL_LENGTH(...) IS NULL,
    -- IF NOT EXISTS (SELECT 1 FROM sys.indexes ...). Objects that must be the first
    -- statement in a batch (views, functions, procedures, triggers) go through
    -- EXEC(N'CREATE ...') inside the guard.

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'<Description>', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- Specific undo steps, in reverse order. Never delete household data without a backup.
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>';
*/
