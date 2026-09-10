# HimotheeCore v0.4.1 — Stage 1C Core Framework Services

HimotheeCore is a modular, progression-focused FiveM framework. v0.4.1 keeps the real-server-tested multicharacter/spawn/Illenium lifecycle from v0.3.2, the Stage 1C framework services from v0.4.0, and fixes txAdmin administrator ACE principal wiring.

## Current architecture

```text
FiveM connection
  -> account + duplicate-session guard
  -> multicharacter preview
  -> character load/create
  -> spawn selector
  -> appearance / Illenium
  -> world-ready lifecycle
  -> Himothee Player Object
  -> gameplay resources
```

`basic-gamemode` remains stopped so HimotheeCore is the only owner of player login/spawning.

## Stage 1C services

v0.4.x includes:

- namespaced framework/player statebags and global readiness state
- persistent metadata service with controlled replication
- expanded Player Object API
- native multi-job, grade, primary-job and duty APIs
- native multi-group/gang membership APIs
- namespaced server/client callback wrappers
- ACE permission service and framework command registry
- duplicate-account session protection
- auditable `himo_player_sessions`
- txAdmin shutdown save-all handling
- stronger QB compatibility for money, metadata, jobs, duty, gangs/groups and callbacks
- `/himocoretest` runtime acceptance command
- schema version 3

## v0.4.1 permission fix

The txAdmin-generated `server.cfg` now contains `{{addPrincipalsMaster}}` before `exec permissions.cfg`. During deployment txAdmin replaces that placeholder with `add_principal identifier.* group.admin` lines for the deploying admin/master account. `permissions.cfg` then grants `group.admin` the `himo.admin`, `himo.staff` and `himo.dev` ACE permissions.

## Resources

```text
resources/[himo]/
  himo_core        framework authority and core services
  himo_qb_bridge   deliberately limited QB compatibility layer
  himo_characters  multicharacter selection and preview lifecycle
  himo_spawn       spawn-location selector
  himo_appearance  Himothee persistence + Illenium integration
```

## txAdmin recipe

Use the raw recipe URL:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

A clean deployment installs the current CFX resources, `ox_lib`, `oxmysql`, the supported Illenium Appearance release, Himothee resources and all required SQL automatically.

## Database

The Himothee migration chain is:

1. `001_schema.sql` — foundation
2. `002_seed.sql` — default core data
3. `003_stage1b_lifecycle.sql` — appearance/lifecycle schema
4. `004_stage1c_core_services.sql` — sessions + generic groups

v0.4.1 requires **schema version 3**. Existing account, character, money, position and appearance data is preserved. There is no new SQL migration between v0.4.0 and v0.4.1.

## Player Object example

```lua
local Player = exports.himo_core:GetPlayer(source)
if not Player then return end

Player.Functions.AddMoney('bank', 250, 'delivery payment')
Player.Functions.SetMetadata('stress', 10)
Player.Functions.SetJob('trucker', 0)
Player.Functions.SetDuty(true)

local job = Player.Functions.GetPrimaryJob()
local groups = Player.Functions.GetGroups()
```

See `docs/API.md` for the current API contract.

## State model

Framework global state:

```text
himothee_core:version
himothee_core:stage
himothee_core:build
himothee_core:ready
```

Replicated player state includes:

```text
himo:characterId
himo:citizenId
himo:characterLoaded
himo:playerLoaded
himo:job
himo:onDuty
himo:group
himo:metadata
```

Only explicitly safe metadata keys are replicated; server-only metadata stays authoritative on the server.

## Development / acceptance commands

```text
/himoaccount
/himowhoami
/himoplayer
/himostatus
/himoduty [on|off]
/switchcharacter
/himoappearance
/himofirstappearance
```

Staff/admin acceptance commands:

```text
/himostage
/himocoretest [serverId]
/himodebugplayer [serverId]
/himosetjob <serverId> <job> <grade>
/himoaddjob <serverId> <job> <grade>
/himosetgroup <serverId> <group> <grade>
/himoaddgroup <serverId> <group> <grade>
/himometadata <serverId> <key> [value]
```

## QB compatibility

`himo_qb_bridge` provides `qb-core` for specifically mapped third-party APIs. v0.4.x covers common PlayerData, money, metadata, job/duty, gang/group, player lookup, permissions and QB callback transport.

It is intentionally not advertised as universal QB compatibility. An API is only added to the bridge after HimotheeCore has a native equivalent and it has been tested.

## Testing

Stage 1C must pass the real txAdmin acceptance plan in `docs/STAGE1C_V040_TEST.md`, including the existing character/spawn/Illenium regression tests, metadata persistence, duty state, session ownership and txAdmin restart saving.

GitHub Actions validates Lua syntax, recipe YAML, dependency/resource order, Stage 1C service presence, version consistency and schema version 3 against MariaDB on every push/PR.
