/*******************************************************************************
 * Object Type: Table
 * Schema: auth
 * Name: RefreshTokens
 * Description: Single-use refresh tokens for the API's JWT sign-in. Only a SHA-256 hash of each token is stored.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0001_Baseline_AuthIdentity)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[auth].[RefreshTokens]', N'U') IS NULL
BEGIN
    CREATE TABLE [auth].[RefreshTokens]
    (
        [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_RefreshTokens_Id] DEFAULT NEWSEQUENTIALID(),
        [UserId] uniqueidentifier NOT NULL,
        [TokenHash] binary(32) NOT NULL,
        [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_RefreshTokens_CreatedAt] DEFAULT SYSUTCDATETIME(),
        [ExpiresAt] datetime2(0) NOT NULL,
        [RevokedAt] datetime2(0) NULL,
        CONSTRAINT [PK_RefreshTokens] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_RefreshTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END
GO
