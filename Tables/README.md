# Tables

Table definitions, one per file: `Tables/<schema>/<Table>.sql`.

The file is the table as it is now, after every migration. When a migration changes the table, update this file in the same PR.

## Template

```sql
/*******************************************************************************
 * Object Type: Table
 * Schema: <schema>
 * Name: PantryItems
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

IF OBJECT_ID(N'[<schema>].[<Table>]', N'U') IS NULL
BEGIN
    CREATE TABLE [<schema>].[<Table>]
    (
        [<Singular>ID] INT IDENTITY(1,1) NOT NULL,
        [HouseholdId]  UNIQUEIDENTIFIER  NOT NULL,
        -- other foreign keys: [<Singular>Id]
        -- [Proxy] VARCHAR(100) NOT NULL, [PartKey] VARCHAR(6) NOT NULL   if the API exposes rows
        -- business columns, each NULL or NOT NULL
        [IsActive]     BIT               NOT NULL CONSTRAINT [DF_<Table>_IsActive]    DEFAULT (1),
        [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_<Table>_IsDeleted]   DEFAULT (0),
        [ModifiedDate] DATETIMEOFFSET(7) NULL,
        [ModifiedById] UNIQUEIDENTIFIER  NULL,
        [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_<Table>_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
        [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_<Table>_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_<Table>] PRIMARY KEY CLUSTERED ([<Singular>ID] ASC),
        CONSTRAINT [FK_<Table>_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE
    );
END
GO
```

## Rules

1. One table per file; plural PascalCase name.
2. Column order: primary key, foreign keys, business columns, audit tail.
3. Named constraints (`PK_`, `FK_<Child>_<Parent>`, `UQ_`, `CK_`, `DF_`); secondary indexes go in `Indexes/`.
4. Household data: `HouseholdId` and the security policy (see `SecurityPolicies/`).
5. Baseline tables (`auth`, `core`, `family`) predate these rules; see the constitution's *Baseline exceptions*.
