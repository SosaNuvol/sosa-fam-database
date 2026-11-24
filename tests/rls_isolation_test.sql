-- Row-level security smoke test. Run against a DEV database only: it creates and
-- then deletes test rows. Fails with an error if any household can see or change
-- another household's rows.
--   sqlcmd -S <server> -d <database> -i tests/rls_isolation_test.sql -b
SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;

DECLARE @u1 uniqueidentifier = NEWID(), @u2 uniqueidentifier = NEWID();
DECLARE @hA uniqueidentifier = NEWID(), @hB uniqueidentifier = NEWID();
DECLARE @n int;

INSERT INTO auth.AspNetUsers (Id, UserName, NormalizedUserName, EmailConfirmed, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount)
VALUES (@u1, CONCAT('rls-test-', @u1), UPPER(CONCAT('rls-test-', @u1)), 0, 0, 0, 0, 0),
       (@u2, CONCAT('rls-test-', @u2), UPPER(CONCAT('rls-test-', @u2)), 0, 0, 0, 0, 0);

-- Setup runs in system context.
EXEC sp_set_session_context N'IsSystem', 1;
INSERT INTO core.Households (Id, Name, CreatedByUserId) VALUES (@hA, N'RLS test A', @u1), (@hB, N'RLS test B', @u2);
INSERT INTO core.Members (HouseholdId, UserId, Role, DisplayName) VALUES (@hA, @u1, N'Owner', N'User 1'), (@hB, @u2, N'Owner', N'User 2');
INSERT INTO core.Invites (HouseholdId, CodeHash, Role, CreatedByUserId, ExpiresAt) VALUES (@hB, HASHBYTES('SHA2_256', CONCAT('code-', @hB)), N'Member', @u2, DATEADD(day, 7, SYSUTCDATETIME()));
EXEC sp_set_session_context N'IsSystem', NULL;

BEGIN TRY
    -- 1. No context: nothing is visible.
    SELECT @n = COUNT(*) FROM core.Households WHERE Id IN (@hA, @hB);
    IF @n <> 0 THROW 50001, 'FAIL: households visible with no session context', 1;
    SELECT @n = COUNT(*) FROM core.Members WHERE HouseholdId IN (@hA, @hB);
    IF @n <> 0 THROW 50002, 'FAIL: members visible with no session context', 1;

    -- 2. User 1 acting in household A.
    EXEC sp_set_session_context N'UserId', @u1;
    EXEC sp_set_session_context N'HouseholdId', @hA;

    SELECT @n = COUNT(*) FROM core.Households WHERE Id IN (@hA, @hB);
    IF @n <> 1 THROW 50003, 'FAIL: user 1 should see exactly household A', 1;
    SELECT @n = COUNT(*) FROM core.Members WHERE HouseholdId = @hB;
    IF @n <> 0 THROW 50004, 'FAIL: user 1 can see household B members', 1;
    SELECT @n = COUNT(*) FROM core.Invites WHERE HouseholdId = @hB;
    IF @n <> 0 THROW 50005, 'FAIL: user 1 can see household B invites', 1;

    UPDATE core.Households SET Name = N'hacked' WHERE Id = @hB;
    IF @@ROWCOUNT <> 0 THROW 50006, 'FAIL: user 1 renamed household B', 1;
    DELETE FROM core.Members WHERE HouseholdId = @hB;
    IF @@ROWCOUNT <> 0 THROW 50007, 'FAIL: user 1 deleted household B members', 1;

    -- 3. Writing a row into another household is blocked.
    DECLARE @blocked bit = 0;
    BEGIN TRY
        INSERT INTO core.Members (HouseholdId, UserId, Role, DisplayName) VALUES (@hB, @u1, N'Owner', N'Intruder');
    END TRY
    BEGIN CATCH
        SET @blocked = 1;
    END CATCH;
    IF @blocked = 0 THROW 50008, 'FAIL: user 1 joined household B without an invite', 1;

    SET @blocked = 0;
    BEGIN TRY
        UPDATE core.Members SET HouseholdId = @hB WHERE HouseholdId = @hA AND UserId = @u1;
    END TRY
    BEGIN CATCH
        SET @blocked = 1;
    END CATCH;
    IF @blocked = 0 THROW 50009, 'FAIL: user 1 moved a member row into household B', 1;

    -- 4. Signed in, no household chosen: the user still sees their own memberships.
    EXEC sp_set_session_context N'HouseholdId', NULL;
    SELECT @n = COUNT(*) FROM core.Members WHERE UserId = @u1;
    IF @n <> 1 THROW 50010, 'FAIL: user 1 cannot list their own memberships', 1;
    SELECT @n = COUNT(*) FROM core.Households WHERE Id IN (@hA, @hB);
    IF @n <> 1 THROW 50011, 'FAIL: user 1 should list only household A', 1;

    PRINT 'PASS: row-level security keeps households apart.';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    EXEC sp_set_session_context N'UserId', NULL;
    EXEC sp_set_session_context N'HouseholdId', NULL;
    EXEC sp_set_session_context N'IsSystem', 1;
    DELETE FROM core.Households WHERE Id IN (@hA, @hB);
    DELETE FROM auth.AspNetUsers WHERE Id IN (@u1, @u2);
    EXEC sp_set_session_context N'IsSystem', NULL;
    THROW;
END CATCH;

-- Clean up.
EXEC sp_set_session_context N'UserId', NULL;
EXEC sp_set_session_context N'HouseholdId', NULL;
EXEC sp_set_session_context N'IsSystem', 1;
DELETE FROM core.Households WHERE Id IN (@hA, @hB);
DELETE FROM auth.AspNetUsers WHERE Id IN (@u1, @u2);
EXEC sp_set_session_context N'IsSystem', NULL;
