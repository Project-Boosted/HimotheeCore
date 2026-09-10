# HimotheeCore v0.4.0 - Stage 1C acceptance test

Stage 1C must preserve the proven v0.3.2 character/spawn/Illenium flow while validating the new framework services.

## 1. Deployment and schema

Deploy with the normal raw txAdmin recipe and confirm it reports v0.4.0. The recipe must apply `004_stage1c_core_services.sql` and the core console should report schema 3.

## 2. Existing lifecycle regression

Join an existing character. Confirm:

- character preview works
- spawn selector works
- saved Illenium appearance reloads
- the world becomes controllable normally
- `/switchcharacter` still returns to the selector
- a new character still auto-opens Illenium when no saved appearance exists

## 3. Runtime self-test

As a txAdmin/admin player run:

    /himostage
    /himocoretest

Expected:

    HimotheeCore v0.4.0 | Stage 1C | schema 3 | ready=true
    CORE TEST PASS ...

## 4. Metadata

Run:

    /himostatus

Expected defaults for a new/unmodified character include hunger 100, thirst 100 and stress 0.

As admin, set a safe test value:

    /himometadata <serverId> stress 25
    /himostatus

Stress should become 25. Switch characters and reload the original character; it must remain 25.

## 5. Job and duty

For the seeded unemployed job:

    /himoplayer
    /himoduty on
    /himostatus
    /himoduty off

The Player Object should show `unemployed`, and duty should change without replacing the job.

To test additional jobs, insert a job + grade definition first or wait for the native jobs package. `/himosetjob` and `/himoaddjob` reject undefined jobs/grades by design.

## 6. Groups

Schema v3 seeds the neutral `none` gang definition. Admins can test:

    /himosetgroup <serverId> none 0
    /himodebugplayer <serverId>

The group API should remain valid and the QB bridge should expose the neutral gang shape. Real gang/group definitions will be supplied by later gameplay resources.

## 7. Session ownership

While one client is connected, attempting to join the same server simultaneously with the same Himothee account should be rejected with an already-connected message. Normal disconnect/reconnect must work immediately afterwards.

`himo_player_sessions` should record the session and receive an `ended_at` value when it closes normally.

## 8. txAdmin restart save

Move to a clearly different location, then restart the server through txAdmin. Reconnect, choose Last Location and verify the character returns to the saved area. This validates the `txAdmin:events:serverShuttingDown` save path.

## 9. QB/Illenium regression

Run:

    /himoappearance

Illenium must still open. Save a visible appearance change, switch character, reload, and verify it persists.

## Pass criteria

Stage 1C passes when all of the following hold together:

- existing character/spawn/appearance flow has no regression
- schema 3 loads
- `/himocoretest` passes
- metadata persists
- job/duty state updates
- group API loads
- duplicate sessions are blocked
- txAdmin restart saves position
- Illenium persistence remains intact
