/*******************************************************************************
 * Object Type: Indexes
 * Schema: PAN
 * Name: Locations_Indexes
 * Description: Indexes on PAN.Locations.
 * Dependencies: PAN.Locations
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-25
 * Modified: 2026-11-25 - Created (migration 20261125_1904_CreatePAN_Locations)
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Locations_HouseholdId' AND [object_id] = OBJECT_ID(N'[PAN].[Locations]'))
    CREATE NONCLUSTERED INDEX [IX_Locations_HouseholdId] ON [PAN].[Locations] ([HouseholdId]) INCLUDE ([Name], [TrackingMode], [SortOrder]) WHERE [IsDeleted] = 0;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_Locations_HouseholdId_Name' AND [object_id] = OBJECT_ID(N'[PAN].[Locations]'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Locations_HouseholdId_Name] ON [PAN].[Locations] ([HouseholdId], [Name]) WHERE [IsDeleted] = 0;
GO
