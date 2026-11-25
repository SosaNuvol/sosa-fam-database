/*******************************************************************************
 * Object Type: Indexes
 * Schema: PAN
 * Name: Products_Indexes
 * Description: Indexes on PAN.Products.
 * Dependencies: PAN.Products
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1905_CreatePAN_Products)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Products_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
    CREATE NONCLUSTERED INDEX [IX_Products_HouseholdId] ON [PAN].[Products] ([HouseholdId]) INCLUDE ([Name], [Category], [MinQuantity], [TargetQuantity], [IsStaple]) WHERE [IsDeleted] = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Products_StoreId' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
    CREATE NONCLUSTERED INDEX [IX_Products_StoreId] ON [PAN].[Products] ([StoreId]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_Products_ProxyGuid' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_ProxyGuid] ON [PAN].[Products] ([ProxyGuid]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_Products_HouseholdId_Barcode' AND [object_id] = OBJECT_ID(N'[PAN].[Products]'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_HouseholdId_Barcode] ON [PAN].[Products] ([HouseholdId], [Barcode]) WHERE [Barcode] IS NOT NULL AND [IsDeleted] = 0;
GO
