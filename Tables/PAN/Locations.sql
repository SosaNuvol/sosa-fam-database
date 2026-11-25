/*******************************************************************************
 * Object Type: Table
 * Schema: PAN
 * Name: Locations
 * Description: Places a household keeps food (Pantry, Fridge, Basement, ...). TrackingMode Count keeps exact quantities; Status keeps Have / Low / Out.
 * Dependencies: 1902_CreatePAN_Schema, 1903_CreateMAC_ProxyIdInfrastructure, core.Households, security.HouseholdIsolation
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1904_CreatePAN_Locations)
 * Proxy-ID prefix: PALO (.github/ProxyID-PrefixRegistry.md)
 ******************************************************************************/

IF OBJECT_ID(N'[PAN].[Locations]', N'U') IS NULL
BEGIN
    CREATE TABLE [PAN].[Locations]
    (
        [LocationID]   INT              IDENTITY(1,1) NOT NULL,
        [HouseholdId]  UNIQUEIDENTIFIER NOT NULL,
        [Proxy]        VARCHAR(100)     NOT NULL,
        [PartKey]      VARCHAR(6)       NOT NULL,
        [Name]         NVARCHAR(60)     NOT NULL,
        [TrackingMode] NVARCHAR(10)     NOT NULL CONSTRAINT [DF_Locations_TrackingMode] DEFAULT (N'Count'),
        [SortOrder]    INT              NOT NULL CONSTRAINT [DF_Locations_SortOrder] DEFAULT (0),
        [IsActive]     BIT               NOT NULL CONSTRAINT [DF_Locations_IsActive]    DEFAULT (1),
        [IsDeleted]    BIT               NOT NULL CONSTRAINT [DF_Locations_IsDeleted]   DEFAULT (0),
        [ModifiedDate] DATETIMEOFFSET(7) NULL,
        [ModifiedById] UNIQUEIDENTIFIER  NULL,
        [CreatedDate]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_Locations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById]  UNIQUEIDENTIFIER  NOT NULL,
        [DEX_ROW_TS]   DATETIME2(7)      NOT NULL CONSTRAINT [DF_Locations_DEX_ROW_TS]  DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_Locations] PRIMARY KEY CLUSTERED ([LocationID] ASC),
        CONSTRAINT [FK_Locations_Households] FOREIGN KEY ([HouseholdId]) REFERENCES [core].[Households] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [UQ_Locations_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [CK_Locations_TrackingMode] CHECK ([TrackingMode] IN (N'Count', N'Status'))
    );
END
GO
