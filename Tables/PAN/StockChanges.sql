/*******************************************************************************
 * Object Type: Table
 * Schema: PAN
 * Name: StockChanges
 * Description: History of every stock change (adjust, move, put away, status), for the activity feed and to explain counts. Written by the API; not exposed by Proxy.
 * Dependencies: 1906_CreatePAN_StockLevels, core.Households, security.HouseholdIsolation
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1907_CreatePAN_StockChanges)
 * Notes: No Proxy-ID: the API does not expose these rows by id.
 ******************************************************************************/

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
GO
