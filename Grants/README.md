# Grants

Permissions, by schema: `Grants/<schema>/grant_<role>_permissions.sql`.

Today: [`dbo/grant_sosafam_api_permissions.sql`](dbo/grant_sosafam_api_permissions.sql), the API's role, with data access on `auth`, `core` and `family`.

## Template

```sql
/*******************************************************************************
 * Object Type: Grant Script
 * Schema: <schema>
 * Name: grant_<role>_permissions
 * Description:
 * Dependencies:
 * Author:
 * Created: YYYY-MM-DD
 * Modified: YYYY-MM-DD - what changed
 ******************************************************************************/

IF DATABASE_PRINCIPAL_ID(N'<role>') IS NULL
    CREATE ROLE [<role>];
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[<schema>] TO [<role>];
GO
```

## Rules

1. Grant to roles, never to individual users.
2. Least privilege: schema-level data access, `EXECUTE` only where procedures are used, nothing on `dbo`, no `CONTROL`, no DDL.
3. Logins and users are created per environment by an admin and never stored here (see the runbook).
4. Every grant is in a migration and reflected here.
