/*******************************************************************************
 * Object Type: Scalar Function
 * Schema: UTL
 * Name: fxGetPartKey
 * Description: Hex of the UTC year and month, the middle segment of a Proxy-ID.
 * Dependencies: None
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created
 ******************************************************************************/

CREATE OR ALTER FUNCTION [UTL].[fxGetPartKey] ()
RETURNS VARCHAR(6)
AS
BEGIN
    -- Hex of the UTC year and month: 202611 -> 0x00031773 -> '31773'.
    -- See .github/ProxyID-PrefixRegistry.md.
    DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @YearMonth INT = (YEAR(@Now) * 100) + MONTH(@Now);
    RETURN SUBSTRING(CONVERT(VARCHAR(10), CAST(@YearMonth AS VARBINARY(4)), 1), 6, 6);
END;
GO
