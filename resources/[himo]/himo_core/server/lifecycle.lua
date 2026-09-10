HimoReadyPlayers = HimoReadyPlayers or {}

local function sourceKey(source)
    return tonumber(source) or source
end

local function setReadyState(source, ready)
    source = sourceKey(source)
    HimoReadyPlayers[source] = ready == true or nil

    HimoState.setPlayer(source, 'himo:playerLoaded', ready == true)

    -- Legacy v0.3.x state key retained during the Stage 1 transition.
    local player = Player(source)
    if player and player.state then
        player.state:set('himoPlayerLoaded', ready == true, true)
    end
end

AddEventHandler('himo_core:server:characterLoaded', function(source, character)
    setReadyState(source, false)
    HimoSessions.attachCharacter(source, character and character.id or nil)
end)

AddEventHandler('himo_core:server:characterUnloaded', function(source)
    setReadyState(source, false)
    HimoSessions.attachCharacter(source, nil)
end)

AddEventHandler('playerDropped', function()
    HimoReadyPlayers[sourceKey(source)] = nil
end)

RegisterNetEvent('himo_core:server:finishLogin', function()
    local source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then
        HimoLogger.error(('finishLogin rejected for source %s: no character loaded'):format(source))
        return
    end

    if HimoReadyPlayers[source] then return end

    setReadyState(source, true)
    HimoSessions.attachCharacter(source, character.id)

    TriggerClientEvent('himo_core:client:playerLoaded', source, character)
    TriggerEvent('himo_core:server:playerLoaded', source, character)

    HimoLogger.debug(('Player world-ready: source %s -> %s'):format(source, character.citizen_id))
end)

exports('IsPlayerLoaded', function(source)
    return HimoReadyPlayers[sourceKey(source)] == true
end)
