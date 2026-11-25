/*******************************************************************************
 * Object Type: Schema
 * Name: MAC
 * Description: Proxy-ID catalog: prefixes and the functions that build and read Proxy-IDs.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25 (migration 20261125_1901_CreateMAC_Schema)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'MAC')
BEGIN
    EXEC(N'CREATE SCHEMA [MAC]');
END
GO
