-- Row-level security: the database itself keeps households apart.
--
-- The API sets these keys with sp_set_session_context (read-only) on every connection:
--   UserId      the signed-in user (uniqueidentifier)
--   HouseholdId the household the request is acting in (uniqueidentifier, optional)
--   IsSystem    1 only for the few API paths that must cross households
--               (creating a household, accepting an invite). Never set from user input.
--
-- With no session context at all, every protected table looks empty and rejects writes.
--
-- PATTERN FOR NEW TENANT TABLES (any app):
--   ALTER SECURITY POLICY [security].[HouseholdIsolation]
--     ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [<schema>].[<Table>],
--     ADD BLOCK  PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [<schema>].[<Table>] AFTER INSERT,
--     ADD BLOCK  PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [<schema>].[<Table>] AFTER UPDATE;

IF SCHEMA_ID(N'security') IS NULL EXEC(N'CREATE SCHEMA [security];');
GO

-- Rows of the current household (or system context).
CREATE FUNCTION [security].[fn_HouseholdAccess](@HouseholdId uniqueidentifier)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS [Allowed]
    WHERE CAST(SESSION_CONTEXT(N'IsSystem') AS bit) = 1
       OR @HouseholdId = CAST(SESSION_CONTEXT(N'HouseholdId') AS uniqueidentifier);
GO

-- Membership rows: the current household's members, plus the signed-in user's own
-- memberships in any household (so they can list and switch between their households).
CREATE FUNCTION [security].[fn_MemberAccess](@HouseholdId uniqueidentifier, @UserId uniqueidentifier)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS [Allowed]
    WHERE CAST(SESSION_CONTEXT(N'IsSystem') AS bit) = 1
       OR @HouseholdId = CAST(SESSION_CONTEXT(N'HouseholdId') AS uniqueidentifier)
       OR @UserId = CAST(SESSION_CONTEXT(N'UserId') AS uniqueidentifier);
GO

-- Household rows: the current household, plus every household the signed-in user belongs to.
CREATE FUNCTION [security].[fn_HouseholdRowAccess](@Id uniqueidentifier)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS [Allowed]
    WHERE CAST(SESSION_CONTEXT(N'IsSystem') AS bit) = 1
       OR @Id = CAST(SESSION_CONTEXT(N'HouseholdId') AS uniqueidentifier)
       OR EXISTS (
            SELECT 1 FROM [core].[Members] AS m
            WHERE m.[HouseholdId] = @Id
              AND m.[UserId] = CAST(SESSION_CONTEXT(N'UserId') AS uniqueidentifier));
GO

CREATE SECURITY POLICY [security].[HouseholdIsolation]
    -- Households: readable by members, changeable only from inside that household.
    ADD FILTER PREDICATE [security].[fn_HouseholdRowAccess]([Id]) ON [core].[Households],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] AFTER UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] BEFORE UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] BEFORE DELETE,

    -- Members: see your own memberships everywhere; change only inside the current household.
    ADD FILTER PREDICATE [security].[fn_MemberAccess]([HouseholdId], [UserId]) ON [core].[Members],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] AFTER UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] BEFORE UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] BEFORE DELETE,

    -- Invites: current household only.
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Invites],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Invites] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Invites] AFTER UPDATE
WITH (STATE = ON);
GO
