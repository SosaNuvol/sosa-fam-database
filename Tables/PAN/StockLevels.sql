/*******************************************************************************
 * Object Type: Table
 * Schema: PAN
 * Name: StockLevels
 * Description: How much of one product is in one location: an exact Quantity for Count locations, a Status (Have / Low / Out) for Status locations.
 * Dependencies: 1905_CreatePAN_Products, 1904_CreatePAN_Locations, core.Households, security.HouseholdIsolation
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1906_CreatePAN_StockLevels)
 * Proxy-ID prefix: PAST (.github/ProxyID-PrefixRegistry.md)
 * Notes: Only one cascade path may reach a table: rows go with their product
 *        (FK_StockLevels_Products CASCADE); the Households and Locations FKs are NO ACTION.
 ******************************************************************************/

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
GO
