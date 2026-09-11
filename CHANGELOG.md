# Changelog

## 0.5.1 - Stage 1D Compatibility Validation & Drag-and-Drop Hardening

- Expanded `/himocompat` from three framework checks into a server+client runtime acceptance test.
- Added live checks for `qbx_vehicles`, `ox_inventory`, `ox_target`, `qb-inventory`, `qb-target`, `qb-menu`, `qb-input` and `progressbar`.
- Added a real QBCore client -> server -> client callback round-trip test.
- Added non-mutating `Health()` exports to the exact-name QB helper facades.
- Added client compatibility probe support inside `himo_core`.
- Hardened CI around schema 5, the ox_inventory native-table mapping, exact-name helper resources, resource start order and version consistency.
- Kept the existing character/spawn/Illenium lifecycle unchanged.
- No new SQL migration beyond Stage 1D schema 5.

## 0.5.0 - Stage 1D Compatibility Layer

- Added exact-name `qb-core` and `qbx_core` compatibility facades backed by HimotheeCore.
- Added `qbx_vehicles` backed by native `himo_vehicles` records.
- Expanded PlayerData/money/metadata/job/group/usable-item compatibility for common QB/QBX resources.
- Added pinned `ox_inventory` v2.47.9 and `ox_target` v1.18.1 deployment.
- Added schema 5 persistence fields for player inventory plus vehicle glovebox/trunk storage.
- Mapped ox_inventory's Qbox database adapter onto `himo_characters` and `himo_vehicles` rather than creating fake Qbox tables.
- Added exact-name `qb-menu`, `qb-input`, `qb-target`, `qb-inventory` and `progressbar` facades backed by ox resources.
- Added audited/pinned Jim Bridge deployment and configured it to use QBX + ox inventory/target compatibility paths.
- Added shared item/job/gang/vehicle catalog synchronisation for QB-style resources.

## 0.4.2 - Native Account Roles

- Added persistent Himothee account roles (`owner`, `admin`, `staff`, `dev`) alongside ACE/txAdmin permissions.
- Added runtime first-owner bootstrap when no owner exists and `himo:autoBootstrapOwner 1` is enabled.
- Added `/himoperms`, role grant/revoke tooling and schema version 4.

## 0.4.1 - txAdmin ACE Principal Integration

- Added txAdmin `{{addPrincipalsMaster}}` permission injection to generated server configuration.
- Kept Himothee staff/admin commands protected by ACE while diagnosing unlinked txAdmin identities.

## 0.4.0 - Stage 1C Core Framework Services

- Preserved the proven v0.3.2 multicharacter, spawn and automatic Illenium Appearance lifecycle without rewriting it.
- Added namespaced framework/player statebags plus global version/stage/build/readiness state.
- Added persistent metadata APIs with default hunger/thirst/stress/status values and an explicit replication whitelist.
- Expanded the server Player Object with metadata, jobs, groups, lifecycle and save methods.
- Added native multi-job support with grade validation, primary-job selection and per-job duty state.
- Added generic multi-group membership for gangs, factions, clubs and crews, with grades and primary group per group type.
- Added namespaced server/client callback wrappers backed by ox_lib.
- Added ACE permission helpers and a framework command registry.
- Added duplicate-account session ownership protection and auditable `himo_player_sessions` records.
- Added txAdmin `serverShuttingDown` save-all handling in addition to periodic/disconnect saves.
- Expanded the limited QB compatibility bridge with money, metadata, job/duty, group/gang, player lookup, permissions and QB callback transport.
- Added `/himostatus`, `/himostage`, `/himocoretest`, `/himodebugplayer`, job/group admin commands and metadata test tooling.
- Added `004_stage1c_core_services.sql`; required Himothee schema version is now 3.
- Added CI coverage for all Stage 1C services and schema-v3 tables.

## 0.3.2 - Direct Illenium first-character creator

- Fixed new characters not automatically opening Illenium Appearance after identity/spawn completion.
- Replaced reliance on the QB-only `qb-clothes:client:CreateFirstCharacter` event for automatic creation with Illenium's generic `startPlayerCustomization` export.
- Automatic appearance creation now keys off persistent state: any loaded character without a saved Himothee appearance receives the full creator once.
- Added a direct first-character configuration covering genetics, facial features, overlays, clothing, props and tattoos while preserving the gender-selected freemode model.
- Added Illenium routing-bucket isolation/reset around the direct creator.
- Direct creator saves now persist to `himo_character_appearance` and mirror into Illenium's `playerskins` table.
- Added `/himofirstappearance` as a development recovery/test command for the direct creator.
- Existing characters with saved appearances continue to load normally and do not reopen the creator.
- No Himothee schema-version bump is required.

## 0.3.1 - Illenium Appearance bridge

