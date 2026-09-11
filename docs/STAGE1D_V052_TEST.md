# HimotheeCore v0.5.2 — Jim compatibility acceptance

This hotfix specifically verifies the two real-server errors found with Jim Bridge: an empty QBX vehicle catalogue and qb-inventory config discovery failure.

## 1. Clean redeploy

Use the normal txAdmin recipe:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

Confirm HimotheeCore reports v0.5.2 and schema 5. No new SQL migration is required.

## 2. Startup log

During `qbx_core` startup expect a HimotheeCompat line reporting that vehicle definitions were loaded into `QBCore.Shared.Vehicles`.

During Jim Bridge startup the following errors must be absent:

    ERROR: Can NOT find qbx_core Vehicles list
    ERROR: Config loader failed from qb-inventory

Jim should report a non-zero vehicle count plus inventory weight and slot values. With the supplied server.cfg, the expected inventory limits are 120000 weight and 50 slots.

## 3. Core regression

Join an existing character and verify multicharacter, spawn selection, Illenium appearance and inventory still load normally. Then run:

    /himocoretest

Expected: `CORE TEST PASS`.

## 4. Full compatibility probe

Run:

    /himocompat

Expected server checks include:

    qb=true
    qbx=true
    catalog=true
    vehicles=true
    oxinv=true
    qbinv=true
    invcfg=true
    jim=true

The client checks from v0.5.1 must also remain true, including the real QB callback round trip.

The final line must be:

    COMPAT TEST PASS

## 5. Vehicle catalogue sanity check

The txAdmin installation should contain:

    resources/[himo]/qbx_core/shared/vehicles.lua
    resources/[himo]/qbx_core/QBOX_UPSTREAM_LICENSE

The recipe replaces HimotheeCore's small source fallback catalogue with the pinned upstream Qbox vehicle catalogue before the server starts.

## 6. Inventory config sanity check

The installation should contain both:

    resources/[himo]/qb-inventory/config.lua
    resources/[himo]/qb-inventory/config/config.lua

These expose the old and new qb-inventory key layouts Jim Bridge probes while using the ox_inventory convars as the authority.

## Pass criteria

v0.5.2 passes when the two original Jim errors are gone, `/himocoretest` passes, `/himocompat` ends in `COMPAT TEST PASS`, the character lifecycle has no regression, and Jim reports populated vehicle/inventory cache values.

After this passes, the next compatibility test should be one real Jim gameplay resource rather than another synthetic bridge-only test.
