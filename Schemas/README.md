# Schemas

One folder per schema with a `schema.sql` that creates it if missing.

## Registry

New schemas are three upper-case letters and are added here before any migration uses them.

| Schema | Type | Purpose | Key tables | Created by |
|---|---|---|---|---|
| `dbo` | Infrastructure | Migration history only | `SchemaVersion` | `00000000_0000_CreateSchemaVersionTable` |
| `auth` | Baseline | Sign-in: ASP.NET Core Identity and refresh tokens | `AspNetUsers`, `RefreshTokens` | `00000000_0001_Baseline_AuthIdentity` |
| `core` | Baseline | Tenancy shared by every app | `Households`, `Members`, `Invites`, `Stores` | `00000000_0002_Baseline_CoreHouseholds` |
| `security` | Baseline | Row-level security | `fn_HouseholdAccess`, `HouseholdIsolation` | `00000000_0003_Baseline_CoreRowLevelSecurity` |
| `family` | Baseline | Family data-sharing app | `GroceryLists`, `GroceryItems` | `00000000_0005_Baseline_FamilyGroceryLists` |
| `PAN` | Domain | Food storage app (pantry) | `Locations`, `Products`, `StockLevels`, `StockChanges` | `20261125_1902_CreatePAN_Schema` |
| `MAC` | Infrastructure | Proxy-ID catalog | `vwTableTypesAndPrefixes` | `20261125_1901_CreateMAC_Schema` |
| `UTL` | Infrastructure | Scalar utilities | `fxGetPartKey` | `20261125_1900_CreateUTL_Schema` |

## Template

```sql
/*******************************************************************************
 * Object Type: Schema
 * Name: PAN
 * Description: The food storage app's tables.
 * Author:
 * Created: YYYY-MM-DD
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'PAN')
BEGIN
    EXEC(N'CREATE SCHEMA [PAN]');
END
GO
```

A new app schema also needs `GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[PAN] TO [sosafam_api];` in its migration and in `Grants/`.
