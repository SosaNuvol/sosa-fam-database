-- Grocery lists for the family app, with items tagged by store so the shopping can be
-- split between people going to different stores. The food storage app adds items too
-- (Source = 'LowStock', ProductId = its pantry product).

-- Stores are shared by every app in the household (pantry products can name a default store).
CREATE TABLE [core].[Stores] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_Stores_Id] DEFAULT NEWSEQUENTIALID(),
    [HouseholdId] uniqueidentifier NOT NULL,
    [Name] nvarchar(60) NOT NULL,
    [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_Stores_CreatedAt] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_Stores] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Stores_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE
);
GO

CREATE UNIQUE INDEX [UX_Stores_HouseholdId_Name] ON [core].[Stores] ([HouseholdId], [Name]);
GO

IF SCHEMA_ID(N'family') IS NULL EXEC(N'CREATE SCHEMA [family];');
GO

CREATE TABLE [family].[GroceryLists] (
    [Id] uniqueidentifier NOT NULL CONSTRAINT [DF_GroceryLists_Id] DEFAULT NEWSEQUENTIALID(),
    [HouseholdId] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [CreatedByUserId] uniqueidentifier NOT NULL,
    [CreatedAt] datetime2(0) NOT NULL CONSTRAINT [DF_GroceryLists_CreatedAt] DEFAULT SYSUTCDATETIME(),
    [ArchivedAt] datetime2(0) NULL,
    CONSTRAINT [PK_GroceryLists] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_GroceryLists_Households_HouseholdId] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_GroceryLists_HouseholdId] ON [family].[GroceryLists] ([HouseholdId]);
GO

-- HouseholdId and StoreId use NO ACTION (SQL Server allows only one cascade path to a table);
-- items are removed through their list, and the API clears StoreId before deleting a store.
-- ProductId is a loose reference to the food storage app's products (no foreign key).
CREATE TABLE [family].[GroceryItems] (
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
GO

CREATE INDEX [IX_GroceryItems_ListId] ON [family].[GroceryItems] ([ListId]);
CREATE INDEX [IX_GroceryItems_HouseholdId] ON [family].[GroceryItems] ([HouseholdId]);
CREATE INDEX [IX_GroceryItems_StoreId] ON [family].[GroceryItems] ([StoreId]);
GO

ALTER SECURITY POLICY [security].[HouseholdIsolation]
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Stores],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Stores] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Stores] AFTER UPDATE,
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryLists],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryLists] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryLists] AFTER UPDATE,
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryItems],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryItems] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryItems] AFTER UPDATE;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[family] TO [sosafam_api];
GO
