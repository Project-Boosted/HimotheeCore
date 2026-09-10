local worldReady = false

local function debugLog(message)
    if GetConvarInt('himo:debug', 0) == 1 then
        print(('[HimotheeCore] %s'):format(message))
    end
end

local function endTutorialSession()
    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
        local deadline = GetGameTimer() + 5000
        while NetworkIsInTutorialSession() and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    return not NetworkIsInTutorialSession()
end

RegisterNetEvent('himo_core:client:playerLoaded', function(character)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    local tutorialEnded = endTutorialSession()
    if not tutorialEnded then
        debugLog('Tutorial session did not end within timeout; continuing with recovery state.')
    end

    worldReady = true
    TriggerEvent('himo_core:client:onPlayerLoaded', character)
    debugLog(('Player world-ready: %s'):format(character and character.citizen_id or 'unknown'))
end)

RegisterNetEvent('himo_core:client:characterUnloaded', function()
    worldReady = false
    TriggerEvent('himo_core:client:onPlayerUnload')
end)

exports('IsPlayerLoaded', function()
    return worldReady
end)

exports('EndTutorialSession', endTutorialSession)
