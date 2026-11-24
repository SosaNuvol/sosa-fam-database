Closes #

## What changes

## Migrations

| Migration | What it does |
|---|---|
| | |

## Households

- [ ] No household-owned tables are added or changed, or:
- [ ] `HouseholdId`, policy predicates, `SecurityPolicies/security/HouseholdIsolation.sql` and the isolation test are updated

## Impact

What the API or the apps will notice, locks on big tables, the API release that must follow.

## Rollback

## Checklist

- [ ] Follows `Migrations/_TEMPLATE_Migration.sql`; name is UTC `YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>`
- [ ] No existing migration edited
- [ ] Current-state files updated
- [ ] `Scripts/deploy/Deploy_<Change>.ps1` with prerequisites and post-checks
- [ ] Ran twice on a scratch database (second run skipped); `Scripts/Tests/` passes
- [ ] No credentials, server names or personal data
