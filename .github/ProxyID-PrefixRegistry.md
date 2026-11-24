# Proxy-ID Prefix Registry: SOS_FAMILY

> **Authoritative.** Every Proxy-ID prefix used in `SOS_FAMILY` is registered here before it is seeded or used. Agents read this file before creating an entity type or a Proxy-enabled table.

## Format

```
{Prefix}:{PartKey}:{GUID}
```

| Segment | Type | Length | Example |
|---|---|---|---|
| `Prefix` | Upper-case letters and digits | 4 | `PAIT` |
| `PartKey` | Hex of the creation year and month | 5 | `31773` (2026-11) |
| `GUID` | `NEWID()` as text | 36 | `E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8` |

## Prefix rules

1. Exactly four characters, `A`–`Z` and `0`–`9`.
2. Unique across the whole database. Check this file first.
3. Abbreviate the entity, not the schema: a reader should guess the entity from the prefix.
4. Start with the schema's two letters (table below). Strongly recommended.
5. Immutable once seeded or used in any environment: it is part of every proxy ever issued.

| Schema | Prefix start | Domain |
|---|---|---|
| `core` | `CO**` | Households, members, invites, stores |
| `family` | `FA**` | Family data-sharing app |
| `PAN` | `PA**` | Food storage app (pantry) |
| `auth` | `AU**` | Sign-in |

## Registered prefixes

### core

| Prefix | TypeId | TypeName | Type table | Description | Registered |
|---|---|---|---|---|---|
| *(none yet; baseline tables use GUID keys)* | | | | | |

### family

| Prefix | TypeId | TypeName | Type table | Description | Registered |
|---|---|---|---|---|---|
| *(none yet)* | | | | | |

### PAN

| Prefix | TypeId | TypeName | Type table | Description | Registered |
|---|---|---|---|---|---|
| *(none yet; reserved namespace `PA**`)* | | | | | |

## Adding a prefix

1. **Claim it here** in the right section, before writing SQL. Make sure the four characters appear nowhere else in this file.
2. **Type table** (when the entity has subtypes): `[Prefix] VARCHAR(4) NOT NULL` with `CONSTRAINT [UQ_<Types>_Prefix] UNIQUE ([Prefix])`. A table without subtypes uses one fixed prefix (TypeId `—`, Type table *(none)*).
3. **Seed** the type rows with `MERGE` in a data migration, with explicit IDs.
4. **Register in `MAC.vwTableTypesAndPrefixes`**: add a `UNION` block for the type table.
5. **Branch in `MAC.fxGeneratePrefixParts`**: `ELSE IF (@TypeName = '<Entity>')`.
6. **Entity table**: `[Proxy] VARCHAR(100) NOT NULL` (`UQ_<Table>_Proxy`) and `[PartKey] VARCHAR(6) NOT NULL`.
7. **Generate** in the insert path:

   ```sql
   DECLARE @Proxy VARCHAR(100) = [MAC].[fxGeneratePrefixProxy]('<Entity>', @TypeId) + CAST(NEWID() AS NVARCHAR(36));
   DECLARE @PartKey VARCHAR(6) = SUBSTRING(@Proxy, CHARINDEX(':', @Proxy) + 1,
       CHARINDEX(':', @Proxy, CHARINDEX(':', @Proxy) + 1) - CHARINDEX(':', @Proxy) - 1);
   ```

   When the API inserts rows with EF Core instead of a procedure, it builds the same string: the registered prefix, `fxGetPartKey()`'s value for the current month, and a new GUID.

## Infrastructure objects

Created by the first Proxy-enabled migration, in its own migration before the table:

| Object | Schema | Type | File | Purpose |
|---|---|---|---|---|
| `fxGetPartKey` | `UTL` | Scalar function | `Functions/UTL/fxGetPartKey.sql` | Hex year+month PartKey |
| `vwTableTypesAndPrefixes` | `MAC` | View | `Views/MAC/vwTableTypesAndPrefixes.sql` | Every prefix with its TypeId, table and TypeName |
| `fxGeneratePrefixParts` | `MAC` | Table-valued function | `Functions/MAC/fxGeneratePrefixParts.sql` | `(Prefix, PartKey)` for a TypeName and TypeId |
| `fxGeneratePrefixProxy` | `MAC` | Scalar function | `Functions/MAC/fxGeneratePrefixProxy.sql` | `Prefix:PartKey:` (the caller appends the GUID) |
| `fxGetPrefixTypeIdFromProxy` | `MAC` | Table-valued function | `Functions/MAC/fxGetPrefixTypeIdFromProxy.sql` | Splits a proxy and resolves its TypeId |

**Status:** not created yet.

`fxGetPartKey` algorithm: `YYYYMM` as an `INT` (202611), to `VARBINARY(4)`, to hex with `CONVERT(..., 1)` (`0x00031773`), then strip `0x000` (`31773`). Use `SYSUTCDATETIME()` so every server agrees.

## Column standards

| Column | Type | Null | Constraint | Notes |
|---|---|---|---|---|
| `Prefix` (type tables) | `VARCHAR(4)` | NOT NULL | `UQ_<Types>_Prefix` | Source of the prefix |
| `Proxy` (entity tables) | `VARCHAR(100)` | NOT NULL | `UQ_<Table>_Proxy` | The full string |
| `PartKey` (entity tables) | `VARCHAR(6)` | NOT NULL | | Middle segment, for indexed filtering |

## Anti-patterns

- `Proxy` or `PartKey` on a type table.
- `PartKey` as `INT` (it is hex text).
- Hard-coded prefixes in procedures (call `MAC.fxGeneratePrefixProxy`).
- A prefix reused, unregistered, or changed after seeding.
- Looking up by `Proxy` alone without validating the type.
