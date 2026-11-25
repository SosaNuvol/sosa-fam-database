/*******************************************************************************
 * Object Type: Security Policy (row-level security)
 * Schema: security
 * Name: HouseholdIsolation
 * Description: Keeps households apart inside the database. Filter predicates hide other
 *              households' rows; block predicates stop writes into another household.
 *              With no session context, every protected table looks empty.
 * Dependencies: security.fn_HouseholdAccess, security.fn_MemberAccess,
 *               security.fn_HouseholdRowAccess; every table listed below.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (baseline migrations 00000000_0003 and 00000000_0005)
 * Modified: 2026-11-24 - Current-state file added (0003 plus the tables 0005 added).
 *
 * Every new household-owned table must be added here AND in its migration with
 * ALTER SECURITY POLICY ... ADD FILTER / BLOCK PREDICATE (see DATABASE_CONSTITUTION.md).
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.security_policies WHERE [object_id] = OBJECT_ID(N'[security].[HouseholdIsolation]'))
BEGIN
    EXEC(N'
CREATE SECURITY POLICY [security].[HouseholdIsolation]
    -- core.Households: readable by members, changeable only from inside that household.
    ADD FILTER PREDICATE [security].[fn_HouseholdRowAccess]([Id]) ON [core].[Households],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] AFTER UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] BEFORE UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([Id]) ON [core].[Households] BEFORE DELETE,

    -- core.Members: see your own memberships everywhere; change only inside the current household.
    ADD FILTER PREDICATE [security].[fn_MemberAccess]([HouseholdId], [UserId]) ON [core].[Members],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] AFTER UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] BEFORE UPDATE,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Members] BEFORE DELETE,

    -- core.Invites: current household only.
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Invites],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Invites] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Invites] AFTER UPDATE,

    -- core.Stores, family.GroceryLists, family.GroceryItems: current household only.
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Stores],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Stores] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [core].[Stores] AFTER UPDATE,
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryLists],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryLists] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryLists] AFTER UPDATE,
    ADD FILTER PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryItems],
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryItems] AFTER INSERT,
    ADD BLOCK PREDICATE [security].[fn_HouseholdAccess]([HouseholdId]) ON [family].[GroceryItems] AFTER UPDATE
WITH (STATE = ON);');
END
GO
