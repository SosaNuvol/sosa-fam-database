-- ASP.NET Core Identity user store (users, external logins, tokens).
-- Generated from EF Core 8 IdentityUserContext<IdentityUser<Guid>, Guid> with schema 'auth',
-- plus a DisplayName column used by the apps.

IF SCHEMA_ID(N'auth') IS NULL EXEC(N'CREATE SCHEMA [auth];');
GO

CREATE TABLE [auth].[AspNetUsers] (
    [Id] uniqueidentifier NOT NULL,
    [UserName] nvarchar(256) NULL,
    [NormalizedUserName] nvarchar(256) NULL,
    [Email] nvarchar(256) NULL,
    [NormalizedEmail] nvarchar(256) NULL,
    [EmailConfirmed] bit NOT NULL,
    [PasswordHash] nvarchar(max) NULL,
    [SecurityStamp] nvarchar(max) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    [PhoneNumber] nvarchar(max) NULL,
    [PhoneNumberConfirmed] bit NOT NULL,
    [TwoFactorEnabled] bit NOT NULL,
    [LockoutEnd] datetimeoffset NULL,
    [LockoutEnabled] bit NOT NULL,
    [AccessFailedCount] int NOT NULL,
    [DisplayName] nvarchar(100) NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [auth].[AspNetUserClaims] (
    [Id] int NOT NULL IDENTITY,
    [UserId] uniqueidentifier NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [auth].[AspNetUserLogins] (
    [LoginProvider] nvarchar(450) NOT NULL,
    [ProviderKey] nvarchar(450) NOT NULL,
    [ProviderDisplayName] nvarchar(max) NULL,
    [UserId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
    CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [auth].[AspNetUserTokens] (
    [UserId] uniqueidentifier NOT NULL,
    [LoginProvider] nvarchar(450) NOT NULL,
    [Name] nvarchar(450) NOT NULL,
    [Value] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
    CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_AspNetUserClaims_UserId] ON [auth].[AspNetUserClaims] ([UserId]);
GO

CREATE INDEX [IX_AspNetUserLogins_UserId] ON [auth].[AspNetUserLogins] ([UserId]);
GO

CREATE INDEX [EmailIndex] ON [auth].[AspNetUsers] ([NormalizedEmail]);
GO

CREATE UNIQUE INDEX [UserNameIndex] ON [auth].[AspNetUsers] ([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;
GO


-- Refresh tokens for the API's JWT sign-in. Only a SHA-256 hash of each token is stored.
CREATE TABLE [auth].[RefreshTokens] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_RefreshTokens_Id] DEFAULT NEWSEQUENTIALID(),
    [UserId] uniqueidentifier NOT NULL,
    [TokenHash] binary(32) NOT NULL,
    [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_RefreshTokens_CreatedAt] DEFAULT SYSUTCDATETIME(),
    [ExpiresAt] datetime2(0) NOT NULL,
    [RevokedAt] datetime2(0) NULL,
    CONSTRAINT [PK_RefreshTokens] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_RefreshTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [auth].[AspNetUsers] ([Id]) ON DELETE CASCADE
);
GO

CREATE UNIQUE INDEX [UX_RefreshTokens_TokenHash] ON [auth].[RefreshTokens] ([TokenHash]);
GO

CREATE INDEX [IX_RefreshTokens_UserId] ON [auth].[RefreshTokens] ([UserId]);
GO
