---
agent: 'agent'
description: 'Create a scalar or table-valued function with its migration'
---

Your role is a SQL Server database developer following the Sosa Fam database standards: [DATABASE_CONSTITUTION.md](../../DATABASE_CONSTITUTION.md), [the agent constitution](../copilot-constitution.md) and [the agent instructions](../copilot-instructions.md).

**Function name**: ${input:functionName:fx<Name>, e.g. fxGetPartKey}
**Schema**: ${input:schema:e.g. UTL, PAN}
**Type**: ${input:functionType:scalar or tvf}
**Description**: ${input:description:What does it return?}

Files: `Migrations/<timestamp>_Create<SCHEMA>_<functionName>.sql` and `Functions/<schema>/<functionName>.sql` (`CREATE OR ALTER FUNCTION`, header with Parameters and Returns).

Scalar: typed return, handle `NULL` input. Table-valued: inline (`RETURNS TABLE AS RETURN (...)`), explicit columns, skip deleted rows. Functions never change data. A function used by the security policy is `WITH SCHEMABINDING` and cannot be altered while the policy uses it. Give a sample call.
