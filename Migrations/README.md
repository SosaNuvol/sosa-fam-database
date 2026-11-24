# Migrations

The history of the database, oldest first. Each file is one logical change and is the only thing that deploys.

- **Immutable:** never edit a migration that has run anywhere. Fix forward.
- **Ordered:** applied in file-name order. Name: `YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql`, UTC.
- **Idempotent:** every statement guarded; the file skips itself if `dbo.SchemaVersion` has it.
- **Atomic:** one transaction, `XACT_ABORT ON`, `TRY...CATCH`.
- **Recorded:** the last statement inserts its row in `dbo.SchemaVersion`.

Start from [`_TEMPLATE_Migration.sql`](_TEMPLATE_Migration.sql) (the runner ignores files starting with `_`). Copy it, fill in every placeholder, keep the structure.

## Baseline

| File | Notes |
|---|---|
| `00000000_0000_CreateSchemaVersionTable` | Creates `dbo.SchemaVersion`. On a database the old DbUp runner built, records `0001` to `0005` as applied from DbUp's `dbo.SchemaVersions`. |
| `00000000_0001` to `00000000_0005` | The original scripts `0001_auth_identity` to `0005_grocery_lists`, renamed only. Their SQL is unchanged because it already ran on `SOS_FAMILY`; the runner runs each in a transaction and records it. |

## Running them

The runner (`src/SosaFam.Database`) embeds this folder. On Windows use the wrappers in `Scripts/deploy/` ([runbook](../docs/Deploying-Migrations.md)). Directly:

```bash
dotnet run --project src/SosaFam.Database -- --what-if "<connection string>"
dotnet run --project src/SosaFam.Database -- "<connection string>"
dotnet run --project src/SosaFam.Database -- --filter 20261125_1400_CreatePAN_PantryItems "<connection string>"
```

## When one fails

It rolls back and isn't recorded. Fix it (it hasn't run anywhere yet, so editing is allowed), then rerun. If a failed migration was already merged and ran successfully somewhere else, don't edit it: write a new one.

Two people picked the same minute? Rename the later file and its `@MigrationName` before either merges.
