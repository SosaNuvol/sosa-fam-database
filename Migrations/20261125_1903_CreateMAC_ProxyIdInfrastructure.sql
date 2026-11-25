/*
Migration: 20261125_1903_CreateMAC_ProxyIdInfrastructure
Author: Claude (for Andres Sosa)
Date: 2026-11-25
Description: Creates the Proxy-ID infrastructure: UTL.fxGetPartKey, MAC.vwTableTypesAndPrefixes (with the PAN prefixes PALO, PAPR, PAST), MAC.fxGeneratePrefixParts, MAC.fxGeneratePrefixProxy and MAC.fxGetPrefixTypeIdFromProxy.
Dependencies: 20261125_1900_CreateUTL_Schema, 20261125_1901_CreateMAC_Schema
Rollback: See the ROLLBACK SCRIPT block at the end.
Expected impact: Five new objects; no tables touched.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261125_1903_CreateMAC_ProxyIdInfrastructure';
    DECLARE @StartedAt DATETIME2(7) = SYSUTCDATETIME();

    -- Skip if already applied
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF OBJECT_ID(N'[UTL].[fxGetPartKey]', N'FN') IS NULL
        EXEC(N'CREATE FUNCTION [UTL].[fxGetPartKey] ()
    RETURNS VARCHAR(6)
    AS
    BEGIN
        -- Hex of the UTC year and month: 202611 -> 0x00031773 -> ''31773''.
        -- See .github/ProxyID-PrefixRegistry.md.
        DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();
        DECLARE @YearMonth INT = (YEAR(@Now) * 100) + MONTH(@Now);
        RETURN SUBSTRING(CONVERT(VARCHAR(10), CAST(@YearMonth AS VARBINARY(4)), 1), 6, 6);
    END');

    IF OBJECT_ID(N'[MAC].[vwTableTypesAndPrefixes]', N'V') IS NULL
        EXEC(N'CREATE VIEW [MAC].[vwTableTypesAndPrefixes]
    AS
        -- One row per registered prefix. Tables without a *Types table use one fixed prefix
        -- (TypeId NULL). Tables with a *Types table add a UNION ALL block that reads it.
        SELECT
            [P].[Prefix],
            [P].[TypeId],
            [P].[TableName],
            [P].[TypeName]
        FROM
        (
            VALUES
            (CAST(''PALO'' AS VARCHAR(4)), CAST(NULL AS INT), CAST(N''PAN.Locations''   AS NVARCHAR(128)), CAST(N''Location''   AS NVARCHAR(128))),
            (''PAPR'', NULL, N''PAN.Products'',    N''Product''),
            (''PAST'', NULL, N''PAN.StockLevels'', N''StockLevel'')
        ) AS [P] ([Prefix], [TypeId], [TableName], [TypeName])');

    IF OBJECT_ID(N'[MAC].[fxGeneratePrefixParts]', N'IF') IS NULL
        EXEC(N'CREATE FUNCTION [MAC].[fxGeneratePrefixParts] (@TypeName NVARCHAR(128), @TypeId INT)
    RETURNS TABLE
    AS
    RETURN
        SELECT
            [V].[Prefix],
            [UTL].[fxGetPartKey]() AS [PartKey]
        FROM
            [MAC].[vwTableTypesAndPrefixes] AS [V]
        WHERE
            [V].[TypeName] = @TypeName
            AND ([V].[TypeId] = @TypeId OR ([V].[TypeId] IS NULL AND @TypeId IS NULL))');

    IF OBJECT_ID(N'[MAC].[fxGeneratePrefixProxy]', N'FN') IS NULL
        EXEC(N'CREATE FUNCTION [MAC].[fxGeneratePrefixProxy] (@TypeName NVARCHAR(128), @TypeId INT)
    RETURNS VARCHAR(100)
    AS
    BEGIN
        -- Returns ''Prefix:PartKey:''; the caller appends CAST(NEWID() AS NVARCHAR(36)).
        -- NULL when the type is not registered.
        DECLARE @Result VARCHAR(100);
        SELECT @Result = [PP].[Prefix] + '':'' + [PP].[PartKey] + '':''
        FROM [MAC].[fxGeneratePrefixParts](@TypeName, @TypeId) AS [PP];
        RETURN @Result;
    END');

    IF OBJECT_ID(N'[MAC].[fxGetPrefixTypeIdFromProxy]', N'IF') IS NULL
        EXEC(N'CREATE FUNCTION [MAC].[fxGetPrefixTypeIdFromProxy] (@Proxy VARCHAR(100))
    RETURNS TABLE
    AS
    RETURN
        SELECT
            [S].[Prefix],
            [S].[PartKey],
            [V].[TypeId],
            [V].[TypeName],
            [V].[TableName]
        FROM
        (
            SELECT
                CAST(LEFT(@Proxy, 4) AS VARCHAR(4)) AS [Prefix],
                CAST(SUBSTRING(@Proxy, 6, CHARINDEX('':'', @Proxy, 6) - 6) AS VARCHAR(6)) AS [PartKey]
            WHERE
                @Proxy LIKE ''[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]:%:%''
                AND CHARINDEX('':'', @Proxy, 6) > 6
        ) AS [S]
        INNER JOIN [MAC].[vwTableTypesAndPrefixes] AS [V]
            ON [V].[Prefix] = [S].[Prefix]');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs])
    VALUES (@MigrationName, N'Creates the Proxy-ID infrastructure objects', 1, DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()));

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
SET QUOTED_IDENTIFIER ON;
DROP FUNCTION [MAC].[fxGetPrefixTypeIdFromProxy];
DROP FUNCTION [MAC].[fxGeneratePrefixProxy];
DROP FUNCTION [MAC].[fxGeneratePrefixParts];
DROP VIEW [MAC].[vwTableTypesAndPrefixes];
DROP FUNCTION [UTL].[fxGetPartKey];
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261125_1903_CreateMAC_ProxyIdInfrastructure';
*/
