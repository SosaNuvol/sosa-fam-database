/*******************************************************************************
 * Object Type: View
 * Schema: MAC
 * Name: vwTableTypesAndPrefixes
 * Description: Every registered Proxy-ID prefix with its TypeId, table and TypeName.
 * Dependencies: None (fixed prefixes listed inline)
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created
 ******************************************************************************/

CREATE OR ALTER VIEW [MAC].[vwTableTypesAndPrefixes]
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
        (CAST('PALO' AS VARCHAR(4)), CAST(NULL AS INT), CAST(N'PAN.Locations'   AS NVARCHAR(128)), CAST(N'Location'   AS NVARCHAR(128))),
        ('PAPR', NULL, N'PAN.Products',    N'Product'),
        ('PAST', NULL, N'PAN.StockLevels', N'StockLevel')
    ) AS [P] ([Prefix], [TypeId], [TableName], [TypeName]);
GO
