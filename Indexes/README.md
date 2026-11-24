# Indexes

Secondary indexes, one file per table: `Indexes/<schema>/<Table>_Indexes.sql`, with every non-primary-key index on that table.

## Template

```sql
/*******************************************************************************
 * Object Type: Index
 * Schema: <schema>
 * Name: <Table>_Indexes
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_<Table>_<Columns>' AND [object_id] = OBJECT_ID(N'[<schema>].[<Table>]'))
    CREATE NONCLUSTERED INDEX [IX_<Table>_<Columns>]
        ON [<schema>].[<Table>] ([Column1] ASC, [Column2] ASC)
        INCLUDE ([Column3])
        WHERE [IsDeleted] = 0;
GO
```

## Rules

1. Name `IX_<Table>_<Columns>` (`UQ_` for unique ones).
2. Every foreign key column has an index; `HouseholdId` usually leads, because row-level security filters on it.
3. Most selective column first; `INCLUDE` to cover the API's queries; filtered indexes for active rows.
4. Filtered and unique indexes need `ANSI_NULLS` and `QUOTED_IDENTIFIER` ON.
5. Don't over-index: each index slows writes. Write down why each one exists.
