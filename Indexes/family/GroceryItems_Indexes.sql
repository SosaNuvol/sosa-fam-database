/*******************************************************************************
 * Object Type: Index
 * Schema: family
 * Name: Indexes on [family].[GroceryItems]
 * Table: [family].[GroceryItems]
 * Description: Every non-primary-key index on the table, as created by 00000000_0005_Baseline_FamilyGroceryLists.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_GroceryItems_ListId' AND [object_id] = OBJECT_ID(N'[family].[GroceryItems]'))
    CREATE INDEX [IX_GroceryItems_ListId] ON [family].[GroceryItems] ([ListId]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_GroceryItems_HouseholdId' AND [object_id] = OBJECT_ID(N'[family].[GroceryItems]'))
    CREATE INDEX [IX_GroceryItems_HouseholdId] ON [family].[GroceryItems] ([HouseholdId]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_GroceryItems_StoreId' AND [object_id] = OBJECT_ID(N'[family].[GroceryItems]'))
    CREATE INDEX [IX_GroceryItems_StoreId] ON [family].[GroceryItems] ([StoreId]);
GO
