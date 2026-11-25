/*
Migration: 20261125_1849_DropDBO_SchemaVersions
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Drops [dbo].[SchemaVersions], the journal of the old DbUp runner. Since
             00000000_0000_CreateSchemaVersionTable, [dbo].[SchemaVersion] is the only
             record of applied migrations and nothing reads the old table.
             Safety: the table is dropped only if every script it lists is one of the five
             baseline scripts and that baseline migration is recorded in [dbo].[SchemaVersion].
             Otherwise the migration fails and changes nothing.
             On a database that never had DbUp (a new Prod), it only records itself.
Dependencies: 00000000_0000_CreateSchemaVersionTable
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact: None for the API or the apps. Removes one table with at most five rows.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1849_DropDBO_SchemaVersions';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[dbo].[SchemaVersions]', N'U') IS NOT NULL
    BEGIN
        -- Every DbUp row must be a baseline script that dbo.SchemaVersion already records.
        IF EXISTS (
            SELECT 1
            FROM [dbo].[SchemaVersions] AS [J]
            WHERE NOT EXISTS (
                SELECT 1
                FROM (VALUES
                        (N'SosaFam.Database.Scripts.0001_auth_identity.sql',           N'00000000_0001_Baseline_AuthIdentity'),
                        (N'SosaFam.Database.Scripts.0002_core_households.sql',         N'00000000_0002_Baseline_CoreHouseholds'),
                        (N'SosaFam.Database.Scripts.0003_core_row_level_security.sql', N'00000000_0003_Baseline_CoreRowLevelSecurity'),
                        (N'SosaFam.Database.Scripts.0004_app_role.sql',                N'00000000_0004_Baseline_AppRole'),
                        (N'SosaFam.Database.Scripts.0005_grocery_lists.sql',           N'00000000_0005_Baseline_FamilyGroceryLists')
                    ) AS [B] ([LegacyScriptName], [MigrationName])
                    INNER JOIN [dbo].[SchemaVersion] AS [S]
                        ON [S].[MigrationName] = [B].[MigrationName] AND [S].[Success] = 1
                WHERE [B].[LegacyScriptName] = [J].[ScriptName]))
        BEGIN
            THROW 50001, N'dbo.SchemaVersions lists a script that dbo.SchemaVersion does not record. Nothing was dropped.', 1;
        END

        DROP TABLE [dbo].[SchemaVersions];
        PRINT 'Dropped dbo.SchemaVersions';
    END

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Drops the old DbUp journal dbo.SchemaVersions', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
-- Recreates DbUp's journal in DbUp's own shape (its Applied column is DATETIME, kept
-- deliberately so DbUp could read it again) with the five baseline rows.
IF OBJECT_ID(N'[dbo].[SchemaVersions]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[SchemaVersions]
    (
        [Id]         INT           IDENTITY(1,1) NOT NULL,
        [ScriptName] NVARCHAR(255) NOT NULL,
        [Applied]    DATETIME      NOT NULL,
        CONSTRAINT [PK_SchemaVersions_Id] PRIMARY KEY ([Id])
    );
    INSERT INTO [dbo].[SchemaVersions] ([ScriptName], [Applied])
    SELECT [B].[LegacyScriptName], [S].[AppliedDate]
    FROM (VALUES
            (N'SosaFam.Database.Scripts.0001_auth_identity.sql',           N'00000000_0001_Baseline_AuthIdentity'),
            (N'SosaFam.Database.Scripts.0002_core_households.sql',         N'00000000_0002_Baseline_CoreHouseholds'),
            (N'SosaFam.Database.Scripts.0003_core_row_level_security.sql', N'00000000_0003_Baseline_CoreRowLevelSecurity'),
            (N'SosaFam.Database.Scripts.0004_app_role.sql',                N'00000000_0004_Baseline_AppRole'),
            (N'SosaFam.Database.Scripts.0005_grocery_lists.sql',           N'00000000_0005_Baseline_FamilyGroceryLists')
        ) AS [B] ([LegacyScriptName], [MigrationName])
        INNER JOIN [dbo].[SchemaVersion] AS [S] ON [S].[MigrationName] = [B].[MigrationName] AND [S].[Success] = 1
    ORDER BY [B].[MigrationName];
END
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1849_DropDBO_SchemaVersions';
*/
