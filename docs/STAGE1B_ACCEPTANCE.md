# Stage 1B Acceptance Test — HimotheeCore v0.2.0

Stage 1B is complete only when all tests below pass on a real txAdmin/FiveM deployment.

## 1. Automatic character selector

1. Deploy/redeploy v0.2.0 through the raw txAdmin recipe URL.
2. Join the server normally.
3. Confirm the HimotheeCore character selector opens automatically without using chat commands.
4. Confirm the player's Himothee account ID is displayed.
5. Confirm every existing character belonging to that account appears as a card.

## 2. Existing character load

1. Select an existing character.
2. Confirm the UI closes.
3. Confirm the character spawns and controls return.
4. Run `/himowhoami` and confirm it matches the selected card.

## 3. Character creation

1. Return to the selector with `/switchcharacter`.
2. Create a second character using the UI.
3. Confirm it occupies the next free slot.
4. Confirm the original character remains unchanged.
5. Select the new character and confirm `/himowhoami` matches it.

## 4. Slot limit

1. Create characters until `himo:maxCharacters` is reached.
2. Confirm the Create button becomes unavailable.
3. Confirm a direct server event cannot create a fifth character beyond the configured limit.

## 5. Last-location persistence

1. Load a character.
2. Move to a clearly different location.
3. Wait at least `himo:autoSaveMs` (default 60 seconds).
4. Disconnect and reconnect.
5. Select the same character.
6. Confirm the character returns to the saved location rather than the default spawn.

## 6. Character switching

1. While loaded as character A, run `/switchcharacter`.
2. Confirm the current position is saved before unload.
3. Confirm the selector reopens.
4. Select character B and verify its own independent position/data loads.
5. Switch back to character A and verify character A's state remains separate.

## 7. Restart persistence

1. Stop and start the server from txAdmin.
2. Reconnect.
3. Confirm the same account and characters remain available.
4. Select a character and confirm the saved position survives the restart.

## 8. Player Object smoke test

A development resource should be able to resolve:

```lua
local Player = exports.himo_core:GetPlayer(source)
assert(Player)
assert(Player.PlayerData)
assert(Player.Functions.GetIdentifier())
assert(Player.Functions.GetMoney('cash') ~= nil)
assert(Player.Functions.GetPrimaryJob())
```

## Pass criteria

Stage 1B passes when character selection, creation, switching, position persistence, restart persistence and the Player Object all work without manual SQL edits or normal-player reliance on `/himocreate` and `/himoload`.
