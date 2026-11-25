/*******************************************************************************
 * Object Type: Grant Script
 * Schema: dbo (database role), with grants on auth, core, family and PAN
 * Target: sosafam_api (role for the API's SQL login)
 * Description: Data access only: SELECT, INSERT, UPDATE, DELETE on the app schemas.
 *              No DDL, no access to dbo.SchemaVersion, no permission to alter the
 *              security policy. The login and user are created per environment and are
 *              never stored in this repository (see docs/Deploying-Migrations.md).
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migrations 00000000_0004 and 00000000_0005)
 * Modified: 2026-11-25 - PAN (migration 20261125_1902_CreatePAN_Schema)
 ******************************************************************************/

IF DATABASE_PRINCIPAL_ID(N'sosafam_api') IS NULL
    CREATE ROLE [sosafam_api];
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[auth] TO [sosafam_api];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[core] TO [sosafam_api];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[family] TO [sosafam_api];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[PAN] TO [sosafam_api];
GO
