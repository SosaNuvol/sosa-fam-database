/*******************************************************************************
 * Object Type: Schema
 * Name: UTL
 * Description: Scalar utilities shared by every schema (fxGetPartKey).
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25 (migration 20261125_1900_CreateUTL_Schema)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'UTL')
BEGIN
    EXEC(N'CREATE SCHEMA [UTL]');
END
GO
