/*******************************************************************************
 * Object Type: Inline Table-Valued Function
 * Schema: MAC
 * Name: fxGetPrefixTypeIdFromProxy
 * Description: Splits a Proxy-ID and resolves its prefix to TypeId, TypeName and table. No row when the proxy is malformed or the prefix unknown.
 * Dependencies: MAC.vwTableTypesAndPrefixes
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created
 ******************************************************************************/

CREATE OR ALTER FUNCTION [MAC].[fxGetPrefixTypeIdFromProxy] (@Proxy VARCHAR(100))
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
            CAST(SUBSTRING(@Proxy, 6, CHARINDEX(':', @Proxy, 6) - 6) AS VARCHAR(6)) AS [PartKey]
        WHERE
            @Proxy LIKE '[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]:%:%'
            AND CHARINDEX(':', @Proxy, 6) > 6
    ) AS [S]
    INNER JOIN [MAC].[vwTableTypesAndPrefixes] AS [V]
        ON [V].[Prefix] = [S].[Prefix];
GO
