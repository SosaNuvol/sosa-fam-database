/*******************************************************************************
 * Object Type: Table
 * Schema: core
 * Name: Members
 * Description: A person's membership and role (Owner, Adult, Member, Child) in a household. One login can belong to several households.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0002_Baseline_CoreHouseholds)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[core].[Members]', N'U') IS NULL
BEGIN
    CREATE TABLE [core].[Members]
    (
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
END
GO
