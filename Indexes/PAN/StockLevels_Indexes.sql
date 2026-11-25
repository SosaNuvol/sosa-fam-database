/*******************************************************************************
 * Object Type: Indexes
 * Schema: PAN
 * Name: StockLevels_Indexes
 * Description: Indexes on PAN.StockLevels.
 * Dependencies: PAN.StockLevels
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1906_CreatePAN_StockLevels)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockLevels_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
    CREATE NONCLUSTERED INDEX [IX_StockLevels_HouseholdId] ON [PAN].[StockLevels] ([HouseholdId]) INCLUDE ([ProductId], [LocationId], [Quantity], [Status]) WHERE [IsDeleted] = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockLevels_LocationId' AND [object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
    CREATE NONCLUSTERED INDEX [IX_StockLevels_LocationId] ON [PAN].[StockLevels] ([LocationId]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_StockLevels_ProductId_LocationId' AND [object_id] = OBJECT_ID(N'[PAN].[StockLevels]'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_StockLevels_ProductId_LocationId] ON [PAN].[StockLevels] ([ProductId], [LocationId]) WHERE [IsDeleted] = 0;
GO
