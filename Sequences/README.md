# Sequences

Sequences, one per file: `Sequences/<schema>/seq_<Name>.sql`. None exist yet; prefer `IDENTITY` unless several tables share a number range or the number must be known before the insert.

## Template

```sql
/*******************************************************************************
 * Object Type: Sequence
 * Schema: <schema>
 * Name: seq_<Name>
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE [name] = N'seq_<Name>' AND [schema_id] = SCHEMA_ID(N'<schema>'))
    CREATE SEQUENCE [<schema>].[seq_<Name>] AS BIGINT START WITH 1 INCREMENT BY 1 NO CYCLE CACHE 50;
GO
```

Never drop and recreate a sequence that is in use: it restarts the numbers.
