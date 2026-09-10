HimoReadyPlayers = HimoReadyPlayers or {}

local function setReadyState(source, ready)
    source = tonumber(source) or source
    HimoReadyPlayers[source] = ready == true or nil

    local player = Player(source)
    if player and player.state then
        player.state:set('himoPlayerLoaded', ready == true, true)
    end
end

AddEventHandler('himo_core:server:characterLoaded', function(source)
    setReadyState(source, false)
end)

AddEventHandler('himo_core:server:characterUnloaded', function(source)
    setReadyState(source, false)
end)

AddEventHandler('playerDropped', function()
    HimoReadyPlayers[tonumber(source) or source] = nil
end)

RegisterNetEvent('himo_core:server:finishLogin', function()
    local source = tonumber(source) or source
    local character = HimoPlayers[source]
    if not character then
        HimoLogger.error(('finishLogin rejected for source %s: no character loaded'):format(source))
        return
    end

    if HimoReadyPlayers[source] then return end

    setReadyState(source, true)

    TriggerClientEvent('himo_core:client:playerLoaded', source, character)
    TriggerEvent('himo_core:server:playerLoaded', source, character)

    HimoLogger.debug(('Player world-ready: source %s -> %s'):format(source, character.citizen_id))
end)

exports('IsPlayerLoaded', function(source)
    return HimoReadyPlayers[tonumber(source) or source] == true
end)
