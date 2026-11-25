/*******************************************************************************
 * Object Type: Inline Table-Valued Function
 * Schema: MAC
 * Name: fxGeneratePrefixParts
 * Description: (Prefix, PartKey) for a TypeName and TypeId (TypeId NULL for fixed-prefix tables).
 * Dependencies: MAC.vwTableTypesAndPrefixes, UTL.fxGetPartKey
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created
 ******************************************************************************/

CREATE OR ALTER FUNCTION [MAC].[fxGeneratePrefixParts] (@TypeName NVARCHAR(128), @TypeId INT)
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
        AND ([V].[TypeId] = @TypeId OR ([V].[TypeId] IS NULL AND @TypeId IS NULL));
GO
