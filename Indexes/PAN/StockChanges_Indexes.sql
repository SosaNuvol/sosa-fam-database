/*******************************************************************************
 * Object Type: Indexes
 * Schema: PAN
 * Name: StockChanges_Indexes
 * Description: Indexes on PAN.StockChanges.
 * Dependencies: PAN.StockChanges
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1907_CreatePAN_StockChanges)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockChanges_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[StockChanges]'))
    CREATE NONCLUSTERED INDEX [IX_StockChanges_HouseholdId] ON [PAN].[StockChanges] ([HouseholdId], [CreatedDate] DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_StockChanges_StockLevelId' AND [object_id] = OBJECT_ID(N'[PAN].[StockChanges]'))
    CREATE NONCLUSTERED INDEX [IX_StockChanges_StockLevelId] ON [PAN].[StockChanges] ([StockLevelId]);
GO
