# HimotheeCore v0.1.2 — Stage 1 Foundation

This is the first development stage of the HimotheeCore FiveM framework.

## Stage 1 goals

- txAdmin recipe-ready deployment layout
- MySQL/MariaDB schema built for long-term migrations
- oxmysql-backed core resource
- account + identifier lifecycle
- multi-character capable character storage
- account balances and transaction ledger
- jobs + grades + character job membership
- generic organisations + roles + permissions
- persistent vehicles
- audit log
- framework schema/version validation
- basic development commands for creating/loading characters

## txAdmin recipe

Use this exact **raw recipe URL** in txAdmin Server Deployer:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

Do **not** paste the repository homepage URL into the Recipe URL box. The repository page is HTML, so txAdmin will report it as `invalid yaml`.

### v0.1.2 bootstrap change

The recipe now downloads the complete current CFX `resources` tree into `resources/[cfx-default]`, following the deployment pattern used by the official CFX/Qbox recipes. It no longer moves individual upstream folders such as `sessionmanager`, which prevents deployment failures when CFX reorganises system resources.

New deployments download the current `main` branch. Existing deployed servers are intentionally not silently overwritten; framework/database updates should be applied as explicit development redeploys or releases.

## Database

Fresh installs run:

1. `database/001_schema.sql`
2. `database/002_seed.sql`

The schema version is recorded in `himo_schema_migrations`. `himo_core` refuses to report a healthy database if the installed schema is below its required version.

## Development commands

These are intentionally temporary Stage 1 commands:

- `/himoaccount` — show the account ID resolved for your current FiveM source.
- `/himocreate Firstname Lastname 1990-01-01 male` — create a test character.
- `/himoload <characterId>` — load one of your own characters.
- `/himowhoami` — display currently loaded character information.

They will be replaced by the proper multicharacter UI later.

## Resource start order

`oxmysql` must start before `himo_core`.

## Status

This package is a foundation build. It is intended for development/testing, not public production deployment yet.

## GitHub automation

- Every push or pull request to `main` runs `.github/workflows/validate.yml`.
- Validation checks Lua syntax, recipe YAML, release version consistency and imports the SQL schema into a disposable MariaDB database.
- Tags matching `v*` run `.github/workflows/release.yml`, build a clean ZIP, calculate SHA-256 and publish a GitHub Release automatically.
