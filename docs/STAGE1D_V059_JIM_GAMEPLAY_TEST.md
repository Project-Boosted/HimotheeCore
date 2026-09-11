# HimotheeCore v0.5.9 — Jim Gameplay Acceptance

This release keeps the proven Stage 1D compatibility layer and adds the first real third-party gameplay resources.

## Pinned upstream resources

- `jimathy/jim-mining` — v3.0.12 — commit `0a8a29783b78c337b2a5939c3e365dd1fcb44071`
- `jimathy/jim-recycle` — v3.1.0 — commit `118df45c2a8e58ba16913dd0b64fb9164c14faf4`

The txAdmin recipe downloads these directly from the upstream repositories into `resources/[jim]`. Their source is not vendored into HimotheeCore.

## Deployment

Use the normal HimotheeCore txAdmin recipe and keep the existing database. Schema remains 5.

After startup, confirm there are no fatal errors from:

- `jim_bridge`
- `jim-mining`
- `jim-recycle`

Then join a character and run:

```text
/himostage
/himocoretest
/himocompat
/himojimtest
```

Expected framework result:

```text
COMPAT TEST PASS
```

Expected gameplay-resource result:

```text
JIM GAMEPLAY TEST PASS | jim-mining + jim-recycle loaded on HimotheeCore
```

## Mining smoke test

1. Visit one of Jim Mining's configured mining areas.
2. Confirm target interactions appear.
3. Confirm the mining shop/menu opens.
4. Obtain/use a mining tool.
5. Mine stone/ore and verify rewards enter ox_inventory.
6. Test stone cracking/washing or panning.
7. Test at least one smelting/crafting recipe.
8. Sell at least one mining output and verify money changes through HimotheeCore.

## Recycling smoke test

1. Confirm dumpster/scrapyard targets appear.
2. Search a valid recycling target.
3. Verify material rewards enter ox_inventory.
4. Enter/use the recycling centre.
5. Obtain `recyclablematerial` and trade it for configured materials.
6. Sell at least one material and verify money changes through HimotheeCore.

## Inventory catalogue

The recipe extends pinned ox_inventory v2.47.9 with the core item names used by these two Jim resources, including mining tools, ores, gems, jewellery, recyclable material and standard scrap materials.

Custom Jim item images are intentionally not required for this acceptance pass. They can be copied into the ox_inventory image set in a later presentation/polish stage.

## Pass criteria

Stage 1D real-world compatibility is accepted when both scripts start cleanly and the smoke tests complete without modifying Jim's gameplay source code.
