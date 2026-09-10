# Changelog

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
