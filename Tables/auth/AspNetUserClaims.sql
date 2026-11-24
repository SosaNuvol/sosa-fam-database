/*******************************************************************************
 * Object Type: Table
 * Schema: auth
 * Name: AspNetUserClaims
 * Description: ASP.NET Core Identity claims per user.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0001_Baseline_AuthIdentity)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[auth].[AspNetUserClaims]', N'U') IS NULL
BEGIN
    CREATE TABLE [auth].[AspNetUserClaims]
    (
        [Id] int NOT NULL IDENTITY,
        [UserId] uniqueidentifier NOT NULL,
        [ClaimType] nvarchar(max) NULL,
        [ClaimValue] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END
GO
