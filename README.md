# HimotheeCore v0.3.2 — Stage 1B Lifecycle + Illenium

HimotheeCore is a progression-focused FiveM framework being built as a modular alternative to monolithic RP frameworks.

## Current lifecycle design

Real-server testing showed that stock autospawn plus a fullscreen character NUI was too fragile. The current lifecycle follows the proven separation used by Qbox while keeping HimotheeCore's database, Player Object and APIs independent.

Key rules:

- `basic-gamemode` is stopped; HimotheeCore owns player login/spawning.
- `ox_lib` context/input UI handles character and spawn selection.
- character selection runs in a solo tutorial/preview session with a scripted camera.
- loading character data and entering the game world are separate lifecycle states.
- `himo_spawn` owns spawn choice.
- `himo_appearance` owns Himothee appearance persistence.
- Illenium Appearance supplies the full visual character editor.
- tutorial mode ends before normal gameplay is released.

## Resources

```text
resources/[himo]/
  himo_core        account, character data, Player Object, lifecycle authority
  himo_qb_bridge   limited QB compatibility surface for supported third-party resources
  himo_characters  multicharacter selection/creation and preview session
  himo_spawn       spawn-location selection
  himo_appearance  Himothee appearance persistence + Illenium integration
```

## txAdmin recipe

Use this exact raw recipe URL:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

A clean deployment installs the current CFX resource tree, `ox_lib`, `oxmysql`, the supported Illenium Appearance release, HimotheeCore resources, and all required SQL automatically.

## Database

Fresh/update deployments run:

1. `database/001_schema.sql`
2. `database/002_seed.sql`
3. `database/003_stage1b_lifecycle.sql`
4. Illenium's additive appearance/outfit SQL files

Schema version 2 adds `himo_character_appearance`, keyed directly to the Himothee character ID. Existing accounts, characters, balances, jobs and saved positions are retained.

## Login flow

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

## v0.3.2 first-character appearance flow

New-character appearance no longer depends on Illenium detecting a QB framework compatibility event. After world entry, HimotheeCore checks whether the character has a saved appearance. If none exists it calls Illenium's generic `startPlayerCustomization` export directly.

```text
Create identity
  -> choose spawn
  -> world ready
  -> no saved appearance detected
  -> Illenium full creator opens automatically
  -> face / genetics / hair / overlays / clothing / props / tattoos
  -> save
  -> himo_character_appearance
  -> Illenium playerskins mirror
```

Once an appearance exists, future spawns skip the automatic creator and simply load the saved appearance. This also gives older test characters created before v0.3.2 a one-time automatic appearance setup.

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
- `/himofirstappearance` — force the direct Illenium creator while testing

The direct create/load commands remain temporary development tools; normal players should use the character selector.

## Resource start order

The supplied `server.cfg` enforces:

```text
spawnmanager
baseevents
ox_lib
oxmysql
himo_core
himo_qb_bridge
illenium-appearance
himo_appearance
himo_spawn
himo_characters
```

`basic-gamemode` is explicitly stopped.

## Status

v0.3.2 is a Stage 1B development acceptance build. Character preview, existing/new character login, spawn selection, world visibility, reconnect position persistence, switching and appearance persistence are being tested on a real txAdmin server before Stage 1B is frozen.

See `docs/STAGE1B_V030_TEST.md` for the real-server acceptance sequence and `docs/API.md` for current framework APIs.

## GitHub automation

Every push/PR to `main` validates Lua syntax, recipe YAML, txAdmin dependency wiring, stopped stock autospawn, absence of the old fullscreen character NUI, resource ordering, version consistency, and SQL/schema v2 against MariaDB. Version tags build a release ZIP and SHA-256 automatically.
