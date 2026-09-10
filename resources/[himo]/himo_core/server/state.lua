HimoState = HimoState or {}

local function validKey(key)
    return type(key) == 'string'
        and #key >= 6
        and #key <= 80
        and key:sub(1, 5) == 'himo:'
        and key:match('^[%w_:%-%.]+$') ~= nil
end

function HimoState.setPlayer(source, key, value, replicated)
    source = tonumber(source) or source
    if not validKey(key) then
        return false, 'State key must be a namespaced himo:* key.'
    end

    local player = Player(source)
    if not player or not player.state then
        return false, 'Player state bag is unavailable.'
    end

    player.state:set(key, value, replicated ~= false)
    return true
end

function HimoState.getPlayer(source, key)
    source = tonumber(source) or source
    if not validKey(key) then return nil end
    local player = Player(source)
    return player and player.state and player.state[key] or nil
end

function HimoState.setFrameworkReady(ready)
    GlobalState['himothee_core:version'] = HimoConfig.Version
    GlobalState['himothee_core:stage'] = HimoConfig.Stage or '1C'
    GlobalState['himothee_core:build'] = HimoConfig.Build or 'core-services'
    GlobalState['himothee_core:ready'] = ready == true
end

function HimoState.syncCharacter(source, character)
    if not character then return false end
    HimoState.setPlayer(source, 'himo:characterId', character.id)
    HimoState.setPlayer(source, 'himo:citizenId', character.citizen_id)
    HimoState.setPlayer(source, 'himo:characterLoaded', true)
    HimoState.setPlayer(source, 'himo:playerLoaded', false)
    return true
end

function HimoState.clearCharacter(source)
    HimoState.setPlayer(source, 'himo:characterId', nil)
    HimoState.setPlayer(source, 'himo:citizenId', nil)
    HimoState.setPlayer(source, 'himo:characterLoaded', false)
    HimoState.setPlayer(source, 'himo:playerLoaded', false)
    HimoState.setPlayer(source, 'himo:job', nil)
    HimoState.setPlayer(source, 'himo:onDuty', false)
    HimoState.setPlayer(source, 'himo:metadata', {})
end

AddEventHandler('himo_core:server:characterLoaded', function(source, character)
    HimoState.syncCharacter(source, character)
end)

AddEventHandler('himo_core:server:characterUnloaded', function(source)
    HimoState.clearCharacter(source)
end)

exports('SetPlayerState', HimoState.setPlayer)
exports('GetPlayerState', HimoState.getPlayer)
