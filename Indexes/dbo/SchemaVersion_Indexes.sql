/*******************************************************************************
 * Object Type: Index
 * Schema: dbo
 * Name: UQ_SchemaVersion_MigrationName
 * Table: [dbo].[SchemaVersion]
 * Type: UNIQUE NONCLUSTERED, filtered (Success = 1)
 * Description: A migration can be recorded as applied only once.
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24
 ******************************************************************************/

-- Filtered and unique indexes need these options.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'UQ_SchemaVersion_MigrationName' AND [object_id] = OBJECT_ID(N'[dbo].[SchemaVersion]'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_SchemaVersion_MigrationName]
        ON [dbo].[SchemaVersion] ([MigrationName])
        WHERE [Success] = 1;
GO
