/*******************************************************************************
 * Object Type: Schema
 * Name: PAN
 * Description: The food storage app (pantry): locations, products, stock levels and their history.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25 (migration 20261125_1902_CreatePAN_Schema)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'PAN')
BEGIN
    EXEC(N'CREATE SCHEMA [PAN]');
END
GO
