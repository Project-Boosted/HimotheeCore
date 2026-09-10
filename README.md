# HimotheeCore v0.2.2 — Stage 1B

HimotheeCore is a progression-focused FiveM framework being built as a modular alternative to existing monolithic RP frameworks.

## Current Stage 1 coverage

### Stage 1A — foundation

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

### Stage 1B — character & player lifecycle

- dedicated `himo_characters` resource
- automatic character selector after joining
- existing-character cards
- character creation form
- account-safe character selection
- Himothee-owned native character spawn path with bounded model/collision waits
- black-screen watchdog/recovery path
- NUI closed-state transparency so the selector cannot remain as an opaque overlay over gameplay
- return to the character's last saved position
- configurable default spawn for new characters
- periodic server-authoritative position autosave
- disconnect position-save attempt
- Stage 1B Player Object/API
- synchronized client character/money state
- `/switchcharacter` development command
- `/himounblack` temporary recovery/debug command

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

v0.2.2 does not require a schema migration; it uses the Stage 1A character metadata/position tables already installed.

## Character flow

Normal players should no longer need `/himocreate` or `/himoload`.

On join:

    FiveM connection
      -> Himothee account resolution
      -> character selector
      -> create or choose character
      -> HimotheeCore character load
      -> bounded native spawn
      -> last saved position/default spawn
      -> selector NUI removed/transparent
      -> active Player Object

Temporary debug commands remain available while Stage 1 is under development:

- `/himoaccount`
- `/himocreate Firstname Lastname YYYY-MM-DD gender`
- `/himoload <characterId>`
- `/himowhoami`
- `/himoplayer`
- `/switchcharacter`
- `/himounblack`

## Resource start order

`oxmysql` must start before `himo_core`, and `himo_core` must start before `himo_characters`. The supplied `server.cfg` already enforces this.

## Configuration

Current Stage 1B convars in `server.cfg`:

    setr himo:maxCharacters 4
    setr himo:startingCash 500
    setr himo:startingBank 5000
    setr himo:autoSaveMs 60000
    setr himo:spawnX 215.76
    setr himo:spawnY -810.12
    setr himo:spawnZ 30.73
    setr himo:spawnHeading 157.0

## API

See `docs/API.md` for the current Player Object, character, money and lifecycle APIs.

## Status

This is still a development/testing framework. Stage 1B must pass real-server character-selector, spawn, autosave and reconnect tests before Stage 2 progression work begins.

## GitHub automation

- Every push/pull request to `main` runs `.github/workflows/validate.yml`.
- Validation checks Lua syntax, NUI JavaScript syntax, closed-state NUI transparency, recipe YAML, resource wiring, release version consistency and SQL import against MariaDB.
- Tags matching `v*` run `.github/workflows/release.yml` and publish a release ZIP + SHA-256 checksum.
