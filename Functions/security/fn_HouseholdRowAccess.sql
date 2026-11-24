/*******************************************************************************
 * Object Type: Inline Table-Valued Function (row-level security predicate)
 * Schema: security
 * Name: fn_HouseholdRowAccess
 * Description: Row-level security predicate for core.Households: the current household, plus every household the signed-in user belongs to.
 * Parameters: @Id uniqueidentifier
 * Returns: One row ([Allowed] = 1) when access is allowed, no rows otherwise.
 * Dependencies: SESSION_CONTEXT keys UserId, HouseholdId, IsSystem (set read-only by the API); core.Members
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0003_Baseline_CoreRowLevelSecurity)
 * Modified: 2026-11-24 - Current-state file added. Baseline name keeps the fn_ prefix
 *           (new functions use fx; see DATABASE_CONSTITUTION.md, Baseline exceptions).
 *
 * Note: security.HouseholdIsolation is schema-bound to this function, so it cannot be
 * dropped or altered while the policy uses it. Change it through a migration that
 * removes the predicates from the policy first, then adds them back.
 ******************************************************************************/

IF OBJECT_ID(N'[security].[fn_HouseholdRowAccess]', N'IF') IS NULL
    EXEC(N'CREATE FUNCTION [security].[fn_HouseholdRowAccess](@Id uniqueidentifier)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS [Allowed]
    WHERE CAST(SESSION_CONTEXT(N''IsSystem'') AS bit) = 1
       OR @Id = CAST(SESSION_CONTEXT(N''HouseholdId'') AS uniqueidentifier)
       OR EXISTS (
            SELECT 1 FROM [core].[Members] AS m
            WHERE m.[HouseholdId] = @Id
              AND m.[UserId] = CAST(SESSION_CONTEXT(N''UserId'') AS uniqueidentifier));');
GO
