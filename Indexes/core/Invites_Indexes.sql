/*******************************************************************************
 * Object Type: Index
 * Schema: core
 * Name: Indexes on [core].[Invites]
 * Table: [core].[Invites]
 * Description: Every non-primary-key index on the table, as created by 00000000_0002_Baseline_CoreHouseholds.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UX_Invites_CodeHash' AND [object_id] = OBJECT_ID(N'[core].[Invites]'))
    CREATE UNIQUE INDEX [UX_Invites_CodeHash] ON [core].[Invites] ([CodeHash]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Invites_HouseholdId' AND [object_id] = OBJECT_ID(N'[core].[Invites]'))
    CREATE INDEX [IX_Invites_HouseholdId] ON [core].[Invites] ([HouseholdId]);
GO
