# HimotheeCore v0.5.1 — Stage 1D compatibility acceptance

This test proves the compatibility layer without changing the working Himothee character/spawn/appearance lifecycle.

## 1. Deploy

Use the normal txAdmin recipe:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

Confirm the recipe reports v0.5.1 and the core reports schema 5.

## 2. Core regression

Join an existing character and verify:

- multicharacter preview works
- spawn selection works
- Illenium appearance reloads
- inventory attaches only after the player is world-ready
- `/switchcharacter` still works
- a new character with no appearance still opens Illenium automatically

Then run:

    /himocoretest

Expected: `CORE TEST PASS`.

## 3. Full compatibility probe

Run:

    /himocompat

The command now checks both server and client paths.

Expected server checks:

- `qb=true`
- `qbx=true`
- `vehicles=true`
- `oxinv=true`
- `qbinv=true`
- `jim=true`

Expected client checks:

- `qbcore=true`
- `qbxcore=true`
- `qbcallback=true`
- `oxinventory=true`
- `oxtarget=true`
- `qbinventory=true`
- `qbtarget=true`
- `qbmenu=true`
- `qbinput=true`
- `progressbar=true`

Final line must be:

    COMPAT TEST PASS

The callback check performs a real QBCore client -> server -> client callback round trip. The inventory checks require the current player's ox_inventory instance to be loaded, not merely the resource to be started.

## 4. Inventory persistence

Open the player inventory and move at least one existing item to a different slot, or add an item through a test/admin resource. Disconnect/reconnect or switch character and return to the same character. The inventory layout must reload from `himo_characters.inventory`.

Vehicle glovebox and trunk data are persisted against the native `himo_vehicles` table.

## 5. QBCore helper facade smoke test

The following exact resource names must show `started` in the server resource list:

- `qb-core`
- `qb-menu`
- `qb-input`
- `qb-target`
- `qb-inventory`
- `progressbar`

They are compatibility facades; they use HimotheeCore, ox_lib, ox_target and ox_inventory underneath.

## 6. Qbox facade smoke test

The following exact resource names must show `started`:

- `qbx_core`
- `qbx_vehicles`

`qbx_core` exposes the player/group/money/metadata/usable-item surface required by the pinned ox_inventory Qbox bridge. `qbx_vehicles` maps owned-vehicle lookup and persistence to `himo_vehicles`.

## 7. Jim Bridge

`jim_bridge` must show `started` and `/himocompat` must report `jim=true`. This proves its shared cache can read the live item and job catalog from the compatibility stack.

After this passes, install one representative Jim resource as the first third-party acceptance test. Any missing API should be added to the compatibility layer rather than modifying the third-party script unless that script directly depends on framework-specific SQL or undocumented internals.

## Pass criteria

Stage 1D v0.5.1 passes when:

- core lifecycle has no regression
- schema 5 is active
- `/himocoretest` passes
- `/himocompat` ends with `COMPAT TEST PASS`
- inventory persists after reconnect/switch
- all exact-name QB helper facades start
- qbx_core/qbx_vehicles start
- Jim Bridge cache is healthy

Once accepted, the next compatibility milestone is a real Jim script test, followed by Stage 2 Activity Mastery/XP.
