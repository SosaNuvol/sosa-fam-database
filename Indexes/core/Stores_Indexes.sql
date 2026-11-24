/*******************************************************************************
 * Object Type: Index
 * Schema: core
 * Name: Indexes on [core].[Stores]
 * Table: [core].[Stores]
 * Description: Every non-primary-key index on the table, as created by 00000000_0005_Baseline_FamilyGroceryLists.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UX_Stores_HouseholdId_Name' AND [object_id] = OBJECT_ID(N'[core].[Stores]'))
    CREATE UNIQUE INDEX [UX_Stores_HouseholdId_Name] ON [core].[Stores] ([HouseholdId], [Name]);
GO
