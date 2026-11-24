# Types

User-defined types, one per file: `Types/<schema>/uddt_<Name>.sql` (alias types) or `Types/<schema>/udtt<Name>.sql` (table types).

## Template (table type)

```sql
/*******************************************************************************
 * Object Type: User-Defined Type
 * Schema: <schema>
 * Name: udtt<Name>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 * Typical Usage: passed READONLY to [<schema>].[sp<Name>]
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.table_types WHERE [name] = N'udtt<Name>' AND [schema_id] = SCHEMA_ID(N'<schema>'))
    CREATE TYPE [<schema>].[udtt<Name>] AS TABLE
    (
        [Proxy] VARCHAR(100) NOT NULL PRIMARY KEY
    );
GO
```

## Rules

1. Types can't be altered. A changed type is a new type (or drop and recreate when nothing uses it).
2. No audit columns in table types.
3. Grant `EXECUTE ON TYPE::[<schema>].[udtt<Name>]` to `sosafam_api`.
