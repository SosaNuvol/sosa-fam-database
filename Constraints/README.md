# Constraints

Constraints added after a table exists, one per file: `Constraints/<schema>/<ConstraintName>.sql`. Constraints created with the table stay inline in `Tables/`.

## Template

```sql
/*******************************************************************************
 * Object Type: Constraint
 * Schema: <schema>
 * Name: <ConstraintName>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE [name] = N'FK_<Child>_<Parent>')
    ALTER TABLE [<schema>].[<Child>]
        ADD CONSTRAINT [FK_<Child>_<Parent>] FOREIGN KEY ([<Parent>Id])
        REFERENCES [<schema>].[<Parents>] ([<Parent>ID]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_<Table>_<Column>')
    ALTER TABLE [<schema>].[<Table>] ADD CONSTRAINT [CK_<Table>_<Column>] CHECK ([<Column>] >= 0);
GO
```

## Rules

1. Names: `FK_<Child>_<Parent>`, `CK_<Table>_<Column>`, `UQ_<Table>_<Columns>`, `DF_<Table>_<Column>`.
2. Say why the rule exists in the header.
3. Only one cascade path may reach a table: use `NO ACTION` where a second one would form.
4. Adding a check or foreign key to a table with rows validates every row: check for violations first.
