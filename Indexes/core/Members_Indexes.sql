/*******************************************************************************
 * Object Type: Index
 * Schema: core
 * Name: Indexes on [core].[Members]
 * Table: [core].[Members]
 * Description: Every non-primary-key index on the table, as created by 00000000_0002_Baseline_CoreHouseholds.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UX_Members_HouseholdId_UserId' AND [object_id] = OBJECT_ID(N'[core].[Members]'))
    CREATE UNIQUE INDEX [UX_Members_HouseholdId_UserId] ON [core].[Members] ([HouseholdId], [UserId]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Members_UserId' AND [object_id] = OBJECT_ID(N'[core].[Members]'))
    CREATE INDEX [IX_Members_UserId] ON [core].[Members] ([UserId]);
GO
