# HimotheeCore v0.4.0 API

v0.4.0 keeps the proven v0.3.x multicharacter/spawn/appearance lifecycle and adds the framework services that jobs, activities, skills and businesses will build on.

## Lifecycle states

Character data loaded and player world-ready are intentionally separate states.

Server exports:

- `exports.himo_core:GetAccountId(source)`
- `exports.himo_core:EnsureAccount(source)`
- `exports.himo_core:GetPlayer(source)`
- `exports.himo_core:GetCharacter(source)`
- `exports.himo_core:GetCharacterId(source)`
- `exports.himo_core:GetCharacters(source)`
- `exports.himo_core:IsPlayerLoaded(source)`
- `exports.himo_core:GetSession(source)`

Client exports:

- `exports.himo_core:GetCharacter()`
- `exports.himo_core:GetCharacterId()`
- `exports.himo_core:IsCharacterLoaded()`
- `exports.himo_core:IsPlayerLoaded()`

Global state:

- `GlobalState['himothee_core:version']`
- `GlobalState['himothee_core:stage']`
- `GlobalState['himothee_core:build']`
- `GlobalState['himothee_core:ready']`

Replicated player state includes `himo:characterId`, `himo:citizenId`, `himo:characterLoaded`, `himo:playerLoaded`, `himo:job`, `himo:onDuty`, `himo:group` and the safe `himo:metadata` snapshot.

## Player Object

```lua
local Player = exports.himo_core:GetPlayer(source)
if not Player then return end

local citizenId = Player.Functions.GetIdentifier()
local cash = Player.Functions.GetMoney('cash')
local job = Player.Functions.GetPrimaryJob()
local gang = Player.Functions.GetPrimaryGroup('gang')
local stress = Player.Functions.GetMetadata('stress', 0)
```

Player methods:

- `GetData()`
- `GetIdentifier()`
- `GetCharacterId()`
- `IsLoaded()`
- `GetMoney(accountType)`
- `AddMoney(accountType, amount, reason, reference)`
- `RemoveMoney(accountType, amount, reason, reference)`
- `GetMetadata(key, default)`
- `SetMetadata(key, value)`
- `AddMetadata(key, amount, minimum, maximum)`
- `GetJobs()`
- `GetPrimaryJob()`
- `SetJob(jobName, grade)`
- `AddJob(jobName, grade, makePrimary)`
- `RemoveJob(jobName)`
- `SetPrimaryJob(jobName)`
- `SetJobGrade(jobName, grade)`
- `SetDuty(onDuty, jobName)`
- `GetGroups()`
- `GetPrimaryGroup(groupType)`
- `SetGroup(groupName, grade)`
- `AddGroup(groupName, grade, makePrimary)`
- `RemoveGroup(groupName)`
- `SetPrimaryGroup(groupName)`
- `SetGroupGrade(groupName, grade)`
- `SavePosition(position)`
- `Save()`

## Metadata

Server:

- `exports.himo_core:GetMetadata(source, key, default)`
- `exports.himo_core:SetMetadata(source, key, value)`
- `exports.himo_core:AddMetadata(source, key, amount, minimum, maximum)`

Client:

- `exports.himo_core:GetMetadata(key, default)`

Default v0.4.0 gameplay metadata: `hunger=100`, `thirst=100`, `stress=0`, `isdead=false`, `inlaststand=false`, `ishandcuffed=false`, `tracker=false`.

Only keys explicitly listed in `HimoConfig.ReplicatedMetadata` are placed into the replicated `himo:metadata` statebag. Other metadata remains server-authoritative.

## Jobs

Server exports:

- `GetJobs(source)`
- `GetPrimaryJob(source)`
- `AddJob(source, jobName, grade, makePrimary)`
- `RemoveJob(source, jobName)`
- `SetPrimaryJob(source, jobName)`
- `SetJobGrade(source, jobName, grade)`
- `SetJobDuty(source, jobName, onDuty)`

The database can hold multiple jobs per character. One job is primary; duty is stored per job.

