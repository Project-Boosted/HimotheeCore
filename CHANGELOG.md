# Changelog

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
