/*******************************************************************************
 * Object Type: Table
 * Schema: dbo
 * Name: SchemaVersion
 * Description: One row per applied migration. The runner skips any migration that has a
 *              row with Success = 1. Migrations insert their own row as their last step.
 * Dependencies: None
 * Author: Claude (for Andres Sosa)
 * Created: 2026-11-24 (migration 00000000_0000_CreateSchemaVersionTable)
 ******************************************************************************/

IF OBJECT_ID(N'[dbo].[SchemaVersion]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[SchemaVersion]
    (
        [SchemaVersionID] INT            IDENTITY(1,1) NOT NULL,
        [MigrationName]   NVARCHAR(255)  NOT NULL,
        [Description]     NVARCHAR(500)  NULL,
        [AppliedDate]     DATETIME2(7)   NOT NULL CONSTRAINT [DF_SchemaVersion_AppliedDate] DEFAULT (SYSUTCDATETIME()),
        [AppliedBy]       NVARCHAR(128)  NOT NULL CONSTRAINT [DF_SchemaVersion_AppliedBy] DEFAULT (SUSER_SNAME()),
        [Success]         BIT            NOT NULL CONSTRAINT [DF_SchemaVersion_Success] DEFAULT (1),
        [ExecutionTimeMs] INT            NULL,
        CONSTRAINT [PK_SchemaVersion] PRIMARY KEY CLUSTERED ([SchemaVersionID] ASC)
    );
END
GO
