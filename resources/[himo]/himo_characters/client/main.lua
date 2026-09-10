local uiOpen = false
local spawning = false
local currentCharacter = nil
local spawnGeneration = 0

local function getConvarNumber(name, fallback)
    return tonumber(GetConvar(name, tostring(fallback))) or fallback
end

local function debugLog(message)
    if GetConvarInt('himo:debug', 0) == 1 then
        print(('[HimotheeCharacters] %s'):format(message))
    end
end

local function defaultSpawn()
    return {
        x = getConvarNumber('himo:spawnX', 215.76),
        y = getConvarNumber('himo:spawnY', -810.12),
        z = getConvarNumber('himo:spawnZ', 30.73),
        heading = getConvarNumber('himo:spawnHeading', 157.0)
    }
end

local function resolveSpawn(character)
    local x = tonumber(character.position_x)
    local y = tonumber(character.position_y)
    local z = tonumber(character.position_z)
    local heading = tonumber(character.heading) or 0.0

    if not x or not y or not z or (math.abs(x) < 0.01 and math.abs(y) < 0.01 and math.abs(z) < 0.01) then
        return defaultSpawn()
    end

    return {
        x = x,
        y = y,
        z = z,
        heading = heading
    }
end

local function setWaitingState(enabled)
    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, enabled)
        SetEntityVisible(ped, not enabled, false)
        SetEntityInvincible(ped, enabled)
        if not enabled then
            SetEntityCollision(ped, true, true)
        end
    end
end

local function takeSpawnControl()
    exports['spawnmanager']:setAutoSpawn(false)
end

local function fadeOutSafe(duration)
    duration = duration or 250
    if IsScreenFadedOut() then return end

    DoScreenFadeOut(duration)
    local deadline = GetGameTimer() + math.max(1500, duration + 1000)
    while not IsScreenFadedOut() and GetGameTimer() < deadline do
        Wait(0)
    end
end

local function openUi(payload)
    uiOpen = true
    spawning = false

    takeSpawnControl()
    DoScreenFadeOut(0)
    setWaitingState(true)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'open',
        accountId = payload.accountId,
        characters = payload.characters or {},
        maxCharacters = payload.maxCharacters or 4,
        notice = payload.notice
    })
end

local function closeUi()
    uiOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
end

local function modelForCharacter(character)
    local gender = tostring(character.gender or ''):lower()
    if gender == 'female' or gender == 'f' or gender == 'woman' then
        return joaat('mp_f_freemode_01')
    end
    return joaat('mp_m_freemode_01')
end

local function loadModel(model, timeoutMs)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        return false
    end

    if HasModelLoaded(model) then
        return true
    end

    RequestModel(model)
    local deadline = GetGameTimer() + (timeoutMs or 8000)
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        RequestModel(model)
        Wait(0)
    end

    return HasModelLoaded(model)
end

local function finishSpawn(character, generation)
    if generation and generation ~= spawnGeneration then return end

    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        SetEntityVisible(ped, true, false)
        SetEntityInvincible(ped, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)

        local health = tonumber(character.health)
        local armour = tonumber(character.armour)
        if health and health >= 100 then
            SetEntityHealth(ped, math.floor(health))
        end
        if armour and armour >= 0 then
            SetPedArmour(ped, math.floor(armour))
        end
    end

    spawning = false
    currentCharacter = character
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(750)
    debugLog(('Spawn complete for %s %s at %.2f %.2f %.2f'):format(
        character.first_name or '?',
        character.last_name or '?',
        GetEntityCoords(PlayerPedId()).x,
        GetEntityCoords(PlayerPedId()).y,
        GetEntityCoords(PlayerPedId()).z
    ))
    TriggerEvent('himo_characters:client:spawned', character)
end

