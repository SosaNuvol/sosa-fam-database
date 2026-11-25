/*******************************************************************************
 * Object Type: Inline Table-Valued Function (row-level security predicate)
 * Schema: security
 * Name: fn_MemberAccess
 * Description: Row-level security predicate for core.Members: the current household's members, plus the signed-in user's own memberships in any household.
 * Parameters: @HouseholdId uniqueidentifier, @UserId uniqueidentifier
 * Returns: One row ([Allowed] = 1) when access is allowed, no rows otherwise.
 * Dependencies: SESSION_CONTEXT keys UserId, HouseholdId, IsSystem (set read-only by the API)
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migration 00000000_0003_Baseline_CoreRowLevelSecurity)
 * Modified: 2026-11-24 - Current-state file added. Baseline name keeps the fn_ prefix
 *           (new functions use fx; see DATABASE_CONSTITUTION.md, Baseline exceptions).
 *
 * Note: security.HouseholdIsolation is schema-bound to this function, so it cannot be
 * dropped or altered while the policy uses it. Change it through a migration that
 * removes the predicates from the policy first, then adds them back.
 ******************************************************************************/

IF OBJECT_ID(N'[security].[fn_MemberAccess]', N'IF') IS NULL
    EXEC(N'CREATE FUNCTION [security].[fn_MemberAccess](@HouseholdId uniqueidentifier, @UserId uniqueidentifier)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS [Allowed]
    WHERE CAST(SESSION_CONTEXT(N''IsSystem'') AS bit) = 1
       OR @HouseholdId = CAST(SESSION_CONTEXT(N''HouseholdId'') AS uniqueidentifier)
       OR @UserId = CAST(SESSION_CONTEXT(N''UserId'') AS uniqueidentifier);');
GO
