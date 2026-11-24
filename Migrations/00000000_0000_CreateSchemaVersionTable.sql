/*
Migration: 00000000_0000_CreateSchemaVersionTable
Author: Claude (for Andres Sosa)
Date: 2026-11-24
Description: Creates [dbo].[SchemaVersion], the record of every applied migration.
             On a database that was built with the old DbUp runner (journal table
             [dbo].[SchemaVersions]), it also records the five baseline migrations that
             DbUp already applied, so they are never run a second time.
Dependencies: None. This must be the first migration in every database.
Rollback: See the ROLLBACK SCRIPT block at the end. Only on a database you are rebuilding.
Expected impact: One new table. No existing object or row is changed.
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
    DECLARE @MigrationName NVARCHAR(255) = N'00000000_0000_CreateSchemaVersionTable';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    IF OBJECT_ID(N'[dbo].[SchemaVersion]', N'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].[SchemaVersion]
        (
            [SchemaVersionID] INT            IDENTITY(1,1) NOT NULL,
            [MigrationName]   NVARCHAR(255)  NOT NULL,
            [Description]     NVARCHAR(500)  NULL,
            [AppliedDate]     DATETIME2(7)   NOT NULL CONSTRAINT [DF_SchemaVersion_AppliedDate] DEFAULT (SYSUTCDATETIME()),
            [AppliedBy]       NVARCHAR(128)  NOT NULL CONSTRAINT [DF_SchemaVersion_AppliedBy] DEFAULT (SUSER_SNAME()),
            [Success]         BIT            NOT NULL CONSTRAINT [DF_SchemaVersion_Success] DEFAULT (1),
            [ExecutionTimeMs] INT            NULL,
            CONSTRAINT [PK_SchemaVersion] PRIMARY KEY CLUSTERED ([SchemaVersionID] ASC)
        );

        CREATE UNIQUE NONCLUSTERED INDEX [UQ_SchemaVersion_MigrationName]
            ON [dbo].[SchemaVersion] ([MigrationName])
            WHERE [Success] = 1;
    END

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Baseline scripts that the old DbUp runner applied keep their history here.
    IF OBJECT_ID(N'[dbo].[SchemaVersions]', N'U') IS NOT NULL
    BEGIN
        INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [AppliedDate], [AppliedBy], [Success])
        SELECT
            [B].[MigrationName],
            N'Baseline, applied earlier by DbUp as ' + [J].[ScriptName],
            [J].[Applied],
            SUSER_SNAME(),
            1
        FROM
            (VALUES
                (N'SosaFam.Database.Scripts.0001_auth_identity.sql',         N'00000000_0001_Baseline_AuthIdentity'),
                (N'SosaFam.Database.Scripts.0002_core_households.sql',       N'00000000_0002_Baseline_CoreHouseholds'),
                (N'SosaFam.Database.Scripts.0003_core_row_level_security.sql', N'00000000_0003_Baseline_CoreRowLevelSecurity'),
                (N'SosaFam.Database.Scripts.0004_app_role.sql',              N'00000000_0004_Baseline_AppRole'),
                (N'SosaFam.Database.Scripts.0005_grocery_lists.sql',         N'00000000_0005_Baseline_FamilyGroceryLists')
            ) AS [B] ([LegacyScriptName], [MigrationName])
            INNER JOIN [dbo].[SchemaVersions] AS [J] ON [J].[ScriptName] = [B].[LegacyScriptName]
        WHERE
            NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] AS [S]
                        WHERE [S].[MigrationName] = [B].[MigrationName] AND [S].[Success] = 1);
    END

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates the SchemaVersion table', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
-- Only on a database you are rebuilding: every later migration depends on this table.
DROP TABLE IF EXISTS [dbo].[SchemaVersion];
*/
