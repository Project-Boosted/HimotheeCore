# HimotheeCore v0.1.0 — Stage 1 Foundation

This is the first development package for the HimotheeCore FiveM framework.

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

Do **not** paste the repository homepage URL (`https://github.com/Project-Boosted/HimotheeCore`) into the Recipe URL box. The repository page is HTML, so txAdmin will report it as `invalid yaml`.

The recipe itself downloads HimotheeCore from the canonical repository:

    https://github.com/Project-Boosted/HimotheeCore

New deployments download the current `main` branch. Existing production servers are intentionally not silently auto-updated; framework/database updates should be applied as explicit releases.

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
- Validation checks Lua syntax, recipe YAML, version consistency and imports the SQL schema into a disposable MariaDB database.
- Tags matching `v*` run `.github/workflows/release.yml`, build a clean ZIP, calculate SHA-256 and publish a GitHub Release automatically.
- `VERSION`, `recipe.yaml` and `himo_core/fxmanifest.lua` are checked to ensure their release versions match.
