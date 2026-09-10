# HimotheeCore v0.1.3 — Stage 1 Foundation

HimotheeCore is a progression-focused FiveM framework currently in Stage 1 development.

## Current Stage 1 coverage

- txAdmin recipe-ready deployment
- MySQL/MariaDB schema with migration tracking
- oxmysql-backed core resource
- account + identifier lifecycle
- FiveM temporary-to-final source migration during join
- multi-character capable character storage
- account balances and transaction ledger
- jobs + grades + character job membership
- generic organisations + roles + permissions
- persistent vehicles
- audit logging
- framework schema/version validation
- temporary development commands for creating/loading characters

## txAdmin recipe

Use this exact raw recipe URL in txAdmin Server Deployer:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

Do not paste the repository homepage URL into the Recipe URL box.

The recipe downloads the current CFX resource tree, oxmysql and the current HimotheeCore `main` branch, then installs the database automatically.

## Database

Fresh installs run:

1. `database/001_schema.sql`
2. `database/002_seed.sql`

The schema version is recorded in `himo_schema_migrations`.

## Development commands

- `/himoaccount` — resolve/show the account ID for your current final FiveM player source.
- `/himocreate Firstname Lastname YYYY-MM-DD gender` — create a test character.
- `/himoload <characterId>` — load one of your own characters.
- `/himowhoami` — display the currently loaded character.

These commands are temporary and will be replaced by the proper character UI.

## Resource start order

`oxmysql` must start before `himo_core`.

## v0.1.3 join lifecycle fix

FiveM uses a temporary player source during `playerConnecting` and assigns the final in-game source at `playerJoining`. HimotheeCore now migrates the resolved account mapping across that boundary and can defensively re-resolve the account if needed.

## Status

This is a development/testing foundation build, not a production-ready release yet.

## GitHub automation

- Every push/pull request to `main` runs `.github/workflows/validate.yml`.
- Validation checks Lua syntax, recipe YAML, release version consistency, recipe path safety and SQL import against MariaDB.
- Tags matching `v*` run `.github/workflows/release.yml` and publish a release ZIP + SHA-256 checksum.
