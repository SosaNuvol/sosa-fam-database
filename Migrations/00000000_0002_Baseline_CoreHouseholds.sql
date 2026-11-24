-- Households are the tenants shared by every Sosa Fam app (data sharing, food storage, ...).
-- Every tenant-owned table carries a HouseholdId and is protected by the row-level
-- security policies in 0003_core_row_level_security.sql.

IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA [core];');
GO

CREATE TABLE [core].[Households] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Households_Id] DEFAULT NEWSEQUENTIALID(),
    [Name] nvarchar(100) NOT NULL,
    [CreatedByUserId] uniqueidentifier NOT NULL,
    [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_Households_CreatedAt] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_Households] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Households_AspNetUsers_CreatedByUserId] FOREIGN KEY ([CreatedByUserId]) REFERENCES [auth].[AspNetUsers] ([Id])
);
GO

-- A person's membership in a household. One login can belong to several households.
-- Roles: Owner (everything), Adult (manage members, adult-only items), Member, Child.
CREATE TABLE [core].[Members] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Members_Id] DEFAULT NEWSEQUENTIALID(),
    [HouseholdId] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NOT NULL,
    [Role] nvarchar(10) NOT NULL,
    [DisplayName] nvarchar(100) NOT NULL,
    [JoinedAt] datetime2(0) NOT NULL CONSTRAINT [DF_Members_JoinedAt] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_Members] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Members_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Members_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [CK_Members_Role] CHECK ([Role] IN (N'Owner', N'Adult', N'Member', N'Child'))
);
GO

CREATE UNIQUE INDEX [UX_Members_HouseholdId_UserId] ON [core].[Members] ([HouseholdId], [UserId]);
GO

CREATE INDEX [IX_Members_UserId] ON [core].[Members] ([UserId]);
GO

-- Invitations to join a household. The code itself is never stored, only its SHA-256 hash.
CREATE TABLE [core].[Invites] (
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
GO

CREATE UNIQUE INDEX [UX_Invites_CodeHash] ON [core].[Invites] ([CodeHash]);
GO

CREATE INDEX [IX_Invites_HouseholdId] ON [core].[Invites] ([HouseholdId]);
GO
