/*******************************************************************************
 * Object Type: Table
 * Schema: family
 * Name: GroceryItems
 * Description: Items on a grocery list, optionally tagged by store; checked off live. The food storage app adds LowStock items with a loose ProductId.
 * Dependencies: See the foreign keys below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0005_Baseline_FamilyGroceryLists)
 * Modified: 2026-11-24 - Current-state file added. Baseline table: predates the
 *           naming and audit-column rules (see DATABASE_CONSTITUTION.md, Baseline exceptions).
 ******************************************************************************/

IF OBJECT_ID(N'[family].[GroceryItems]', N'U') IS NULL
BEGIN
    CREATE TABLE [family].[GroceryItems]
    (
        [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_GroceryItems_Id] DEFAULT NEWSEQUENTIALID(),
        [HouseholdId] uniqueidentifier NOT NULL,
        [ListId] uniqueidentifier NOT NULL,
        [Name] nvarchar(120) NOT NULL,
        [Quantity] decimal(10, 2) NULL,
        [Unit] nvarchar(20) NULL,
        [Note] nvarchar(200) NULL,
        [StoreId] uniqueidentifier NULL,
        [Source] nvarchar(10) NOT NULL CONSTRAINT [DF_GroceryItems_Source] DEFAULT N'Manual',
        [ProductId] uniqueidentifier NULL,
        [IsChecked] bit NOT NULL CONSTRAINT [DF_GroceryItems_IsChecked] DEFAULT 0,
        [CheckedByUserId] uniqueidentifier NULL,
        [CheckedAt] datetime2(0) NULL,
        [AddedByUserId] uniqueidentifier NOT NULL,
        [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_GroceryItems_CreatedAt] DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [PK_GroceryItems] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_GroceryItems_GroceryLists_ListId] FOREIGN KEY ([ListId]) REFERENCES [family].[GroceryLists] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_GroceryItems_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]),
        CONSTRAINT [FK_GroceryItems_Stores_StoreId] FOREIGN KEY ([StoreId]) REFERENCES [core].[Stores] ([Id]),
        CONSTRAINT [CK_GroceryItems_Source] CHECK ([Source] IN (N'Manual', N'LowStock')),
        CONSTRAINT [CK_GroceryItems_Quantity] CHECK ([Quantity] IS NULL OR [Quantity] > 0)
    );
END
GO
