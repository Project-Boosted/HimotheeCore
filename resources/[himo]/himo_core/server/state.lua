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
    GlobalState['himothee_core:stage'] = '1C'
    GlobalState['himothee_core:build'] = 'core-services'
    GlobalState['himothee_core:ready'] = ready == true
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

exports('SetPlayerState', HimoState.setPlayer)
exports('GetPlayerState', HimoState.getPlayer)
