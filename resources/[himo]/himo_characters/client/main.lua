local selectionActive = false
local spawnInProgress = false
local previewCam = nil
local pendingCharacter = nil
local pendingIsNew = false
local spawnGeneration = 0

local preview = {
    ped = { x = 969.25, y = 72.61, z = 116.18, w = 276.55 },
    cam = { x = 972.20, y = 72.90, z = 116.68, w = 97.27 }
}

local function debugLog(message)
    if GetConvarInt('himo:debug', 0) == 1 then
        print(('[HimotheeCharacters] %s'):format(message))
    end
end

local function takeSpawnControl()
    pcall(function()
        exports['spawnmanager']:setAutoSpawn(false)
    end)
end

local function fadeOutSafe(duration)
    duration = duration or 300
    if IsScreenFadedOut() then return end

    DoScreenFadeOut(duration)
    local deadline = GetGameTimer() + math.max(1500, duration + 1000)
    while not IsScreenFadedOut() and GetGameTimer() < deadline do Wait(0) end
end

local function fadeInSafe(duration)
    duration = duration or 500
    if IsScreenFadedIn() then return end

    DoScreenFadeIn(duration)
    local deadline = GetGameTimer() + math.max(2000, duration + 1500)
    while not IsScreenFadedIn() and GetGameTimer() < deadline do Wait(0) end
end

local function destroyPreviewCamera()
    if previewCam and DoesCamExist(previewCam) then
        SetCamActive(previewCam, false)
        DestroyCam(previewCam, true)
    end
    RenderScriptCams(false, false, 300, true, true)
    ClearTimecycleModifier()
    previewCam = nil
end

local function setupPreviewCamera()
    destroyPreviewCamera()
    previewCam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        preview.cam.x, preview.cam.y, preview.cam.z,
        -6.0, 0.0, preview.cam.w,
        40.0, false, 0
    )
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 500, true, true)
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(0.65)
end

local function startTutorialSession()
    if NetworkIsInTutorialSession() then return true end

    NetworkStartSoloTutorialSession()
    local deadline = GetGameTimer() + 5000
    while not NetworkIsInTutorialSession() and GetGameTimer() < deadline do Wait(0) end

    if not NetworkIsInTutorialSession() then
        debugLog('Tutorial session did not report active within timeout; selector will continue safely.')
        return false
    end
    return true
end

