local customizationOpen = false

local function waitForAppearanceResource()
    local timeout = GetGameTimer() + 15000
    while GetResourceState('illenium-appearance') ~= 'started' and GetGameTimer() < timeout do
        Wait(100)
    end
    return GetResourceState('illenium-appearance') == 'started'
end

local function modelForGender(gender)
    gender = tostring(gender or ''):lower()
    if gender == 'female' or gender == 'f' or gender == 'woman' or gender == '1' then
        return 'mp_f_freemode_01'
    end
    return 'mp_m_freemode_01'
end

local function applyDefaultModel(gender)
    if not waitForAppearanceResource() then return false end

    local ok = pcall(function()
        exports['illenium-appearance']:setPlayerModel(modelForGender(gender))
    end)

    if not ok then return false end

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    ClearPedDecorations(ped)
    return true
end

local function applyAppearance(appearance)
    if type(appearance) ~= 'table' then return false end
    if not waitForAppearanceResource() then return false end

    local ok, err = pcall(function()
        exports['illenium-appearance']:setPlayerAppearance(appearance)
    end)

    if not ok then
        print(('[HimotheeAppearance] Failed to apply appearance: %s'):format(err))
        return false
    end

    return true
end

local function getOwnedAppearance(characterId)
    local ok, appearance = pcall(function()
        return lib.callback.await('himo_appearance:server:getPreview', false, characterId)
    end)

    if not ok then
        print(('[HimotheeAppearance] Preview lookup failed: %s'):format(appearance))
        return nil
    end

    return appearance
end

local function prepareCharacter(character)
    if type(character) ~= 'table' then return false end

    local appearance = getOwnedAppearance(character.id)
    if appearance and applyAppearance(appearance) then
        return true
    end

    applyDefaultModel(character.gender)
    return false
end

local function currentAppearance()
    local ok, appearance = pcall(function()
        return lib.callback.await('himo_appearance:server:getCurrent', false)
    end)

    if not ok then
        print(('[HimotheeAppearance] Current appearance lookup failed: %s'):format(appearance))
        return nil
    end

    return appearance
end

local function fullCharacterConfig()
    return {
        ped = true,
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

local function saveAppearance(appearance)
    local ok, saved, reason = pcall(function()
        return lib.callback.await('himo_appearance:server:save', false, appearance)
    end)

    if not ok then
        return false, tostring(saved)
    end

    return saved == true, reason
end

local function startInitialCustomization(gender)
    if customizationOpen then return false end
    if not waitForAppearanceResource() then
        lib.notify({
            title = 'HimotheeCore',
            description = 'Appearance editor is not available.',
            type = 'error'
        })
        return false
    end

    customizationOpen = true
    applyDefaultModel(gender)

    if not IsScreenFadedIn() then
        DoScreenFadeIn(500)
        local timeout = GetGameTimer() + 2000
        while not IsScreenFadedIn() and GetGameTimer() < timeout do Wait(0) end
    end

    local ok, err = pcall(function()
        exports['illenium-appearance']:startPlayerCustomization(function(appearance)
            customizationOpen = false

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
                    description = reason or 'Could not save your appearance.',
                    type = 'error'
                })
                return
            end

            lib.notify({
                title = 'HimotheeCore',
                description = 'Appearance saved.',
                type = 'success'
            })
        end, fullCharacterConfig())
    end)

    if not ok then
        customizationOpen = false
        print(('[HimotheeAppearance] Customization failed to start: %s'):format(err))
        lib.notify({
            title = 'HimotheeCore',
            description = 'Appearance editor failed to open. Gameplay can continue; use /himoappearance to retry.',
            type = 'error'
        })
        return false
    end

    return true
end

local function loadCurrent()
    local appearance = currentAppearance()
    if not appearance then return false end
    return applyAppearance(appearance)
end

exports('PrepareCharacter', prepareCharacter)
exports('ApplyAppearance', applyAppearance)
exports('LoadCurrent', loadCurrent)
exports('StartInitialCustomization', startInitialCustomization)

RegisterCommand('himoappearance', function()
    if customizationOpen then return end

    local character = exports['himo_core']:GetCharacter()
    if not character then
        lib.notify({
            title = 'HimotheeCore',
            description = 'Load a character before opening appearance.',
            type = 'error'
        })
        return
    end

    startInitialCustomization(character.gender)
end, false)
