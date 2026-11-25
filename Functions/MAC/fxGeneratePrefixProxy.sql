/*******************************************************************************
 * Object Type: Scalar Function
 * Schema: MAC
 * Name: fxGeneratePrefixProxy
 * Description: 'Prefix:PartKey:' for a TypeName and TypeId; the caller appends a GUID.
 * Dependencies: MAC.fxGeneratePrefixParts
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created
 ******************************************************************************/

CREATE OR ALTER FUNCTION [MAC].[fxGeneratePrefixProxy] (@TypeName NVARCHAR(128), @TypeId INT)
RETURNS VARCHAR(100)
AS
BEGIN
    -- Returns 'Prefix:PartKey:'; the caller appends CAST(NEWID() AS NVARCHAR(36)).
    -- NULL when the type is not registered.
    DECLARE @Result VARCHAR(100);
    SELECT @Result = [PP].[Prefix] + ':' + [PP].[PartKey] + ':'
    FROM [MAC].[fxGeneratePrefixParts](@TypeName, @TypeId) AS [PP];
    RETURN @Result;
END;
GO
