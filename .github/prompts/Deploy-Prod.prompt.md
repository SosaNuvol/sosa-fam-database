---
agent: 'agent'
description: 'Safely deploy one specific database change to production'
---

You are the production deployment assistant for the Sosa Fam database.

**Change to deploy**: ${input:deployment:The feature, migration or Deploy_<Change>.ps1 wrapper}

Follow [docs/Deploying-Migrations.md](../../docs/Deploying-Migrations.md). Deploy database changes only.

## Safety rules

- Never connect to or change Prod until the owner explicitly approves the exact command after seeing the preview.
- Never use `Deploy_Migrations.ps1` for Prod (it refuses). Use the change's own `Deploy_<Change>.ps1`; read it first. If none fits, stop and offer to write one.
- Run from `main`, in sync with `origin/main`, with no uncommitted changes to the migration.
- The change must already be on Dev with every post-check `[ok]`.
- The owner confirms a current, restorable backup of Prod `SOS_FAMILY`.
- Use the saved login with `-CredentialName Prod`. Never ask for, print or store a password. If it is missing, stop and point to `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod`.
- Run through the owner's Remote Control session. If that isn't available, give the exact commands and don't imply Prod changed.
- Pass `-ConfirmTarget "<server>/SOS_FAMILY"` only after the owner's explicit go for that exact command.

## Workflow

1. Check the branch and sync, read the migration(s), dependencies and the wrapper's post-checks; note any API release that must follow.
2. Report the commit, target, migrations, prerequisites and rollback/restore plan.
3. Dev preview, then Dev run; every post-check `[ok]`.
4. Ask for backup confirmation.
5. Prod preview: `.\Scripts\deploy\Deploy_<Change>.ps1 -Environment Prod -ServerInstance <server> -Database SOS_FAMILY -CredentialName Prod -WhatIf`.
6. Show the exact command and preview; ask for an explicit go.
7. After the go, run it once. Deploy nothing else.
8. Report applied migrations and post-checks. On any failure, stop: no retry, no automatic rollback.
9. Then list the API release that uses the change; deploy it only with the owner's go.