local function setPreviewPedState()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    SetEntityCoordsNoOffset(ped, preview.ped.x, preview.ped.y, preview.ped.z, false, false, false, true)
    SetEntityHeading(ped, preview.ped.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    return true
end

local function previewCharacter(character)
    fadeOutSafe(150)

    local target = character or { id = 0, gender = 'male' }
    local ok, hadAppearance = pcall(function()
        return exports['himo_appearance']:PrepareCharacter(target)
    end)
    if not ok then
        debugLog(('Preview appearance failed: %s'):format(hadAppearance))
    end

    setPreviewPedState()
    fadeInSafe(250)
end

local function notifyError(message)
    lib.notify({
        title = 'HimotheeCore',
        description = tostring(message or 'Something went wrong.'),
        type = 'error'
    })
end

local function fetchCharacterList()
    local ok, payload, reason = pcall(function()
        return lib.callback.await('himo_characters:server:list', false)
    end)

    if not ok then return nil, tostring(payload) end
    if not payload then return nil, reason or 'Character list could not be loaded.' end
    return payload
end

local chooseCharacter

local function beginSpawnChoice(character, isNew)
    pendingCharacter = character
    pendingIsNew = isNew == true
    lib.hideContext(false)

    local ok, err = pcall(function()
        exports['himo_spawn']:Open(character, pendingIsNew)
    end)
    if not ok then
        notifyError(('Spawn selector failed: %s'):format(err))
        chooseCharacter()
    end
end

local function loadExistingCharacter(character)
    fadeOutSafe(150)

    local ok, loaded, reason = pcall(function()
        return lib.callback.await('himo_characters:server:load', false, character.id)
    end)

    if not ok then
        fadeInSafe(250)
        notifyError(loaded)
        return
    end
    if not loaded then
        fadeInSafe(250)
        notifyError(reason or 'Character load failed.')
        return
    end

    debugLog(('Server login accepted for %s'):format(loaded.citizen_id or '?'))
    beginSpawnChoice(loaded, false)
    fadeInSafe(250)
end

local function createCharacter()
    local dialog = lib.inputDialog('Create character', {
        { type = 'input', label = 'First name', required = true, min = 2, max = 50 },
        { type = 'input', label = 'Last name', required = true, min = 2, max = 50 },
        { type = 'date', label = 'Date of birth', required = true, format = 'YYYY-MM-DD', returnString = true, min = '1900-01-01', max = '2008-12-31' },
        {
            type = 'select',
            label = 'Gender',
            required = true,
            options = {
                { value = 'male', label = 'Male' },
                { value = 'female', label = 'Female' }
            }
        },
        { type = 'input', label = 'Nationality', required = true, default = 'British', max = 60 }
    })

    if not dialog then
        lib.showContext('himo_character_list')
        return
    end

    fadeOutSafe(150)
    local ok, character, reason = pcall(function()
        return lib.callback.await('himo_characters:server:create', false, {
            firstName = dialog[1],
            lastName = dialog[2],
            dateOfBirth = dialog[3],
            gender = dialog[4],
            nationality = dialog[5]
        })
    end)

    if not ok then
        fadeInSafe(250)
        notifyError(character)
        chooseCharacter()
        return
    end
    if not character then
        fadeInSafe(250)
        notifyError(reason or 'Character creation failed.')
        chooseCharacter()
        return
    end

    debugLog(('Created and server-loaded %s'):format(character.citizen_id or '?'))
    beginSpawnChoice(character, true)
    fadeInSafe(250)
end

local function registerCharacterMenus(payload)
    local characters = payload.characters or {}
    local maxCharacters = tonumber(payload.maxCharacters) or 4
    local bySlot = {}
    for _, character in ipairs(characters) do
        bySlot[tonumber(character.slot) or 0] = character
    end

    local options = {}
    for slot = 1, maxCharacters do
        local character = bySlot[slot]
        if character then
            local captured = character
            local contextId = ('himo_character_%s'):format(captured.id)

            lib.registerContext({
                id = contextId,
                title = ('%s %s'):format(captured.first_name or 'Unknown', captured.last_name or ''),
                menu = 'himo_character_list',
                canClose = false,
                options = {
                    {
                        title = 'Play',
                        description = 'Load this character and choose a spawn.',
                        icon = 'play',
                        onSelect = function()
                            loadExistingCharacter(captured)
                        end
                    },
                    {
                        title = 'Character details',
                        icon = 'id-card',
                        readOnly = true,
                        metadata = {
                            { label = 'Citizen ID', value = captured.citizen_id or '?' },
                            { label = 'Date of birth', value = tostring(captured.date_of_birth or 'Not set'):sub(1, 10) },
                            { label = 'Nationality', value = captured.nationality or 'Not set' },
                            { label = 'Gender', value = captured.gender or 'Not set' }
                        }
                    }
                }
            })

            options[#options + 1] = {
                title = ('Slot %d - %s %s'):format(slot, captured.first_name or 'Unknown', captured.last_name or ''),
                description = captured.citizen_id or 'Existing character',
                icon = 'user',
                onSelect = function()
                    previewCharacter(captured)
                    lib.showContext(contextId)
                end
            }
        else
            options[#options + 1] = {
                title = ('Slot %d - New Character'):format(slot),
                description = 'Create a new life in this slot.',
                icon = 'user-plus',
                onSelect = createCharacter
            }
        end
    end

    lib.registerContext({
        id = 'himo_character_list',
        title = ('HimotheeCore - Account %s'):format(payload.accountId or '?'),
        canClose = false,
        options = options
    })
end

chooseCharacter = function()
    if spawnInProgress then return end

    takeSpawnControl()
    fadeOutSafe(300)

    local payload, reason = fetchCharacterList()
    if not payload then
        notifyError(reason)
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        fadeInSafe(500)
        return
    end

    if payload.loadedCharacter and payload.worldReady then
        debugLog('Character resource started while player is already world-ready; selector skipped.')
        fadeInSafe(250)
        return
    end

    if payload.loadedCharacter and not payload.worldReady then
        pcall(function()
            lib.callback.await('himo_characters:server:logout', false)
        end)
        payload, reason = fetchCharacterList()
        if not payload then
            notifyError(reason)
            fadeInSafe(500)
            return
        end
    end

    selectionActive = true
    pendingCharacter = nil
    pendingIsNew = false

    startTutorialSession()

    local firstCharacter = payload.characters and payload.characters[1] or nil
    local ok, previewResult = pcall(function()
        return exports['himo_appearance']:PrepareCharacter(firstCharacter or { id = 0, gender = 'male' })
    end)
    if not ok then debugLog(('Initial preview model failed: %s'):format(previewResult)) end

    setPreviewPedState()
    setupPreviewCamera()
    DisplayRadar(false)

    registerCharacterMenus(payload)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    fadeInSafe(500)
    lib.showContext('himo_character_list')
end

local function nativeSpawnFallback(coords)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.w or 0.0, true, true, false)
    SetEntityHeading(PlayerPedId(), coords.w or 0.0)
    return true
