# Security policies

Row-level security policies, by schema. Today there is one: [`security/HouseholdIsolation.sql`](security/HouseholdIsolation.sql), which keeps households apart.

## How it works

The API sets three read-only `SESSION_CONTEXT` keys on every connection: `UserId`, `HouseholdId` and `IsSystem`. The policy's predicate functions (`Functions/security/`) compare each row's `HouseholdId` with them:

- **Filter predicates** hide other households' rows from every `SELECT`, `UPDATE` and `DELETE`.
- **Block predicates** reject an `INSERT` or `UPDATE` that would write a row into another household.
- With no session context, protected tables look empty and reject writes.

## Adding a table

In the table's migration (inside the transaction, under a guard):

```sql
IF NOT EXISTS (SELECT 1 FROM sys.security_predicates WHERE [target_object_id] = OBJECT_ID(N'[PAN].[PantryItems]'))
    EXEC(N'ALTER SECURITY POLICY [security].[HouseholdIsolation]
        ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems],
        ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems] AFTER INSERT,
        ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [PAN].[PantryItems] AFTER UPDATE;');
```

Then add the same lines to `HouseholdIsolation.sql` and a check to `Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql`.

The policy is schema-bound to its functions: to change a function, drop its predicates, alter it, and add them back, all in one migration.

Deployment order: after Functions, before Procedures.
