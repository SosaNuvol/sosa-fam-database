# Repository structure

```
sosa-fam-database/
├── Migrations/                 History: YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql (flat, UTC, immutable)
│   └── _TEMPLATE_Migration.sql
├── Schemas/<schema>/schema.sql Current state, one file per object, in deployment order:
├── Types/<schema>/
├── Tables/<schema>/
├── Indexes/<schema>/
├── Constraints/<schema>/
├── Sequences/<schema>/
├── Views/<schema>/
├── Functions/<schema>/
├── SecurityPolicies/<schema>/  (Sosa Fam: row-level security policies)
├── Procedures/<schema>/
├── Triggers/<schema>/
├── Grants/<schema>/
├── Data/<schema>/
├── Scripts/
│   ├── deploy/                 One Deploy_<Change>.ps1 per change, plus the shared module
│   ├── Rollback/               Rollback scripts too long for a migration's rollback block
│   └── Tests/<ObjectType>/<schema>/<Object>_Tests.sql
├── src/SosaFam.Database/       The migration runner (.NET 8)
├── docs/                       Runbooks and design notes
└── .github/                    Agent rules, Proxy-ID registry, prompts, PR template
```

## Today's objects

| Folder | Files |
|---|---|
| `Schemas/` | `auth`, `core`, `family`, `security` |
| `Tables/dbo/` | `SchemaVersion` |
| `Tables/auth/` | `AspNetUsers`, `AspNetUserClaims`, `AspNetUserLogins`, `AspNetUserTokens`, `RefreshTokens` |
| `Tables/core/` | `Households`, `Members`, `Invites`, `Stores` |
| `Tables/family/` | `GroceryLists`, `GroceryItems` |
| `Indexes/` | one `<Table>_Indexes.sql` per table with secondary indexes |
| `Functions/security/` | `fn_HouseholdAccess`, `fn_MemberAccess`, `fn_HouseholdRowAccess` |
| `SecurityPolicies/security/` | `HouseholdIsolation` |
| `Grants/dbo/` | `grant_sosafam_api_permissions` |
| `Scripts/Tests/Policies/security/` | `HouseholdIsolation_Tests` |

Running the current-state files in deployment order on an empty database produces the same schema as the migrations (checked column by column, including every index, constraint, predicate and grant).

## Migrations vs current state

- **Migrations** say how the database got here. They are what deploys.
- **Current-state files** say what is there now. They are for reading, reviewing and rebuilding, and are updated in the same PR as the migration that changes the object.

## Deployment order

1. Schemas 2. Types 3. Tables 4. Indexes 5. Constraints 6. Sequences 7. Views 8. Functions 9. Security policies 10. Procedures 11. Triggers 12. Grants 13. Data

Within `Tables/`, a table comes after the tables its foreign keys point at (`auth` → `core` → app schemas).
