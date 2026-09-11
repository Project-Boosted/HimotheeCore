# HimotheeCore v0.5.3 — Stage 1D QBX Runtime Contract Fix

HimotheeCore is a modular, progression-focused FiveM framework. v0.5.3 preserves the real-server-tested character/spawn/Illenium/core lifecycle and fixes two QBX compatibility defects found by live ox_inventory testing: early group updates reaching ox_inventory before `PlayerData.groups` existed, and a Lua multi-return bug that passed two SQL parameters to the one-placeholder `qbx_vehicles` plate query.

## Runtime architecture

```text
FiveM connection
  -> Himothee account/session
  -> multicharacter
  -> spawn
  -> Illenium appearance
  -> world-ready
  -> Himothee Player Object
  -> compatibility layer
       -> qb-core
       -> qbx_core
       -> qbx_vehicles
       -> ox_inventory / ox_target
       -> QB helper facades
       -> jim_bridge
  -> gameplay resources
```

HimotheeCore remains authoritative for accounts, characters, money, metadata, jobs, groups, permissions and owned vehicles. Compatibility resources translate third-party calls into those native services.

## v0.5.3 fixes

The QBX client now publishes a full `qbx_core:client:setGroups` snapshot before every incremental `qbx_core:client:onGroupUpdate`. This mirrors the ordering ox_inventory expects and prevents early character-load job/group events from indexing a nil `PlayerData.groups` table.

`qbx_vehicles` now normalises plates with a single-return `trim()` helper. The previous chained `string.gsub()` return leaked gsub's replacement-count value into `{ trim(plate) }`, causing oxmysql to receive two parameters for a one-placeholder query.

The v0.5.2 Jim compatibility fixes remain in place: populated `QBCore.Shared.Vehicles`, pinned Qbox vehicle metadata during txAdmin deployment, and both qb-inventory config layouts used by Jim Bridge.

## Compatibility stack

The txAdmin recipe installs/starts:

```text
ox_lib
oxmysql
ox_target 1.18.1

himo_core
himo_qb_bridge
qb-core
qbx_core
qbx_vehicles

ox_inventory 2.47.9
qb-menu
qb-input
qb-target
qb-inventory
progressbar

jim_bridge

illenium-appearance
himo_appearance
himo_spawn
himo_characters
```

The exact-name QB helper resources are lightweight facades:

- `qb-menu` -> ox_lib contexts
- `qb-input` -> ox_lib input dialogs
- `qb-target` -> ox_target
- `qb-inventory` -> ox_inventory
- `progressbar` -> ox_lib progress bars

This allows many resources that declare traditional QBCore dependencies to start without installing duplicate legacy UI/inventory/target stacks.

## QBCore compatibility

`qb-core` exposes a QBCore-shaped API backed by HimotheeCore, including common PlayerData, player lookup, money, metadata, jobs/duty, gangs/groups, callbacks, notifications, usable items and shared catalogues.

Compatibility is intentionally API-by-API rather than claiming universal support. Scripts that directly query QBCore-specific SQL or undocumented internals may still require a resource-specific adapter.

## Qbox / QBX compatibility

`qbx_core` exposes the common QBX player/group/money/metadata/usable-item APIs and advertises a compatible 1.23.0 façade version. Its vehicle metadata API resolves the populated shared catalogue used by Jim Bridge. `qbx_vehicles` separately exposes owned-vehicle functions against `himo_vehicles` and satisfies the persistence surface required by ox_inventory's Qbox bridge.

## Jim Bridge

The recipe installs the audited Jim Bridge revision and lets it use the normal QBX + ox_inventory + ox_target path. Jim's shared item/job/vehicle cache therefore resolves through the same compatibility layer rather than a separate fake framework.

## Inventory persistence

Stage 1D schema 5 contains:

- `himo_characters.inventory`
- `himo_vehicles.glovebox`
- `himo_vehicles.trunk`

The txAdmin recipe maps the pinned ox_inventory Qbox database configuration from Qbox's `players` / `player_vehicles` tables onto HimotheeCore's native tables.

## Runtime tests

Core test:

```text
/himocoretest
```

Full compatibility test:

```text
/himocompat
```

v0.5.3 `/himocompat` validates both server and client paths, including QBCore callback transport, the live ox_inventory player inventory, the shared vehicle catalogue, qbx_vehicles persistence lookup, qb-inventory configuration, ox_target and Jim Bridge cache health.

A healthy server-side line includes:

```text
qb=true | qbx=true | catalog=true | vehicles=true | oxinv=true | qbinv=true | invcfg=true | jim=true
```

and the final line is:

```text
COMPAT TEST PASS | QB + QBX + callbacks + vehicle catalog + vehicle persistence + ox_inventory + ox_target + Jim + helper facades
```

See `docs/STAGE1D_V053_TEST.md` for the real-server acceptance sequence.

## txAdmin recipe

Use:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

v0.5.3 still requires **Himothee schema version 5**. There is no new SQL migration in this hotfix; existing characters, balances, inventory, vehicles, appearance, jobs, permissions and positions remain intact.

Migration chain:

1. `001_schema.sql`
2. `002_seed.sql`
3. `003_stage1b_lifecycle.sql`
4. `004_stage1c_core_services.sql`
5. `005_stage1c_account_roles.sql`
6. `006_stage1d_compatibility.sql`

## Permissions

Native Himothee roles (`owner`, `admin`, `staff`, `dev`) remain active alongside ACE/txAdmin permissions. `/himoperms` shows the current account's effective role permissions.

## Important compatibility rule

"Drag and drop" means a resource only gets Level-A compatibility after it has passed a real runtime test. A script may still need a small adapter when it hardcodes another framework's SQL tables, expects a resource we have not mapped yet, or uses undocumented internals.

GitHub Actions validates Lua syntax, txAdmin recipe wiring, schema 5, compatibility resource presence/start order, Jim vehicle and qb-inventory contracts, QBX group initialisation ordering, single-value vehicle plate trimming, helper health contracts and version consistency on every push/PR.
