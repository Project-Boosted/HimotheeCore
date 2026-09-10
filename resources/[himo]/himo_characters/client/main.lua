local uiOpen = false
local spawning = false
local currentCharacter = nil

local function getConvarNumber(name, fallback)
    return tonumber(GetConvar(name, tostring(fallback))) or fallback
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
    end
end

local function takeSpawnControl()
    exports['spawnmanager']:setAutoSpawn(false)
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

local function finishSpawn(character)
    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        SetEntityVisible(ped, true, false)
        SetEntityInvincible(ped, false)
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
    DoScreenFadeIn(750)
    TriggerEvent('himo_characters:client:spawned', character)
end

local function spawnCharacter(character)
    if spawning then return end
    spawning = true

    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(0) end

    closeUi()
    takeSpawnControl()

    local spawn = resolveSpawn(character)
    local model = modelForCharacter(character)

    exports['spawnmanager']:spawnPlayer({
        x = spawn.x,
        y = spawn.y,
        z = spawn.z,
        heading = spawn.heading,
        model = model,
        skipFade = true
    }, function()
        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
        local timeout = GetGameTimer() + 5000
        while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < timeout do
            Wait(50)
        end

        finishSpawn(character)
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
    if IsScreenFadedOut() then
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
    if uiOpen then
        SetNuiFocus(false, false)
        setWaitingState(false)
    end
end)
