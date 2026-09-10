# HimotheeCore v0.3.0 — Stage 1B Lifecycle Refactor

HimotheeCore is a progression-focused FiveM framework being built as a modular alternative to monolithic RP frameworks.

## Why v0.3.0 exists

The first Stage 1B implementation mixed stock FiveM autospawn, a fullscreen character NUI and HimotheeCore's own spawn handling. Real-server testing showed that this was too fragile. v0.3.0 replaces that path with a lifecycle based on the same architectural principles used by current Qbox while keeping HimotheeCore's database, player object and APIs independent.

Key rules in v0.3.0:

- `basic-gamemode` is stopped; HimotheeCore is the only owner of player login/spawning.
- `ox_lib` context/input UI replaces the fullscreen character-browser NUI.
- character selection runs in a solo tutorial/preview session with a scripted camera.
- loading character data and entering the game world are separate lifecycle states.
- `himo_spawn` owns spawn choice.
- `himo_appearance` owns appearance/clothing persistence.
- `himo_core` becomes world-ready only after the final spawn handoff.
- tutorial mode is explicitly ended before normal gameplay is released.

## Resources

```text
resources/[himo]/
  himo_core        account, character data, Player Object, lifecycle authority
  himo_characters  multicharacter selection/creation and preview session
  himo_spawn       spawn-location selection
  himo_appearance  standalone clothing/model persistence and editor
```

## txAdmin recipe

Use this exact raw recipe URL:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

A clean deployment installs the current CFX resource tree, `ox_lib`, `oxmysql`, HimotheeCore resources, and all required SQL automatically.

## Database

Fresh/update deployments run:

1. `database/001_schema.sql`
2. `database/002_seed.sql`
3. `database/003_stage1b_lifecycle.sql`

Schema version 2 adds `himo_character_appearance`, keyed directly to the Himothee character ID. Existing accounts, characters, balances, jobs and saved positions are retained.

## v0.3.0 login flow

```text
FiveM connection
  -> account resolution
  -> solo tutorial/preview session
  -> ox_lib character selector
  -> server-authoritative character load/create
  -> himo_spawn location selector
  -> apply saved/default appearance
  -> final spawn
  -> himo_core finishLogin
  -> NetworkEndTutorialSession
  -> world-ready Player Object
  -> gameplay
```

New characters are offered the standalone Himothee clothing editor after their first successful world spawn. Existing characters without saved v0.3.0 appearance data receive the gender-appropriate freemode model and can use `/himoappearance` to save clothing.

## Stage 1A foundation retained

- account + identifier lifecycle
- multi-character persistence
- cash/bank balances and transaction ledger
- jobs + grades + multi-job groundwork
- organisations + granular-role groundwork
- persistent vehicles
- audit logging
- migration tracking
- periodic/disconnect position saving
- Stage 1B Player Object

## Development commands

- `/himoaccount`
- `/himocreate Firstname Lastname YYYY-MM-DD gender`
- `/himoload <characterId>`
- `/himowhoami`
- `/himoplayer`
- `/switchcharacter`
- `/himoappearance`

The direct create/load commands remain temporary development tools; normal players should use the character selector.

## Resource start order

The supplied `server.cfg` enforces:

```text
spawnmanager
baseevents
ox_lib
oxmysql
himo_core
himo_appearance
himo_spawn
himo_characters
```

`basic-gamemode` is explicitly stopped.

## Status

v0.3.0 is a development acceptance build. It must pass character preview, existing/new character login, spawn selection, world visibility, reconnect position persistence, switching, and clothing persistence before Stage 1B is frozen.

See `docs/STAGE1B_V030_TEST.md` for the real-server acceptance sequence and `docs/API.md` for current framework APIs.

## GitHub automation

Every push/PR to `main` validates Lua syntax, recipe YAML, txAdmin dependency wiring, stopped stock autospawn, absence of the old fullscreen character NUI, resource ordering, version consistency, and SQL/schema v2 against MariaDB. Version tags build a release ZIP and SHA-256 automatically.
