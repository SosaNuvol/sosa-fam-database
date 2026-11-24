# CLAUDE.md

Rules for Claude in this repository. Read these before changing anything:

1. [.github/copilot-constitution.md](.github/copilot-constitution.md): binding rules and the response protocol.
2. [.github/copilot-instructions.md](.github/copilot-instructions.md): templates and patterns.
3. [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md): the full standard (it wins any conflict).
4. [.github/ProxyID-PrefixRegistry.md](.github/ProxyID-PrefixRegistry.md): before creating any Proxy-enabled table.
5. [docs/Deploying-Migrations.md](docs/Deploying-Migrations.md): before deploying anything.

Task prompts for common changes are in [.github/prompts/](.github/prompts/).

Quick checks before a PR:

```bash
dotnet build src/SosaFam.Database
# Scratch database: everything applies, and a second run skips everything
dotnet run --project src/SosaFam.Database -- --ensure-database "Server=localhost,1433;Database=Scratch;User Id=sa;Password=<dev password>;TrustServerCertificate=True"
dotnet run --project src/SosaFam.Database -- "<same connection string>"
sqlcmd -S localhost,1433 -U sa -P '<dev password>' -d Scratch -b -i Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql
```