Client exports:

- `GetJobs()`
- `GetPrimaryJob()`

Events:

- server: `himo_core:server:jobsChanged(source, jobs, primaryJob)`
- client: `himo_core:client:onJobsChanged(jobs, primaryJob)`

## Groups / gangs

Groups are a generic membership layer for gangs, factions, clubs and crews. Businesses/organisations remain a separate richer system.

Server exports:

- `GetGroups(source)`
- `GetPrimaryGroup(source, groupType)`
- `AddGroup(source, groupName, grade, makePrimary)`
- `RemoveGroup(source, groupName)`
- `SetPrimaryGroup(source, groupName)`
- `SetGroupGrade(source, groupName, grade)`

Client exports:

- `GetGroups()`
- `GetPrimaryGroup()`

## Framework callbacks

Himothee callbacks are automatically namespaced with `himo:` unless the caller already supplies the prefix.

Server resource:

```lua
exports.himo_core:RegisterServerCallback('contracts:get', function(source, contractId)
    return { id = contractId }
end)
```

Client:

```lua
local contract = exports.himo_core:AwaitServerCallback('contracts:get', 42)
```

Available exports:

- server `RegisterServerCallback(name, handler)`
- server `AwaitClientCallback(name, source, ...)`
- client `AwaitServerCallback(name, ...)`
- client `RegisterClientCallback(name, handler)`

## Permissions and commands

- `exports.himo_core:HasPermission(source, permission)`
- `exports.himo_core:HasAnyPermission(source, permissions)`
- `exports.himo_core:RegisterFrameworkCommand(name, options, handler)`

Permissions use ACE and are automatically normalised to the `himo.*` namespace.

## Saving

- `SaveCharacterPosition(source, position)`
- `SavePlayerPosition(source)`
- `SaveAllPlayers(reason)`

Position saving runs periodically, on disconnect, on character switch, and on the txAdmin `serverShuttingDown` lifecycle event. Money/jobs/groups/metadata are written immediately when changed.

## Character / spawn / appearance

Existing Stage 1B APIs remain available:

- `CreateCharacter(source, data)`
- `LoadCharacter(source, characterId)`
- `UnloadCharacter(source)`
- `exports.himo_spawn:Open(character, isNewCharacter)`
- `exports.himo_appearance:PrepareCharacter(character)`
- `exports.himo_appearance:ApplyAppearance(appearance)`
- `exports.himo_appearance:LoadCurrent()`
- `exports.himo_appearance:CaptureAppearance()`
- `exports.himo_appearance:OpenEditor(character, required)`

## Lifecycle events

Server:

- `himo_core:server:characterLoaded(source, character)`
- `himo_core:server:characterUnloaded(source, character)`
- `himo_core:server:playerLoaded(source, character)`
- `himo_core:server:metadataChanged(source, key, value, previous)`
- `himo_core:server:moneyChanged(...)`
- `himo_core:server:jobsChanged(...)`
- `himo_core:server:groupsChanged(...)`

Client:

- `himo_core:client:characterLoaded(character)`
- `himo_core:client:characterUnloaded()`
- `himo_core:client:onPlayerLoaded(character)`
- `himo_core:client:onPlayerUnload()`
- `himo_core:client:onMoneyChanged(...)`
- `himo_core:client:onMetadataChanged(key, value)`
- `himo_core:client:onJobsChanged(jobs, primaryJob)`
- `himo_core:client:onGroupsChanged(groups, primaryGroup)`

Resources that require a fully spawned player should initialise from `himo_core:server:playerLoaded` / `himo_core:client:onPlayerLoaded`, not merely `characterLoaded`.

## QB compatibility bridge

`himo_qb_bridge` remains deliberately limited. v0.4.0 maps the commonly required player-data, money, metadata, job/duty, gang/group, player lookup, permission and QB callback APIs onto native HimotheeCore services. Unsupported QB APIs should not be assumed to exist until a native Himothee equivalent is implemented and tested.
