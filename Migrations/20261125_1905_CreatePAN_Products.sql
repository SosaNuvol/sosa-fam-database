/*
Migration: 20261125_1905_CreatePAN_Products
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates PAN.Products: Kinds of food a household keeps, shared across locations, with the household-wide minimum and target quantities that drive restocking.
Dependencies: 20261125_1904_CreatePAN_Locations, core.Households, core.Stores
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1905_CreatePAN_Products';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[PAN].[Products]', N'U') IS NULL
    BEGIN
        CREATE TABLE [PAN].[Products]
        (
            [ProductID]      INT              IDENTITY(1,1) NOT NULL,
            [HouseholdId]    UNIQUEIDENTIFIER NOT NULL,
            [StoreId]        UNIQUEIDENTIFIER NULL,
            [Proxy]          VARCHAR(100)     NOT NULL,
            [PartKey]        VARCHAR(6)       NOT NULL,
            [ProxyGuid]      AS CONVERT(UNIQUEIDENTIFIER, RIGHT([Proxy], 36)) PERSISTED,
            [Name]           NVARCHAR(120)    NOT NULL,
            [Barcode]        NVARCHAR(32)     NULL,
            [Category]       NVARCHAR(60)     NULL,
            [Unit]           NVARCHAR(20)     NULL,
            [MinQuantity]    DECIMAL(10,2)    NULL,
            [TargetQuantity] DECIMAL(10,2)    NULL,
            [IsStaple]       BIT              NOT NULL CONSTRAINT [DF_Products_IsStaple] DEFAULT (0),
            [ImageUrl]       NVARCHAR(500)    NULL,
            [IsActive]     BIT               NOT NULL CONSTRAINT [DF_Products_IsActive]    DEFAULT (1),
            [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_Products_IsDeleted]   DEFAULT (0),
            [ModifiedDate] DATETIMEOFFSET(7) NULL,
            [ModifiedById] UNIQUEIDENTIFIER  NULL,
            [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Products_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
            [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_Products_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductID] ASC),
            CONSTRAINT [FK_Products_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE,
            CONSTRAINT [FK_Products_Stores] FOREIGN KEY ([StoreId]) REFERENCES [core].[Stores] ([Id]),
            CONSTRAINT [UQ_Products_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_Products_MinQuantity] CHECK ([MinQuantity] IS NULL OR [MinQuantity] >= 0),
            CONSTRAINT [CK_Products_TargetQuantity] CHECK ([TargetQuantity] IS NULL OR [TargetQuantity] >= ISNULL([MinQuantity], 0))
        );
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Products_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
        CREATE NONCLUSTERED INDEX [IX_Products_HouseholdId] ON [PAN].[Products] ([HouseholdId]) INCLUDE ([Name], [Category], [MinQuantity], [TargetQuantity], [IsStaple]) WHERE [IsDeleted] = 0;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Products_StoreId' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
        CREATE NONCLUSTERED INDEX [IX_Products_StoreId] ON [PAN].[Products] ([StoreId]);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_Products_ProxyGuid' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_ProxyGuid] ON [PAN].[Products] ([ProxyGuid]);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_Products_HouseholdId_Barcode' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
        CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_HouseholdId_Barcode] ON [PAN].[Products] ([HouseholdId], [Barcode]) WHERE [Barcode] IS NOT NULL AND [IsDeleted] = 0;

    -- Households stay apart (DATABASE_CONSTITUTION.md, Article VIII)
    IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[Products]'))
        EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
            ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[Products],
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[Products] AFTER INSERT,
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[Products] AFTER UPDATE;');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates PAN.Products', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
IF NOT EXISTS (SELECT 1 FROM [PAN].[Products])
BEGIN
    ALTER SECURITY POLICY [security].[HouseholdIsolation]
        DROP FILTER PREDICATE ON [PAN].[Products],
        DROP BLOCK PREDICATE ON [PAN].[Products] AFTER INSERT,
        DROP BLOCK PREDICATE ON [PAN].[Products] AFTER UPDATE;
    DROP TABLE [PAN].[Products];
    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1905_CreatePAN_Products';
END
*/
