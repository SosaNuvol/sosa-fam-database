/*******************************************************************************
 * Object Type: Schema
 * Name: core
 * Description: Tenancy shared by every app: households, members, invites, stores.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0002_Baseline_CoreHouseholds)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'core')
BEGIN
    EXEC(N'CREATE SCHEMA [core]');
END
GO
