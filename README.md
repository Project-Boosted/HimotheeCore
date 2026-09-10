# HimotheeCore v0.4.2 — Stage 1C Core Framework Services

HimotheeCore is a modular, progression-focused FiveM framework. v0.4.2 keeps the real-server-tested multicharacter/spawn/Illenium lifecycle and adds a native account-role permission layer alongside txAdmin/ACE permissions.

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
  -> jobs / groups / metadata / gameplay resources
```

## Stage 1C services

v0.4.x includes:

- framework/player statebags and global readiness state
- persistent metadata with controlled replication
- expanded Player Object API
- multi-job, grades, primary job and duty
- generic groups/gangs with grades and primary membership
- server/client callback wrappers
- duplicate-account session protection
- txAdmin shutdown save-all
- QB compatibility for common PlayerData/money/metadata/job/group/callback APIs
- native account roles plus ACE fallback
- runtime self-tests

## Permissions

v0.4.2 supports two permission authorities:

1. **ACE/txAdmin** — `group.admin` can still receive `himo.admin`, `himo.staff` and `himo.dev` through `permissions.cfg` when txAdmin has a linked provider identifier.
2. **Himothee account roles** — persistent `owner`, `admin`, `staff` and `dev` roles stored against the Himothee account ID and independent of txAdmin provider linking.

Migration 005 creates and seeds the role/permission tables. Once the database is ready, HimotheeCore performs the initial-owner bootstrap at runtime: if `himo:autoBootstrapOwner 1` is enabled and no owner exists, the earliest existing Himothee account becomes `owner`. On a fresh server this naturally becomes the first account created. Once an owner exists, the bootstrap does nothing.

Owner has wildcard `himo.*`. Admin has `himo.admin`, `himo.staff` and `himo.dev`. Staff and developer roles receive their matching permissions.

Useful commands:

```text
/himoperms
/himostage
/himocoretest
/himodebugplayer [serverId]
/himograntrole <serverId> <owner|admin|staff|dev>
/himorevokerole <serverId> <owner|admin|staff|dev>
```

`/himoperms` is deliberately non-privileged and reports only the Himothee account ID, role names, and true/false permission results; it does not expose raw FiveM identifiers.

## txAdmin recipe

Use:

    https://raw.githubusercontent.com/Project-Boosted/HimotheeCore/main/recipe.yaml

v0.4.2 requires **schema version 4**. Existing characters, balances, appearance, jobs, positions and Stage 1C data are preserved.

Migration chain:

1. `001_schema.sql`
2. `002_seed.sql`
3. `003_stage1b_lifecycle.sql`
4. `004_stage1c_core_services.sql`
5. `005_stage1c_account_roles.sql`

## Resources

```text
resources/[himo]/
  himo_core
  himo_qb_bridge
  himo_characters
  himo_spawn
  himo_appearance
```

## Regular development commands

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

See `docs/API.md` for the framework API and `docs/STAGE1C_V040_TEST.md` for the Stage 1C acceptance sequence.

GitHub Actions validates Lua syntax, recipe wiring, resource order, native permission services and the full MariaDB migration chain through schema 4 on every push/PR.
