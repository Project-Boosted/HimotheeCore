local creatorOpen = false

local function debugLog(message)
    if GetConvarInt('himo:debug', 0) == 1 then
        print(('[HimotheeAppearance] %s'):format(message))
    end
end

local function fullCharacterConfig()
    return {
        ped = false,
        headBlend = true,
        faceFeatures = true,
        headOverlays = true,
        components = true,
        componentConfig = {
            masks = true,
            upperBody = true,
            lowerBody = true,
            bags = true,
            shoes = true,
            scarfAndChains = true,
            bodyArmor = true,
            shirts = true,
            decals = true,
            jackets = true
        },
        props = true,
        propConfig = {
            hats = true,
            glasses = true,
            ear = true,
            watches = true,
            bracelets = true
        },
        tattoos = true,
        enableExit = false,
        hasTracker = false,
        automaticFade = false
    }
end

local function getCurrentAppearance()
    local ok, appearance = pcall(function()
        return lib.callback.await('himo_appearance:server:getCurrent', false)
    end)

    if not ok then
        debugLog(('Automatic creator appearance lookup failed: %s'):format(appearance))
        return nil
    end

    return appearance
end

local function saveAppearance(appearance)
    local ok, saved, reason = pcall(function()
        return lib.callback.await('himo_appearance:server:save', false, appearance)
    end)

    if not ok then
        return false, tostring(saved)
    end

    return saved == true, reason
end

local function resetRoutingBucket()
    TriggerServerEvent('illenium-appearance:server:ResetRoutingBucket')
end

local function openDirectCreator(character)
    if creatorOpen then return false end
    if GetResourceState('illenium-appearance') ~= 'started' then
        debugLog('Automatic creator skipped because illenium-appearance is not started.')
        return false
    end

    creatorOpen = true

    -- Re-apply the correct freemode gender model before handing the ped to
    -- Illenium. For a new character there is intentionally no saved appearance.
    pcall(function()
        exports['himo_appearance']:PrepareCharacter(character)
    end)

    if not IsScreenFadedIn() then
        DoScreenFadeIn(300)
        local deadline = GetGameTimer() + 2500
        while not IsScreenFadedIn() and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    -- Illenium uses a private routing bucket during first-character creation.
    -- These events are part of Illenium's generic resource, not its QB adapter.
    TriggerServerEvent('illenium-appearance:server:ChangeRoutingBucket')

    debugLog(('Opening direct Illenium creator for %s'):format(character.citizen_id or '?'))

    local ok, err = pcall(function()
        exports['illenium-appearance']:startPlayerCustomization(function(appearance)
            CreateThread(function()
                creatorOpen = false
                resetRoutingBucket()

                if not appearance then
                    lib.notify({
                        title = 'HimotheeCore',
                        description = 'Character appearance was not saved. Use /himoappearance to try again.',
                        type = 'warning'
                    })
                    return
                end

                local saved, reason = saveAppearance(appearance)
                if not saved then
                    lib.notify({
                        title = 'HimotheeCore',
                        description = reason or 'Could not save your character appearance.',
                        type = 'error'
                    })
                    return
                end

                debugLog(('Direct Illenium appearance saved for %s'):format(character.citizen_id or '?'))
                lib.notify({
                    title = 'HimotheeCore',
                    description = 'Character appearance saved.',
                    type = 'success'
                })
                TriggerEvent('himo_appearance:client:saved')
            end)
        end, fullCharacterConfig())
    end)

    if not ok then
        creatorOpen = false
        resetRoutingBucket()
        debugLog(('Direct Illenium creator failed to start: %s'):format(err))
        lib.notify({
            title = 'HimotheeCore',
            description = 'Automatic appearance creator failed to open. Use /himoappearance to retry.',
            type = 'error'
        })
        return false
    end

    return true
end

-- The reliable first-character test is persistent state, not a transient
-- client flag. Any loaded character without a saved Himothee appearance gets
-- the creator once. After saving, future spawns skip this path automatically.
AddEventHandler('himo_characters:client:spawned', function(character)
    if type(character) ~= 'table' then return end

    CreateThread(function()
        Wait(1200)

        if creatorOpen then return end
        if not exports['himo_core']:IsPlayerLoaded() then return end
        if getCurrentAppearance() then
            debugLog(('Appearance already exists for %s; automatic creator skipped.'):format(character.citizen_id or '?'))
            return
        end

        openDirectCreator(character)
    end)
end)

RegisterCommand('himofirstappearance', function()
    local character = exports['himo_core']:GetCharacter()
    if not character then
        lib.notify({ title = 'HimotheeCore', description = 'Load a character first.', type = 'error' })
        return
    end

    openDirectCreator(character)
end, false)
