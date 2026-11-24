# sosa-fam-database

SQL Server schema for every Sosa Fam app: sign-in, households (the tenants), members, invites, and each app's own tables.

## How it works

- `src/SosaFam.Database/Scripts/` holds numbered scripts. Each runs exactly once, in order, and the list of applied scripts is kept in `dbo.SchemaVersions` (DbUp).
- **Never edit a script that has already run anywhere.** Add a new, higher-numbered script instead.
- Row-level security keeps households apart inside the database, even if the API has a bug. See `0003_core_row_level_security.sql` for how it works and the pattern for new tables.

| Script | What it adds |
| --- | --- |
| 0001_auth_identity | ASP.NET Core Identity users, external logins, refresh tokens (schema `auth`) |
| 0002_core_households | Households, Members (roles Owner/Adult/Member/Child), Invites (schema `core`) |
| 0003_core_row_level_security | Security policy that filters and blocks rows by household |
| 0004_app_role | `sosafam_api` role with data-only access for the API's login |
| 0005_grocery_lists | Stores (shared by all apps), grocery lists and items tagged by store (schema `family`) |

## Apply the scripts

Requires the .NET 8 SDK and SQL Server 2016 or later (row-level security).

```bash
dotnet run --project src/SosaFam.Database -- "Server=<server>;Database=SosaFam;Integrated Security=True;TrustServerCertificate=True"
```

Add `--ensure-database` to create the database if it does not exist (development only). You can also set the connection string in `SOSAFAM_DB_CONNECTION` and run with no arguments.

Run migrations with an admin login. The API should use its own login that is only a member of `sosafam_api`:

```sql
CREATE LOGIN sosafam_api_login WITH PASSWORD = '<strong password>';
USE SosaFam;
CREATE USER sosafam_api_user FOR LOGIN sosafam_api_login;
ALTER ROLE sosafam_api ADD MEMBER sosafam_api_user;
```

## Test the tenant isolation

`tests/rls_isolation_test.sql` creates two test households, checks that neither can see or change the other's rows, then removes them. Run it on a development database:

```bash
sqlcmd -S <server> -d SosaFam -i tests/rls_isolation_test.sql -b
```

It prints `PASS: row-level security keeps households apart.` or fails with the check that broke.

## Local SQL Server for development

```bash
docker run -d --name sosafam-sql -e ACCEPT_EULA=Y -e 'MSSQL_SA_PASSWORD=<dev password>' -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
```

## Adding tables for an app

1. Add a new script, for example `0010_pantry_items.sql`. Use a schema per app (`family`, `pantry`).
2. Give every tenant-owned table a `HouseholdId uniqueidentifier NOT NULL` with a foreign key to `core.Households` (`ON DELETE CASCADE`).
3. In the same script, add the table to `security.HouseholdIsolation` with the filter and block predicates shown in `0003`, and grant the `sosafam_api` role access to the new schema.
4. Extend `tests/rls_isolation_test.sql` to cover the new table.
