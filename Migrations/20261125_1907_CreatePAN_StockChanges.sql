/*
Migration: 20261125_1907_CreatePAN_StockChanges
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates PAN.StockChanges: History of every stock change (adjust, move, put away, status), for the activity feed and to explain counts. Written by the API; not exposed by Proxy.
Dependencies: 20261125_1906_CreatePAN_StockLevels, core.Households
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1907_CreatePAN_StockChanges';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[PAN].[StockChanges]', N'U') IS NULL
    BEGIN
        CREATE TABLE [PAN].[StockChanges]
        (
            [StockChangeID]  INT              IDENTITY(1,1) NOT NULL,
            [HouseholdId]    UNIQUEIDENTIFIER NOT NULL,
            [StockLevelId]   INT              NOT NULL,
            [ChangeType]     NVARCHAR(20)     NOT NULL,
            [QuantityBefore] DECIMAL(10,2)    NULL,
            [QuantityAfter]  DECIMAL(10,2)    NULL,
            [StatusAfter]    NVARCHAR(10)     NULL,
            [Note]           NVARCHAR(200)    NULL,
            [IsActive]     BIT               NOT NULL CONSTRAINT [DF_StockChanges_IsActive]    DEFAULT (1),
            [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_StockChanges_IsDeleted]   DEFAULT (0),
            [ModifiedDate] DATETIMEOFFSET(7) NULL,
            [ModifiedById] UNIQUEIDENTIFIER  NULL,
            [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_StockChanges_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
            [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_StockChanges_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT [PK_StockChanges] PRIMARY KEY CLUSTERED ([StockChangeID] ASC),
            CONSTRAINT [FK_StockChanges_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]),
            CONSTRAINT [FK_StockChanges_StockLevels] FOREIGN KEY ([StockLevelId]) REFERENCES [PAN].[StockLevels] ([StockLevelID]) ON DELETE CASCADE,
            CONSTRAINT [CK_StockChanges_ChangeType] CHECK ([ChangeType] IN (N'Adjust', N'Set', N'MoveIn', N'MoveOut', N'PutAway', N'Status'))
        );
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockChanges_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[StockChanges]'))
        CREATE NONCLUSTERED INDEX [IX_StockChanges_HouseholdId] ON [PAN].[StockChanges] ([HouseholdId], [CreatedDate] DESC);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockChanges_StockLevelId' AND [object_id] = OBJECT_ID(N'[PAN].[StockChanges]'))
        CREATE NONCLUSTERED INDEX [IX_StockChanges_StockLevelId] ON [PAN].[StockChanges] ([StockLevelId]);

    -- Households stay apart (DATABASE_CONSTITUTION.md, Article VIII)
    IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[StockChanges]'))
        EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
            ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[StockChanges],
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[StockChanges] AFTER INSERT,
            ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[StockChanges] AFTER UPDATE;');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates PAN.StockChanges', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

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
IF NOT EXISTS (SELECT 1 FROM [PAN].[StockChanges])
BEGIN
    ALTER SECURITY POLICY [security].[HouseholdIsolation]
        DROP FILTER PREDICATE ON [PAN].[StockChanges],
        DROP BLOCK PREDICATE ON [PAN].[StockChanges] AFTER INSERT,
        DROP BLOCK PREDICATE ON [PAN].[StockChanges] AFTER UPDATE;
    DROP TABLE [PAN].[StockChanges];
    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1907_CreatePAN_StockChanges';
END
*/