- Added `himo_qb_bridge`, a deliberately limited QB compatibility layer that provides `qb-core` for supported third-party adapters without changing HimotheeCore's native API.
- Added QB-shaped player identity, money, metadata, job and gang data for Illenium Appearance.
- Added standard QB player-loaded/unloaded compatibility events mapped from HimotheeCore's world-ready lifecycle.
- Added automatic installation of the supported Illenium Appearance release through the txAdmin recipe.
- Added Illenium `playerskins`, outfit and management-outfit SQL installation.
- New characters now open Illenium's full first-character customization flow after the spawn handoff succeeds.
- `/himoappearance` now opens Illenium's full appearance editor when available.
- Illenium appearance saves are mirrored into `himo_character_appearance` so Himothee multicharacter previews remain independently available.
- Himothee preview/application now uses Illenium's full appearance payload when available, including genetics/hair/overlays/tattoos rather than only clothing components.
- The existing Himothee clothing editor remains as a fallback if Illenium is unavailable.
- No Himothee schema-version bump is required; Illenium's own additive tables are installed separately.

## 0.3.0 - Stage 1B Qbox-style lifecycle refactor

- Rebuilt the character/login lifecycle after studying current Qbox core/spawn behaviour.
- `basic-gamemode` is now explicitly stopped so stock autospawn cannot compete with HimotheeCore.
- Added `ox_lib` as a txAdmin-installed dependency and moved character creation/selection to context/input UI.
- Removed the old fullscreen `himo_characters` HTML/CSS/JavaScript NUI from the critical login path.
- Added solo tutorial-session character selection with an in-world preview ped and scripted camera.
- Reworked character create/load into server-authoritative `ox_lib` callbacks.
- Added `himo_spawn` as a separate spawn-selection resource with Last Location, Legion Square, LSIA, Sandy Shores and Paleto Bay choices.
- Added separate character-loaded versus player-world-ready lifecycle states.
- Added explicit tutorial-session shutdown on final player load.
- Added `himo_appearance` with Himothee-owned model/component/prop persistence and a standalone `ox_lib` clothing editor.
- Added `himo_character_appearance` and schema migration version 2.
- Added bounded spawnmanager fallback rather than allowing a missing callback to strand login.
- Added CI guards preventing `ensure basic-gamemode` and fullscreen character NUI from returning.
- Existing account, character, money, job and position data remains compatible.

## 0.2.2 - Stage 1B NUI black-overlay fix

- Fixed the character selector NUI continuing to paint an opaque dark root layer after the selector closed.
- Made `:root`/`html` permanently transparent for FiveM NUI rendering.
- Moved the full-screen selector background to `body:not(.hidden)` so it exists only while the selector is visible.
- Changed the closed selector state to `display: none !important` as well as transparent/no-input.
- Added a CI guard so future NUI CSS cannot reintroduce an opaque root/html background.
- No SQL migration is required.

## 0.2.1 - Stage 1B spawn black-screen fix

- Replaced selected-character `spawnmanager:spawnPlayer()` usage with a bounded native spawn path so a stale CFX `spawnLock` cannot strand the client on a black screen.
- Added model-load and collision-streaming timeouts.
- Added a 12-second emergency spawn watchdog that restores visibility and fades the screen back in if the spawn sequence does not complete.
- Added `/himounblack` as a temporary Stage 1B recovery/debug command.
- Kept `spawnmanager` only for suppressing the stock autospawn path.
- No SQL migration is required.

## 0.2.0 - Stage 1B character and player lifecycle

- Added `himo_characters` as a dedicated multicharacter/login resource.
- Added full-screen character selection UI with existing-character cards and new-character creation.
- Added account-safe character refresh/create/select server events with action throttling.
- Added controlled spawn handling with last-location restore and a configurable default spawn.
- Added `/switchcharacter` for Stage 1B testing.
- Added a server-side Player Object with data, money, job and save methods.
- Added server-authoritative periodic position autosaving and disconnect save attempts.
- Added client character/money state synchronization and client exports.
- Added Stage 1B NUI/resource/version checks to GitHub Actions.
- Kept the Stage 1 SQL schema compatible; no database migration is required for v0.2.0.

## 0.1.4 - system chat bootstrap fix

- Enabled Cfx.re's built-in system chat with `set resources_useSystemChat true` before `ensure chat`.
- Restored the default `T` text-chat input path needed for Stage 1 development commands.

## 0.1.3 - account join lifecycle fix

- Fixed FiveM temporary `playerConnecting` source IDs not being carried into the final in-game `playerJoining` source.
- Added account mapping migration during `playerJoining`.
- Added defensive lazy account re-resolution for development commands and future framework exports.
- Added `EnsureAccount` server export for resources that explicitly need account resolution.

## 0.1.2 - txAdmin CFX bootstrap fix

- Reworked the txAdmin recipe to download the complete current CFX resources tree instead of moving individual upstream folders.
- Removed the broken `tmp/cfx/[system]/sessionmanager` deployment assumption.
- Aligned the bootstrap layout with the official CFX/Qbox recipe pattern.
- Kept the Stage 1 stock `basic-gamemode` available for first-spawn testing.

## 0.1.1 - first-spawn bootstrap

- Added the Stage 1 stock gamemode bootstrap path for clean first joins.

## 0.1.0 - Stage 1 Foundation

- Initial HimotheeCore framework foundation.
- txAdmin recipe and automated database installation.
- Account, identifier and character persistence.
- Money ledger, jobs, organisations, vehicles and audit schema.
- GitHub validation and release automation prepared.
