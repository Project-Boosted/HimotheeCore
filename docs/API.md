# HimotheeCore v0.2.0 API

Stage 1B introduces a stable player-facing API while retaining the lower-level character and money exports for framework resources.

## Player/account exports

- `exports.himo_core:GetAccountId(source)` — return the resolved Himothee account ID if loaded.
- `exports.himo_core:EnsureAccount(source)` — resolve/load the account if necessary.
- `exports.himo_core:GetPlayer(source)` — return the Stage 1B Player Object for a loaded character.
- `exports.himo_core:GetCharacter(source)` — return the raw loaded character data.
- `exports.himo_core:GetCharacterId(source)` — return the loaded character database ID.
- `exports.himo_core:GetCharacters(source)` — return characters owned by the resolved account.

## Player Object

```lua
local Player = exports.himo_core:GetPlayer(source)
if not Player then return end

local citizenId = Player.Functions.GetIdentifier()
local cash = Player.Functions.GetMoney('cash')
local primaryJob = Player.Functions.GetPrimaryJob()

Player.Functions.AddMoney('bank', 250, 'delivery payment', 'contract:123')
Player.Functions.RemoveMoney('cash', 50, 'shop purchase', 'shop:24')
```

Current Stage 1B methods:

- `Player.Functions.GetData()`
- `Player.Functions.GetIdentifier()`
- `Player.Functions.GetMoney(accountType)`
- `Player.Functions.AddMoney(accountType, amount, reason, reference)`
- `Player.Functions.RemoveMoney(accountType, amount, reason, reference)`
- `Player.Functions.GetPrimaryJob()`
- `Player.Functions.SavePosition(position)`

This object is intentionally small in Stage 1B. Job, skill, reputation and inventory methods will be added by their own systems rather than bloating the core.

## Character lifecycle exports

- `exports.himo_core:CreateCharacter(source, data)`
- `exports.himo_core:LoadCharacter(source, characterId)`
- `exports.himo_core:UnloadCharacter(source)`
- `exports.himo_core:SaveCharacterPosition(source, position)`
- `exports.himo_core:SavePlayerPosition(source)` — capture the live server-side ped position.

## Money exports

Lower-level money APIs remain available when a resource operates on a known character ID:

- `exports.himo_core:GetBalance(characterId, accountType)`
- `exports.himo_core:AddMoney(characterId, accountType, amount, reason, reference)`
- `exports.himo_core:RemoveMoney(characterId, accountType, amount, reason, reference)`

Current account types: `cash`, `bank`.

## Client exports

- `exports.himo_core:GetCharacter()`
- `exports.himo_core:GetCharacterId()`
- `exports.himo_core:IsCharacterLoaded()`

## Lifecycle events

Server:

- `himo_core:server:characterLoaded(source, character)`
- `himo_core:server:characterUnloaded(source, character)`

Client:

- `himo_core:client:characterLoaded(character)`
- `himo_core:client:characterUnloaded()`
- `himo_core:client:onMoneyChanged(accountType, balance, transactionType, amount, reason)`
- `himo_characters:client:spawned(character)`
