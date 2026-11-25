/*
Migration: 20261125_1902_CreatePAN_Schema
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates the PAN schema. The food storage app (pantry): locations, products, stock levels and their history.
Dependencies: 00000000_0004_Baseline_AppRole
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact: One new empty schema; sosafam_api gets data access to it.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1902_CreatePAN_Schema';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'PAN')
        EXEC(N'CREATE SCHEMA [PAN]');

    -- The API reads and writes the food storage tables (DATABASE_CONSTITUTION.md, Article X)
    IF DATABASE_PRINCIPAL_ID(N'sosafam_api') IS NOT NULL
        GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[PAN] TO [sosafam_api];

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates schema PAN', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
REVOKE SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[PAN] FROM [sosafam_api];
DROP SCHEMA [PAN];  -- only once every object in it is gone
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1902_CreatePAN_Schema';
*/
