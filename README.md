# HimotheeCore v0.5.2 — Stage 1D Jim Compatibility Hotfix

HimotheeCore is a modular, progression-focused FiveM framework. v0.5.2 preserves the real-server-tested character/spawn/Illenium/core lifecycle and fixes two runtime contracts found by real Jim Bridge testing: the QBX/QBCore shared vehicle catalogue and qb-inventory configuration discovery.

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

## v0.5.2 fixes

Jim Bridge reads `QBCore.Shared.Vehicles` directly when QBX is present. v0.5.2 now loads a real vehicle definition catalogue before the rest of `qbx_core` starts. The txAdmin recipe replaces the small source fallback with the vehicle catalogue from the pinned Qbox upstream commit and preserves the upstream licence alongside it.

Jim Bridge also probes `qb-inventory/config.lua` and `qb-inventory/config/config.lua` to discover inventory limits. Both files now exist and map directly to HimotheeCore's ox_inventory convars. With the standard configuration they resolve to 120000 maximum weight and 50 slots.

Owned-vehicle persistence remains separate in `qbx_vehicles`; the shared vehicle catalogue is model metadata, not ownership state.

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

`qbx_core` exposes the common QBX player/group/money/metadata/usable-item APIs and advertises a compatible 1.23.0 façade version. Its vehicle metadata API now resolves the same populated shared catalogue Jim Bridge reads. `qbx_vehicles` separately exposes owned-vehicle functions against `himo_vehicles` and satisfies the persistence surface required by ox_inventory's Qbox bridge.

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

v0.5.2 `/himocompat` validates both server and client paths and now explicitly fails if `QBCore.Shared.Vehicles` is empty, if qb-inventory's config contract is missing, or if Jim's cache lacks vehicles, inventory weight or inventory slots.

A healthy server-side line includes:

```text
qb=true | qbx=true | catalog=true | vehicles=true | oxinv=true | qbinv=true | invcfg=true | jim=true
```

and the final line is:

```text
COMPAT TEST PASS | QB + QBX + callbacks + vehicle catalog + vehicle persistence + ox_inventory + ox_target + Jim + helper facades
```

See `docs/STAGE1D_V052_TEST.md` for the real-server acceptance sequence.

## txAdmin recipe

Use:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

v0.5.2 still requires **Himothee schema version 5**. There is no new SQL migration in this hotfix; existing characters, balances, inventory, vehicles, appearance, jobs, permissions and positions remain intact.

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

GitHub Actions validates Lua syntax, txAdmin recipe wiring, schema 5, compatibility resource presence/start order, the Jim vehicle and qb-inventory config contracts, helper health contracts and version consistency on every push/PR.
