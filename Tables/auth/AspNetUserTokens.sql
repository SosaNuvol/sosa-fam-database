/*******************************************************************************
 * Object Type: Table
 * Schema: auth
 * Name: AspNetUserTokens
 * Description: ASP.NET Core Identity tokens per user and login provider.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0001_Baseline_AuthIdentity)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[auth].[AspNetUserTokens]', N'U') IS NULL
BEGIN
    CREATE TABLE [auth].[AspNetUserTokens]
    (
        [UserId] uniqueidentifier NOT NULL,
        [LoginProvider] nvarchar(450) NOT NULL,
        [Name] nvarchar(450) NOT NULL,
        [Value] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
        CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END
GO