end

local function finishWorldEntry(character, isNew, generation)
    if generation ~= spawnGeneration then return end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    ClearPlayerWantedLevel(PlayerId())
    DisplayRadar(true)

    local health = tonumber(character.health)
    local armour = tonumber(character.armour)
    if health and health >= 100 then SetEntityHealth(ped, math.floor(health)) end
    if armour and armour >= 0 then SetPedArmour(ped, math.floor(armour)) end

    TriggerServerEvent('himo_core:server:finishLogin')

    local readyDeadline = GetGameTimer() + 5000
    while not exports['himo_core']:IsPlayerLoaded() and GetGameTimer() < readyDeadline do Wait(50) end
    if not exports['himo_core']:IsPlayerLoaded() then
        debugLog('World-ready acknowledgement timed out; forcing tutorial cleanup locally.')
        exports['himo_core']:EndTutorialSession()
    end

    selectionActive = false
    spawnInProgress = false
    pendingCharacter = nil
    pendingIsNew = false

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    fadeInSafe(500)

    debugLog(('World entry complete for %s at %.2f %.2f %.2f'):format(
        character.citizen_id or '?',
        GetEntityCoords(PlayerPedId()).x,
        GetEntityCoords(PlayerPedId()).y,
        GetEntityCoords(PlayerPedId()).z
    ))

    TriggerEvent('himo_characters:client:spawned', character)

    if isNew then
        Wait(500)
        local ok, err = pcall(function()
            exports['himo_appearance']:OpenEditor(character, true)
        end)
        if not ok then
            debugLog(('Initial clothing editor failed: %s'):format(err))
            lib.notify({ title = 'HimotheeCore', description = 'Use /himoappearance to edit your clothing.', type = 'warning' })
        end
    end
end

local function spawnSelectedCharacter(selection)
    if spawnInProgress or not pendingCharacter then return end

    local character = pendingCharacter
    local isNew = pendingIsNew
    local coords = {
        x = tonumber(selection.x) or 215.76,
        y = tonumber(selection.y) or -810.12,
        z = tonumber(selection.z) or 30.73,
        w = tonumber(selection.w) or 157.0
    }

    spawnInProgress = true
    spawnGeneration = spawnGeneration + 1
    local generation = spawnGeneration

    fadeOutSafe(400)
    lib.hideContext(false)
    destroyPreviewCamera()
    takeSpawnControl()

    local ok, hadAppearance = pcall(function()
        return exports['himo_appearance']:PrepareCharacter(character)
    end)
    if not ok then
        debugLog(('Final appearance preparation failed: %s'):format(hadAppearance))
    end

    local completed = false
    local function complete()
        if completed or generation ~= spawnGeneration then return end
        completed = true
        finishWorldEntry(character, isNew, generation)
    end

    local spawnOk, spawnErr = pcall(function()
        exports['spawnmanager']:spawnPlayer({
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = coords.w,
            skipFade = true
        }, complete)
    end)

    if not spawnOk then
        debugLog(('spawnmanager call failed: %s'):format(spawnErr))
        nativeSpawnFallback(coords)
        complete()
        return
    end

    CreateThread(function()
        Wait(8000)
        if completed or generation ~= spawnGeneration then return end
        debugLog('spawnmanager callback timeout; using bounded native fallback.')
        nativeSpawnFallback(coords)
        complete()
    end)
end

AddEventHandler('himo_spawn:client:selected', spawnSelectedCharacter)

RegisterCommand('switchcharacter', function()
    if spawnInProgress then return end
    CreateThread(function()
        fadeOutSafe(250)
        local ok, success, reason = pcall(function()
            return lib.callback.await('himo_characters:server:logout', false)
        end)
        if not ok or not success then
            notifyError(ok and (reason or 'Could not unload character.') or success)
            fadeInSafe(250)
            return
        end
        chooseCharacter()
    end)
end, false)

CreateThread(function()
    takeSpawnControl()
    while not NetworkIsSessionStarted() do Wait(100) end
    Wait(250)
    chooseCharacter()
end)

CreateThread(function()
    while true do
        if selectionActive then
            local ped = PlayerPedId()
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                SetEntityInvincible(ped, true)
            end
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    spawnGeneration = spawnGeneration + 1
    destroyPreviewCamera()
    lib.hideContext(false)
    SetNuiFocus(false, false)
    DisplayRadar(true)

    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
    end

    if IsScreenFadedOut() then DoScreenFadeIn(0) end
end)
