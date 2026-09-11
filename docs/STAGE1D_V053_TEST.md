# HimotheeCore v0.5.3 — QBX runtime acceptance

This hotfix verifies two real-server defects found while loading a new character with ox_inventory enabled: an uninitialised QBX group table on the client and a multi-return SQL parameter bug in qbx_vehicles.

## 1. Deploy

Use the normal txAdmin recipe:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

Confirm HimotheeCore reports v0.5.3 and schema 5. No new SQL migration is required.

## 2. Character load regression

Join or create a character. During character load, the client console must not show:

    SCRIPT ERROR: @ox_inventory/modules/bridge/qbx/client.lua:10: attempt to index a nil value (local 'groups')

The QBX façade now sends a complete `qbx_core:client:setGroups` snapshot before the incremental `qbx_core:client:onGroupUpdate` event.

Verify the normal lifecycle still works:

- multicharacter selector
- spawn selection
- world-ready handoff
- Illenium appearance load / first-character creator
- ox_inventory attachment

## 3. Vehicle persistence probe

Run:

    /himocompat

The server must not show an oxmysql error similar to:

    Expected 1 parameters, but received 2.

The `vehicles=true` check exercises `qbx_vehicles:GetVehicleIdByPlate()` using a harmless non-existent health-check plate.

## 4. Core and compatibility tests

Run:

    /himostage
    /himocoretest
    /himocompat

Expected:

    HimotheeCore v0.5.3 | Stage 1D | schema 5 | ready=true
    CORE TEST PASS

The compatibility server line should include:

    qb=true | qbx=true | catalog=true | vehicles=true | oxinv=true | qbinv=true | invcfg=true | jim=true

The client checks should remain true for QB, QBX, callback transport, ox_inventory, ox_target, qb-inventory, qb-target, qb-menu, qb-input and progressbar.

Final line:

    COMPAT TEST PASS

## 5. Jim regression

The v0.5.2 Jim fixes must remain healthy. Startup must not report:

    ERROR: Can NOT find qbx_core Vehicles list
    ERROR: Config loader failed from qb-inventory

Jim Bridge should still report a populated vehicle catalogue and the configured inventory limits.

## Pass criteria

v0.5.3 passes when the ox_inventory `groups` nil error is gone, the qbx_vehicles SQL parameter-count error is gone, `/himocoretest` passes, `/himocompat` ends in `COMPAT TEST PASS`, and the existing character/spawn/appearance/Jim compatibility path has no regression.
