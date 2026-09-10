# Changelog

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
