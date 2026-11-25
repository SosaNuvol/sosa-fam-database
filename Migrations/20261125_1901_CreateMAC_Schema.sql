/*
Migration: 20261125_1901_CreateMAC_Schema
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates the MAC schema. Proxy-ID catalog: prefixes and the functions that build and read Proxy-IDs.
Dependencies: 00000000_0004_Baseline_AppRole
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact: One new empty schema.
*/

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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1901_CreateMAC_Schema';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'MAC')
        EXEC(N'CREATE SCHEMA [MAC]');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates schema MAC', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
SET QUOTED_IDENTIFIER ON;
DROP SCHEMA [MAC];  -- only once every object in it is gone
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1901_CreateMAC_Schema';
*/
