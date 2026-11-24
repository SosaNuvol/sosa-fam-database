/*******************************************************************************
 * Object Type: Schema
 * Name: security
 * Description: Row-level security predicate functions and the HouseholdIsolation policy.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0003_Baseline_CoreRowLevelSecurity)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'security')
BEGIN
    EXEC(N'CREATE SCHEMA [security]');
END
GO
