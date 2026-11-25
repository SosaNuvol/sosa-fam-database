/*******************************************************************************
 * Object Type: Table
 * Schema: core
 * Name: Households
 * Description: Households are the tenants shared by every Sosa Fam app. Protected by security.HouseholdIsolation.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0002_Baseline_CoreHouseholds)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[core].[Households]', N'U') IS NULL
BEGIN
    CREATE TABLE [core].[Households]
    (
        [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Households_Id] DEFAULT NEWSEQUENTIALID(),
        [Name] nvarchar(100) NOT NULL,
        [CreatedByUserId] uniqueidentifier NOT NULL,
        [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_Households_CreatedAt] DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [PK_Households] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Households_AspNetUsers_CreatedByUserId] FOREIGN KEY ([CreatedByUserId]) REFERENCES [auth].[AspNetUsers] ([Id])
    );
END
GO
