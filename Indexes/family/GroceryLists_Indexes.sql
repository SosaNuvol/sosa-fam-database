/*******************************************************************************
 * Object Type: Index
 * Schema: family
 * Name: Indexes on [family].[GroceryLists]
 * Table: [family].[GroceryLists]
 * Description: Every non-primary-key index on the table, as created by 00000000_0005_Baseline_FamilyGroceryLists.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_GroceryLists_HouseholdId' AND [object_id] = OBJECT_ID(N'[family].[GroceryLists]'))
    CREATE INDEX [IX_GroceryLists_HouseholdId] ON [family].[GroceryLists] ([HouseholdId]);
GO