local function performNativeSpawn(character, generation)
    local spawn = resolveSpawn(character)
    local model = modelForCharacter(character)

    debugLog(('Starting native spawn for %s at %.2f %.2f %.2f'):format(
        character.citizen_id or '?', spawn.x, spawn.y, spawn.z
    ))

    local modelLoaded = loadModel(model, 8000)
    if generation ~= spawnGeneration then return end

    if modelLoaded then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        Wait(0)

        local ped = PlayerPedId()
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            SetPedDefaultComponentVariation(ped)
        end
    else
        debugLog('Requested freemode model did not load in time; using current player model as fallback.')
    end

    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        debugLog('Player ped was unavailable during spawn; emergency fade-in will recover the screen.')
        return
    end

    RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading, true, true, false)

    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    ClearPlayerWantedLevel(PlayerId())
    SetEntityHeading(ped, spawn.heading)

    local collisionDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < collisionDeadline do
        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
        Wait(50)
    end

    if generation ~= spawnGeneration then return end
    finishSpawn(character, generation)
end

local function spawnCharacter(character)
    if spawning then return end
    spawning = true
    spawnGeneration = spawnGeneration + 1
    local generation = spawnGeneration

    fadeOutSafe(250)
    closeUi()
    takeSpawnControl()

    -- Never allow a failed model/collision/spawn path to strand the player on a
    -- permanent black screen. This watchdog is deliberately independent from
    -- spawnmanager's internal spawnLock.
    CreateThread(function()
        Wait(12000)
        if spawning and generation == spawnGeneration then
            debugLog('Spawn watchdog fired; restoring player visibility and screen.')
            spawning = false
            currentCharacter = character
            setWaitingState(false)
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            DoScreenFadeIn(500)
            TriggerEvent('himo_characters:client:spawned', character)
        end
    end)

    CreateThread(function()
        performNativeSpawn(character, generation)
    end)
end

RegisterNetEvent('himo_characters:client:show', function(payload)
    openUi(payload or {})
end)

RegisterNetEvent('himo_characters:client:error', function(message)
    SendNUIMessage({
        action = 'error',
        message = message or 'Something went wrong.'
    })
end)

RegisterNetEvent('himo_characters:client:resume', function(character)
    currentCharacter = character
    closeUi()
    takeSpawnControl()
    setWaitingState(false)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(500)
    end
end)

RegisterNetEvent('himo_core:client:characterLoaded', function(character)
    currentCharacter = character
    spawnCharacter(character)
end)

RegisterNetEvent('himo_core:client:characterUnloaded', function()
    currentCharacter = nil
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    local characterId = tonumber(data and data.characterId)
    if not characterId then
        cb({ ok = false, error = 'Invalid character.' })
        return
    end

    TriggerServerEvent('himo_characters:server:select', characterId)
    cb({ ok = true })
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('himo_characters:server:create', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('refreshCharacters', function(_, cb)
    TriggerServerEvent('himo_characters:server:refresh')
    cb({ ok = true })
end)

RegisterCommand('switchcharacter', function()
    if spawning then return end
    TriggerServerEvent('himo_characters:server:logout')
end, false)

-- Development recovery command. This does not alter character/database data;
-- it only releases NUI/freeze/fade state if another resource leaves the client
-- visually stuck while Stage 1B is being tested.
RegisterCommand('himounblack', function()
    spawning = false
    spawnGeneration = spawnGeneration + 1
    closeUi()
    takeSpawnControl()
    setWaitingState(false)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(250)
    debugLog('Manual black-screen recovery executed.')
end, false)

-- basic-gamemode enables spawnmanager autospawn during onClientMapStart. Stage
-- 1B owns the player spawn, so reclaim control after that stock handler runs.
AddEventHandler('onClientMapStart', function()
    CreateThread(function()
        Wait(0)
        takeSpawnControl()
        if uiOpen then
            setWaitingState(true)
        end
    end)
end)

CreateThread(function()
    takeSpawnControl()

    while not NetworkIsSessionStarted() do
        Wait(100)
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    Wait(750)

    takeSpawnControl()
    TriggerServerEvent('himo_characters:server:bootstrap')
end)

CreateThread(function()
    while true do
        if uiOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push-to-talk can remain available
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    spawnGeneration = spawnGeneration + 1
    if uiOpen or spawning then
        SetNuiFocus(false, false)
        setWaitingState(false)
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        DoScreenFadeIn(0)
    end
end)
