# HimotheeCore v0.3.0 — Stage 1B Real-Server Acceptance Test

Run this test on a clean txAdmin deployment using the canonical recipe. Existing character/database data may be retained; schema migration 2 is additive.

## 1. Deployment/startup

Expected server resource order:

```text
spawnmanager
baseevents
ox_lib
oxmysql
himo_core
himo_appearance
himo_spawn
himo_characters
```

`basic-gamemode` must be stopped.

The core startup log should report schema version 2 and HimotheeCore v0.3.0.

## 2. Initial character selector

Join the server without running any Himothee chat command.

Expected:

- loading screen clears
- game does not drop straight into stock autospawn
- an `ox_lib` character menu appears
- player is in the Himothee preview location with a scripted camera
- existing characters are listed by slot
- empty slots show New Character
- no permanent black screen

## 3. Existing character

Choose an existing character, then Play.

Expected:

- server accepts the owned character
- spawn selector opens
- Last Location appears if the character has a saved position
- fixed locations are also available
- choose a spawn
- game becomes visible and controllable
- tutorial session ends
- radar is restored
- player is not frozen or invincible

Verify:

```text
/himowhoami
/himoplayer
```

## 4. World-ready boundary

After final spawn, `/himoplayer` should report a valid Player Object.

Future gameplay resources should initialize from `himo_core:server:playerLoaded` or `himo_core:client:onPlayerLoaded`, not merely the earlier character-loaded event.

## 5. New character

Use an empty slot and create a new character through the `ox_lib` input dialog.

Expected:

- first/last name, nationality, gender and DOB save correctly
- new character is server-loaded
- spawn selector opens
- after final spawn, the Himothee clothing editor opens
- Save & Finish writes a row to `himo_character_appearance`

## 6. Appearance persistence

After saving clothing:

1. disconnect
2. reconnect
3. select the same character
4. choose a spawn

Expected: saved model/components/props are reapplied.

`/himoappearance` should reopen the editor during gameplay.

## 7. Position persistence

Move to a clearly different location. Wait at least 65 seconds, disconnect, reconnect and choose Last Location.

Expected: character returns to the saved area.

Repeat once after a txAdmin full server restart.

## 8. Character switching

Run:

```text
/switchcharacter
```

Expected:

- current position saves
- character unloads
- world-ready state resets
- tutorial/preview selector returns
- another owned character can be loaded
- second character reaches gameplay normally

## 9. Failure conditions

Stage 1B does not pass if any of these occur:

- permanent black screen
- stock random autospawn before character selection
- two simultaneous spawn flows
- character selector can load another account's character
- preview/tutorial state remains active after spawn
- player remains frozen/invincible after world entry
- position or appearance fails to persist through reconnect
- SQL errors or missing schema v2 migration

## Acceptance result

Stage 1B is considered frozen only after existing-character login, new-character creation, spawn selection, world-ready transition, switching, position persistence and appearance persistence all pass on a real txAdmin server.
