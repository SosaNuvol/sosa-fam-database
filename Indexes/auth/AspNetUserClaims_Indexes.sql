/*******************************************************************************
 * Object Type: Index
 * Schema: auth
 * Name: Indexes on [auth].[AspNetUserClaims]
 * Table: [auth].[AspNetUserClaims]
 * Description: Every non-primary-key index on the table, as created by 00000000_0001_Baseline_AuthIdentity.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_AspNetUserClaims_UserId' AND [object_id] = OBJECT_ID(N'[auth].[AspNetUserClaims]'))
    CREATE INDEX [IX_AspNetUserClaims_UserId] ON [auth].[AspNetUserClaims] ([UserId]);
GO
