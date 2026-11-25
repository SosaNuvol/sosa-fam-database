/*******************************************************************************
 * Object Type: Index
 * Schema: auth
 * Name: Indexes on [auth].[RefreshTokens]
 * Table: [auth].[RefreshTokens]
 * Description: Every non-primary-key index on the table, as created by 00000000_0001_Baseline_AuthIdentity.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UX_RefreshTokens_TokenHash' AND [object_id] = OBJECT_ID(N'[auth].[RefreshTokens]'))
    CREATE UNIQUE INDEX [UX_RefreshTokens_TokenHash] ON [auth].[RefreshTokens] ([TokenHash]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_RefreshTokens_UserId' AND [object_id] = OBJECT_ID(N'[auth].[RefreshTokens]'))
    CREATE INDEX [IX_RefreshTokens_UserId] ON [auth].[RefreshTokens] ([UserId]);
GO
