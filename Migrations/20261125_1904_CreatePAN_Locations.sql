/*
Migration: 20261125_1904_CreatePAN_Locations
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates PAN.Locations: Places a household keeps food (Pantry, Fridge, Basement, ...). TrackingMode Count keeps exact quantities; Status keeps Have / Low / Out.
Dependencies: 20261125_1902_CreatePAN_Schema, 20261125_1903_CreateMAC_ProxyIdInfrastructure, core.Households
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact: One new empty table, added to security.HouseholdIsolation.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1904_CreatePAN_Locations';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[PAN].[Locations]', N'U') IS NULL
    BEGIN
        CREATE TABLE [PAN].[Locations]
        (
            [LocationID]   INT              IDENTITY(1,1) NOT NULL,
            [HouseholdId]  UNIQUEIDENTIFIER NOT NULL,
            [Proxy]        VARCHAR(100)     NOT NULL,
            [PartKey]      VARCHAR(6)       NOT NULL,
            [Name]         NVARCHAR(60)     NOT NULL,
            [TrackingMode] NVARCHAR(10)     NOT NULL CONSTRAINT [DF_Locations_TrackingMode] DEFAULT (N'Count'),
            [SortOrder]    INT              NOT NULL CONSTRAINT [DF_Locations_SortOrder] DEFAULT (0),
            [IsActive]     BIT               NOT NULL CONSTRAINT [DF_Locations_IsActive]    DEFAULT (1),
            [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_Locations_IsDeleted]   DEFAULT (0),
            [ModifiedDate] DATETIMEOFFSET(7) NULL,
            [ModifiedById] UNIQUEIDENTIFIER  NULL,
            [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Locations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
            [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_Locations_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT [PK_Locations] PRIMARY KEY CLUSTERED ([LocationID] ASC),
            CONSTRAINT [FK_Locations_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE,
            CONSTRAINT [UQ_Locations_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_Locations_TrackingMode] CHECK ([TrackingMode] IN (N'Count', N'Status'))
        );
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Locations_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[Locations]'))
        CREATE NONCLUSTERED INDEX [IX_Locations_HouseholdId] ON [PAN].[Locations] ([HouseholdId]) INCLUDE ([Name], [TrackingMode], [SortOrder]) WHERE [IsDeleted] = 0;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_Locations_HouseholdId_Name' AND [object_id] = OBJECT_ID(N'[PAN].[Locations]'))
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Locations_HouseholdId_Name] ON [PAN].[Locations] ([HouseholdId], [Name]) WHERE [IsDeleted] = 0;

    -- Households stay apart (DATABASE_CONSTITUTION.md, Article VIII)
    IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[Locations]'))
        EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
            ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[Locations],
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[Locations] AFTER INSERT,
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[Locations] AFTER UPDATE;');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates PAN.Locations', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
-- Refuses to lose data: only when the table is empty.
IF NOT EXISTS (SELECT 1 FROM [PAN].[Locations])
BEGIN
    ALTER SECURITY POLICY [security].[HouseholdIsolation]
        DROP FILTER PREDICATE ON [PAN].[Locations],
        DROP BLOCK PREDICATE ON [PAN].[Locations] AFTER INSERT,
        DROP BLOCK PREDICATE ON [PAN].[Locations] AFTER UPDATE;
    DROP TABLE [PAN].[Locations];
    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1904_CreatePAN_Locations';
END
*/
