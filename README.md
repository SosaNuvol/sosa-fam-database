# sosa-fam-database

The SQL Server database behind every Sosa Fam app: sign-in, households (the tenants), members, invites, stores, the family app's grocery lists, and the food storage app's tables as they arrive. Households are kept apart by row-level security inside the database.

The standards follow the Solasta database repository, adapted for households. Start with:

| Read | For |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Building a database and making your first change |
| [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md) | The binding rules |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How a change goes from issue to Prod |
| [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) | Day-to-day workflow and patterns |
| [STRUCTURE.md](STRUCTURE.md) | What lives in each folder |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Names, templates and commands on one page |
| [docs/Deploying-Migrations.md](docs/Deploying-Migrations.md) | Deploying to Dev and Prod |
| [CICD_GUIDE.md](CICD_GUIDE.md) | Automated checks |
| [CLAUDE.md](CLAUDE.md), [.github/copilot-constitution.md](.github/copilot-constitution.md), [.github/copilot-instructions.md](.github/copilot-instructions.md) | Rules for AI agents |
| [.github/ProxyID-PrefixRegistry.md](.github/ProxyID-PrefixRegistry.md) | Public IDs (`Prefix:PartKey:GUID`) |
| [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md), [.github/prompts/](.github/prompts/) | Ready-made prompts and diagnostic queries |

## How it works

- **`Migrations/`** is the history: `YYYYMMDD_HHMM_<Verb><SCHEMA>_<What>.sql` files, applied in name order, each once, each in its own transaction, each recorded in `dbo.SchemaVersion`. Never edit one that has run anywhere.
- **Object folders** (`Tables/`, `Functions/`, `SecurityPolicies/`, ...) hold the current state of every object, one file per object, safe to run twice.
- **`src/SosaFam.Database`** is the runner. It carries every migration, skips the applied ones, and supports `--what-if`, `--filter`, `--require` and `--list`.
- **`Scripts/deploy/`** has one PowerShell wrapper per change, with prerequisites, a preview, a Prod confirmation and post-checks.

## Environments

| | Database | Server |
|---|---|---|
| Dev | `SOS_FAMILY` | SQL Server on Andres's PC |
| Prod | `SOS_FAMILY` | the family's SQL Server (later) |

## Schemas

| Schema | Holds |
|---|---|
| `auth` | ASP.NET Core Identity users, logins, tokens; refresh tokens |
| `core` | Households, members (Owner, Adult, Member, Child), invites, stores |
| `security` | Row-level security predicates and the `HouseholdIsolation` policy |
| `family` | Grocery lists and items (family data-sharing app) |
| `PAN` | Food storage app (reserved) |
| `dbo` | `SchemaVersion` |

## Baseline

| Migration | What it adds |
|---|---|
| `00000000_0000_CreateSchemaVersionTable` | `dbo.SchemaVersion`; records the baseline on databases the old DbUp runner built |
| `00000000_0001_Baseline_AuthIdentity` | Identity users, external logins, refresh tokens |
| `00000000_0002_Baseline_CoreHouseholds` | Households, members, invites |
| `00000000_0003_Baseline_CoreRowLevelSecurity` | The policy that filters and blocks rows by household |
| `00000000_0004_Baseline_AppRole` | `sosafam_api`, data-only access for the API's login |
| `00000000_0005_Baseline_FamilyGroceryLists` | Stores, grocery lists and items |

These five predate the standards and keep their original SQL unchanged (see the constitution's *Baseline exceptions*).

## Test the household isolation

```bash
sqlcmd -S <server> -d SOS_FAMILY -E -b -i Scripts/Tests/Policies/security/HouseholdIsolation_Tests.sql
```

It prints `PASS: row-level security keeps households apart.` or fails with the check that broke.
