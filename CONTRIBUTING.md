# Contributing

## The flow

1. **Issue.** Every change starts with a GitHub issue in this repository (project rule for every Sosa Fam repository).
2. **Branch** from `main`: `<area>/<short-name>` (for example `pantry/items-table`).
3. **Migration + current-state files + deploy wrapper**, following [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md).
4. **Test** on a scratch database (below).
5. **Pull request** that closes the issue (`Closes #<n>`), using the PR template.
6. **Review**, then **Dev** deploy with the wrapper, then the API change is tested against Dev.
7. **Merge**, then **Prod** deploy from `main` ([docs/Deploying-Migrations.md](docs/Deploying-Migrations.md)).

## Commit messages

```
[Feature]: Add pantry items table

- Migration: 20261125_1400_CreatePAN_PantryItems
- Affects: PAN.PantryItems, security.HouseholdIsolation, sosafam_api
```

Types: `Feature`, `Fix`, `Refactor`, `Docs`, `Chore`, `Data`. One logical change per commit where you can.

## Before opening a PR

- [ ] Migration name is `YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql` in UTC, and `@MigrationName` matches it.
- [ ] Migration follows the template: header (with Dependencies, Rollback, Expected impact), SET options, transaction, skip check, guarded statements, `dbo.SchemaVersion` insert, rollback block.
- [ ] No existing migration was edited.
- [ ] Every new or changed object has its current-state file, with the header.
- [ ] Names follow the constitution (`XxxID` primary keys, `XxxId` foreign keys, `PK_`/`FK_`/`UQ_`/`CK_`/`DF_`/`IX_`, `vw`/`fx`/`sp` prefixes).
- [ ] New tables have the audit tail and an index on every foreign key.
- [ ] Household data: `HouseholdId`, policy predicates, the policy file and the isolation test are updated.
- [ ] Rows the API exposes have a registered Proxy-ID prefix.
- [ ] `Scripts/deploy/Deploy_<Change>.ps1` exists, with prerequisites and post-checks.
- [ ] Ran on a scratch database twice (the second run skipped) and `Scripts/Tests/` passes.
- [ ] No credentials, server names or personal data.

## Testing on a scratch database

```bash
CS="Server=localhost,1433;Database=Scratch;User Id=sa;Password=<dev password>;TrustServerCertificate=True"
dotnet run --project src/SosaFam.Database -- --ensure-database "$CS"
dotnet run --project src/SosaFam.Database -- "$CS"        # must say Nothing to apply
sqlcmd -S localhost,1433 -U sa -P '<dev password>' -d Scratch -b -i Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql
```

Try the migration's rollback block on the scratch database too, then drop it.

## Reviews

Reviewers check the PR checklist, read the migration as if it will run on Prod tomorrow, and confirm the household isolation for any new table. Ask questions in the PR.
