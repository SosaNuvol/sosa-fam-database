/*******************************************************************************
 * Object Type: Table
 * Schema: family
 * Name: GroceryLists
 * Description: Grocery lists shared by a household.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0005_Baseline_FamilyGroceryLists)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[family].[GroceryLists]', N'U') IS NULL
BEGIN
    CREATE TABLE [family].[GroceryLists]
    (
        [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_GroceryLists_Id] DEFAULT NEWSEQUENTIALID(),
        [HouseholdId] uniqueidentifier NOT NULL,
        [Name] nvarchar(100) NOT NULL,
        [CreatedByUserId] uniqueidentifier NOT NULL,
        [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_GroceryLists_CreatedAt] DEFAULT SYSUTCDATETIME(),
        [ArchivedAt] datetime2(0) NULL,
        CONSTRAINT [PK_GroceryLists] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_GroceryLists_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE
    );
END
GO
