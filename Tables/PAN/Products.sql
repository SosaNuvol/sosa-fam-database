/*******************************************************************************
 * Object Type: Table
 * Schema: PAN
 * Name: Products
 * Description: Kinds of food a household keeps, shared across locations, with the household-wide minimum and target quantities that drive restocking.
 * Dependencies: 1904_CreatePAN_Locations, core.Households, core.Stores, security.HouseholdIsolation
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1905_CreatePAN_Products)
 * Proxy-ID prefix: PAPR (.github/ProxyID-PrefixRegistry.md)
 * Notes: FK_Products_Stores is NO ACTION (one cascade path per table); the store delete
 *        endpoint clears StoreId first. family.GroceryItems.ProductId holds the GUID
 *        segment of a product's Proxy (loose reference),
 *        matched through the persisted ProxyGuid column.
 ******************************************************************************/

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
GO
