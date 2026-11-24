/*******************************************************************************
 * Object Type: Schema
 * Name: family
 * Description: The family data-sharing app: grocery lists and items.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0005_Baseline_FamilyGroceryLists)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'family')
BEGIN
    EXEC(N'CREATE SCHEMA [family]');
END
GO
