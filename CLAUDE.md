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

## Production deploys

Follow [docs/Passwordless-Prod-Deploys.md](docs/Passwordless-Prod-Deploys.md). In short:

- Prod only through a Remote Control session on the person's PC, with their saved `Prod` login (`-CredentialName Prod`).
- Never read, print, log or copy the password, never open the saved `.xml`, and never ask for the password in chat. If the login is missing or rejected, ask the person to run `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod` themselves.
- No password on a command line or in an environment variable (no `sqlcmd -P`, no `SOSAFAM_DB_CONNECTION` for Prod).
- Dev first, PR merged, deploy from `main` in sync with `origin/main`, after a backup.
- Show the exact command and the `-WhatIf` output, then wait for an explicit go. That go allows `-ConfirmTarget`.
- On failure, stop and report. Don't retry or roll back.
