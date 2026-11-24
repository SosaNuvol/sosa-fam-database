/*******************************************************************************
 * Object Type: Table
 * Schema: core
 * Name: Invites
 * Description: Invitations to join a household. Only the SHA-256 hash of the invite code is stored.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0002_Baseline_CoreHouseholds)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[core].[Invites]', N'U') IS NULL
BEGIN
    CREATE TABLE [core].[Invites]
    (
        [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Invites_Id] DEFAULT NEWSEQUENTIALID(),
        [HouseholdId] uniqueidentifier NOT NULL,
        [CodeHash] binary(32) NOT NULL,
        [Role] nvarchar(10) NOT NULL,
        [CreatedByUserId] uniqueidentifier NOT NULL,
        [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_Invites_CreatedAt] DEFAULT SYSUTCDATETIME(),
        [ExpiresAt] datetime2(0) NOT NULL,
        [AcceptedAt] datetime2(0) NULL,
        [AcceptedByUserId] uniqueidentifier NULL,
        [RevokedAt] datetime2(0) NULL,
        CONSTRAINT [PK_Invites] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Invites_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Invites_AspNetUsers_CreatedByUserId] FOREIGN KEY ([CreatedByUserId]) REFERENCES [auth].[AspNetUsers] ([Id]),
        CONSTRAINT [FK_Invites_AspNetUsers_AcceptedByUserId] FOREIGN KEY ([AcceptedByUserId]) REFERENCES [auth].[AspNetUsers] ([Id]),
        CONSTRAINT [CK_Invites_Role] CHECK ([Role] IN (N'Adult', N'Member', N'Child'))
    );
END
GO
