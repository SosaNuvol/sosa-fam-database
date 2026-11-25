/*******************************************************************************
 * Object Type: Schema
 * Name: auth
 * Description: Sign-in: ASP.NET Core Identity users, logins, tokens and refresh tokens.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0001_Baseline_AuthIdentity)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'auth')
BEGIN
    EXEC(N'CREATE SCHEMA [auth]');
END
GO
