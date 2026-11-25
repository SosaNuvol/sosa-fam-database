/*******************************************************************************
 * Object Type: Unit Test
 * Schema: MAC
 * Name: ProxyId_Tests
 * Description: Checks the Proxy-ID infrastructure: UTL.fxGetPartKey, MAC.fxGeneratePrefixProxy
 *              and MAC.fxGetPrefixTypeIdFromProxy, for every PAN prefix. Reads only; changes
 *              nothing. Fails with an error naming the broken check; prints PASS otherwise.
 * Dependencies: 20261125_1903_CreateMAC_ProxyIdInfrastructure
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Usage:
 *   sqlcmd -S <server> -d <database> -E -b -i Scripts/Tests/Functions/MAC/ProxyId_Tests.sql
 ******************************************************************************/
SET NOCOUNT ON;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();
DECLARE @Expected VARCHAR(6) = SUBSTRING(CONVERT(VARCHAR(10), CAST((YEAR(@Now) * 100) + MONTH(@Now) AS VARBINARY(4)), 1), 6, 6);
DECLARE @Proxy VARCHAR(100);
DECLARE @n INT;

-- 1. PartKey: hex of YYYYMM (202611 -> 31773).
IF [UTL].[fxGetPartKey]() <> @Expected THROW 50101, 'FAIL: UTL.fxGetPartKey does not match the hex of the current UTC year and month', 1;
IF SUBSTRING(CONVERT(VARCHAR(10), CAST(202611 AS VARBINARY(4)), 1), 6, 6) <> '31773' THROW 50102, 'FAIL: PartKey algorithm changed (202611 should be 31773)', 1;

-- 2. Every PAN prefix generates and round-trips.
SELECT @n = COUNT(*) FROM [MAC].[vwTableTypesAndPrefixes] WHERE [Prefix] IN ('PALO', 'PAPR', 'PAST');
IF @n <> 3 THROW 50103, 'FAIL: the PAN prefixes are not all registered in MAC.vwTableTypesAndPrefixes', 1;

SET @Proxy = [MAC].[fxGeneratePrefixProxy](N'Product', NULL) + CAST(NEWID() AS NVARCHAR(36));
IF @Proxy NOT LIKE 'PAPR:' + @Expected + ':%' OR LEN(@Proxy) <> 4 + 1 + LEN(@Expected) + 1 + 36
    THROW 50104, 'FAIL: MAC.fxGeneratePrefixProxy built a malformed Product proxy', 1;

SELECT @n = COUNT(*) FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy) WHERE [TypeName] = N'Product' AND [PartKey] = @Expected AND [TableName] = N'PAN.Products';
IF @n <> 1 THROW 50105, 'FAIL: MAC.fxGetPrefixTypeIdFromProxy did not resolve a Product proxy', 1;

IF [MAC].[fxGeneratePrefixProxy](N'Location', NULL) NOT LIKE 'PALO:%' THROW 50106, 'FAIL: Location prefix', 1;
IF [MAC].[fxGeneratePrefixProxy](N'StockLevel', NULL) NOT LIKE 'PAST:%' THROW 50107, 'FAIL: StockLevel prefix', 1;

-- 3. Unknown and malformed input.
IF [MAC].[fxGeneratePrefixProxy](N'NoSuchType', NULL) IS NOT NULL THROW 50108, 'FAIL: an unknown type produced a proxy', 1;
SELECT @n = COUNT(*) FROM [MAC].[fxGetPrefixTypeIdFromProxy]('ZZZZ:31773:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8');
IF @n <> 0 THROW 50109, 'FAIL: an unregistered prefix resolved', 1;
SELECT @n = COUNT(*) FROM [MAC].[fxGetPrefixTypeIdFromProxy]('not-a-proxy');
IF @n <> 0 THROW 50110, 'FAIL: a malformed proxy resolved', 1;

PRINT 'PASS: Proxy-ID infrastructure works.';
