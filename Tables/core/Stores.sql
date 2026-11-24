/*******************************************************************************
 * Object Type: Table
 * Schema: core
 * Name: Stores
 * Description: Stores (WinCo, Costco, ...) a household shops at. Shared by every app.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0005_Baseline_FamilyGroceryLists)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[core].[Stores]', N'U') IS NULL
BEGIN
    CREATE TABLE [core].[Stores]
    (
        [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Stores_Id] DEFAULT NEWSEQUENTIALID(),
        [HouseholdId] uniqueidentifier NOT NULL,
        [Name] nvarchar(60) NOT NULL,
        [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_Stores_CreatedAt] DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [PK_Stores] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Stores_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE
    );
END
GO
