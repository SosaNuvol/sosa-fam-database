-- Database role for the API's login. The API needs data access only: no DDL, and no
-- permission to alter the security policy. See README for creating the login.

IF DATABASE_PRINCIPAL_ID(N'sosafam_api') IS NULL
    CREATE ROLE [sosafam_api];
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[auth] TO [sosafam_api];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[core] TO [sosafam_api];
GO
