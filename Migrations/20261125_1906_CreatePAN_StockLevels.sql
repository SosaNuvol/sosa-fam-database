/*
Migration: 20261125_1906_CreatePAN_StockLevels
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates PAN.StockLevels: How much of one product is in one location: an exact Quantity for Count locations, a Status (Have / Low / Out) for Status locations.
Dependencies: 20261125_1905_CreatePAN_Products, 20261125_1904_CreatePAN_Locations, core.Households
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1906_CreatePAN_StockLevels';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[PAN].[StockLevels]', N'U') IS NULL
    BEGIN
        CREATE TABLE [PAN].[StockLevels]
        (
            [StockLevelID] INT              IDENTITY(1,1) NOT NULL,
            [HouseholdId]  UNIQUEIDENTIFIER NOT NULL,
            [ProductId]    INT              NOT NULL,
            [LocationId]   INT              NOT NULL,
            [Proxy]        VARCHAR(100)     NOT NULL,
            [PartKey]      VARCHAR(6)       NOT NULL,
            [Quantity]     DECIMAL(10,2)    NOT NULL CONSTRAINT [DF_StockLevels_Quantity] DEFAULT (0),
            [Status]       NVARCHAR(10)     NULL,
            [IsActive]     BIT               NOT NULL CONSTRAINT [DF_StockLevels_IsActive]    DEFAULT (1),
            [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_StockLevels_IsDeleted]   DEFAULT (0),
            [ModifiedDate] DATETIMEOFFSET(7) NULL,
            [ModifiedById] UNIQUEIDENTIFIER  NULL,
            [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_StockLevels_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
            [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_StockLevels_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT [PK_StockLevels] PRIMARY KEY CLUSTERED ([StockLevelID] ASC),
            CONSTRAINT [FK_StockLevels_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]),
            CONSTRAINT [FK_StockLevels_Products] FOREIGN KEY ([ProductId]) REFERENCES [PAN].[Products] ([ProductID]) ON DELETE CASCADE,
            CONSTRAINT [FK_StockLevels_Locations] FOREIGN KEY ([LocationId]) REFERENCES [PAN].[Locations] ([LocationID]),
            CONSTRAINT [UQ_StockLevels_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_StockLevels_Quantity] CHECK ([Quantity] >= 0),
            CONSTRAINT [CK_StockLevels_Status] CHECK ([Status] IS NULL OR [Status] IN (N'Have', N'Low', N'Out'))
        );
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockLevels_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
        CREATE NONCLUSTERED INDEX [IX_StockLevels_HouseholdId] ON [PAN].[StockLevels] ([HouseholdId]) INCLUDE ([ProductId], [LocationId], [Quantity], [Status]) WHERE [IsDeleted] = 0;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockLevels_LocationId' AND [object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
        CREATE NONCLUSTERED INDEX [IX_StockLevels_LocationId] ON [PAN].[StockLevels] ([LocationId]);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_StockLevels_ProductId_LocationId' AND [object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockLevels_ProductId_LocationId] ON [PAN].[StockLevels] ([ProductId], [LocationId]) WHERE [IsDeleted] = 0;

    -- Households stay apart (DATABASE_CONSTITUTION.md, Article VIII)
    IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
        EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
            ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[StockLevels],
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[StockLevels] AFTER INSERT,
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[StockLevels] AFTER UPDATE;');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates PAN.StockLevels', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
IF NOT EXISTS (SELECT 1 FROM [PAN].[StockLevels])
BEGIN
    ALTER SECURITY POLICY [security].[HouseholdIsolation]
        DROP FILTER PREDICATE ON [PAN].[StockLevels],
        DROP BLOCK PREDICATE ON [PAN].[StockLevels] AFTER INSERT,
        DROP BLOCK PREDICATE ON [PAN].[StockLevels] AFTER UPDATE;
    DROP TABLE [PAN].[StockLevels];
    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1906_CreatePAN_StockLevels';
END
*/
