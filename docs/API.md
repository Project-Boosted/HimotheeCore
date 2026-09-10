# HimotheeCore v0.1.0 server exports

## Player/account

- `exports.himo_core:GetAccountId(source)`
- `exports.himo_core:GetCharacter(source)`
- `exports.himo_core:GetCharacterId(source)`
- `exports.himo_core:GetCharacters(source)`

## Character lifecycle

- `exports.himo_core:CreateCharacter(source, data)`
- `exports.himo_core:LoadCharacter(source, characterId)`
- `exports.himo_core:UnloadCharacter(source)`
- `exports.himo_core:SaveCharacterPosition(source, position)`

## Money

- `exports.himo_core:GetBalance(characterId, accountType)`
- `exports.himo_core:AddMoney(characterId, accountType, amount, reason, reference)`
- `exports.himo_core:RemoveMoney(characterId, accountType, amount, reason, reference)`

Current account types: `cash`, `bank`.
