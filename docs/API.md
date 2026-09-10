# HimotheeCore v0.3.0 API

v0.3.0 separates character data loading from final world entry. Resources that need a physically spawned/ready player should use the world-ready API/event rather than only checking whether character data exists.

## Player/account exports

- `exports.himo_core:GetAccountId(source)` — resolved account ID if loaded.
- `exports.himo_core:EnsureAccount(source)` — resolve/load the account if necessary.
- `exports.himo_core:GetPlayer(source)` — Stage 1B Player Object for a loaded character.
- `exports.himo_core:GetCharacter(source)` — raw loaded character data.
- `exports.himo_core:GetCharacterId(source)` — loaded character database ID.
- `exports.himo_core:GetCharacters(source)` — characters owned by the resolved account.
- `exports.himo_core:IsPlayerLoaded(source)` — **server**: true only after final spawn/world handoff.

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

Current methods:

- `Player.Functions.GetData()`
- `Player.Functions.GetIdentifier()`
- `Player.Functions.GetMoney(accountType)`
- `Player.Functions.AddMoney(accountType, amount, reason, reference)`
- `Player.Functions.RemoveMoney(accountType, amount, reason, reference)`
- `Player.Functions.GetPrimaryJob()`
- `Player.Functions.SavePosition(position)`

## Character lifecycle exports

- `exports.himo_core:CreateCharacter(source, data)`
- `exports.himo_core:LoadCharacter(source, characterId)`
- `exports.himo_core:UnloadCharacter(source)`
- `exports.himo_core:SaveCharacterPosition(source, position)`
- `exports.himo_core:SavePlayerPosition(source)`

`LoadCharacter` means the character's data exists in memory; it does **not** mean the client has completed spawn. The final spawn resource calls `himo_core:server:finishLogin`, after which `IsPlayerLoaded` becomes true.

## Money exports

- `exports.himo_core:GetBalance(characterId, accountType)`
- `exports.himo_core:AddMoney(characterId, accountType, amount, reason, reference)`
- `exports.himo_core:RemoveMoney(characterId, accountType, amount, reason, reference)`

Current account types: `cash`, `bank`.

## Client core exports

- `exports.himo_core:GetCharacter()`
- `exports.himo_core:GetCharacterId()`
- `exports.himo_core:IsCharacterLoaded()`
- `exports.himo_core:IsPlayerLoaded()` — true after final world-ready acknowledgement.
- `exports.himo_core:EndTutorialSession()` — lifecycle recovery/helper export.

## Spawn API

- `exports.himo_spawn:Open(character, isNewCharacter)` — open the Stage 1B spawn selector.
- `himo_spawn:client:selected(selection)` — local event fired with `{x, y, z, w, label, isNewCharacter}`.

## Appearance API

- `exports.himo_appearance:PrepareCharacter(character)` — apply saved appearance or the gender-appropriate default model.
- `exports.himo_appearance:ApplyAppearance(appearance)`
- `exports.himo_appearance:LoadCurrent()`
- `exports.himo_appearance:CaptureAppearance()`
- `exports.himo_appearance:OpenEditor(character, required)`

Appearance data is stored in `himo_character_appearance` and belongs to HimotheeCore rather than a third-party framework table.

## Lifecycle events

Server:

- `himo_core:server:characterLoaded(source, character)` — character data entered memory.
- `himo_core:server:characterUnloaded(source, character)`
- `himo_core:server:playerLoaded(source, character)` — final world spawn completed and player became ready.

Client:

- `himo_core:client:characterLoaded(character)`
- `himo_core:client:characterUnloaded()`
- `himo_core:client:playerLoaded(character)` — internal final world-ready handoff.
- `himo_core:client:onPlayerLoaded(character)` — public local event after tutorial mode ends.
- `himo_core:client:onPlayerUnload()`
- `himo_core:client:onMoneyChanged(accountType, balance, transactionType, amount, reason)`
- `himo_characters:client:spawned(character)`

For future jobs, inventory, skills, housing and other gameplay resources, prefer `himo_core:server:playerLoaded` / `himo_core:client:onPlayerLoaded` when initialization requires a fully spawned player.
