local fallbackEditorOpen = false
local currentModelName = 'mp_m_freemode_01'

local function debugLog(message)
    if GetConvarInt('himo:debug', 0) == 1 then
        print(('[HimotheeAppearance] %s'):format(message))
    end
end

local function illeniumReady()
    return GetResourceState('illenium-appearance') == 'started'
end

local function modelForGender(gender)
    gender = tostring(gender or ''):lower()
    if gender == 'female' or gender == 'f' or gender == 'woman' or gender == '1' then
        return 'mp_f_freemode_01'
    end
    return 'mp_m_freemode_01'
end

local function loadModel(model, timeoutMs)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelInCdimage(model) or not IsModelValid(model) then return nil end

    RequestModel(model)
    local deadline = GetGameTimer() + (timeoutMs or 10000)
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        RequestModel(model)
        Wait(0)
    end

    return HasModelLoaded(model) and model or nil
end

local function setPlayerModel(modelName)
    modelName = tostring(modelName or 'mp_m_freemode_01')

    if illeniumReady() then
        local ok = pcall(function()
            exports['illenium-appearance']:setPlayerModel(modelName)
        end)
        if ok then
            currentModelName = modelName
            return true
        end
    end

    local model = loadModel(modelName, 10000)
    if not model then
        debugLog(('Model failed to load: %s'):format(modelName))
        return false
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    Wait(0)
    currentModelName = modelName
    return true
end

local function applyDefaultModel(gender)
    local modelName = modelForGender(gender)
    if not setPlayerModel(modelName) then return false end

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    ClearAllPedProps(ped)
    ClearPedDecorations(ped)
    return true
end

local function nativeCaptureAppearance()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end

    local appearance = {
        version = 1,
        model = currentModelName,
        components = {},
        props = {}
    }

    for componentId = 0, 11 do
        appearance.components[#appearance.components + 1] = {
            component_id = componentId,
            drawable = GetPedDrawableVariation(ped, componentId),
            texture = GetPedTextureVariation(ped, componentId),
            palette = GetPedPaletteVariation(ped, componentId)
        }
    end

    for propId = 0, 7 do
        appearance.props[#appearance.props + 1] = {
            prop_id = propId,
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId)
        }
    end

    return appearance
end

local function captureAppearance()
    if illeniumReady() then
        local ok, appearance = pcall(function()
            return exports['illenium-appearance']:getPedAppearance(PlayerPedId())
        end)
        if ok and type(appearance) == 'table' then
            currentModelName = tostring(appearance.model or currentModelName)
            return appearance
        end
    end

    return nativeCaptureAppearance()
end

local function nativeApplyAppearance(appearance)
    local modelName = tostring(appearance.model or currentModelName)
    if not setPlayerModel(modelName) then return false end

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    ClearAllPedProps(ped)

    if type(appearance.components) == 'table' then
        for _, component in ipairs(appearance.components) do
            local id = tonumber(component.component_id)
            local drawable = tonumber(component.drawable)
            local texture = tonumber(component.texture) or 0
            local palette = tonumber(component.palette) or 0
            if id and drawable then
                SetPedComponentVariation(ped, id, drawable, texture, palette)
            end
        end
    end

    if type(appearance.props) == 'table' then
        for _, prop in ipairs(appearance.props) do
            local id = tonumber(prop.prop_id)
            local drawable = tonumber(prop.drawable)
            local texture = tonumber(prop.texture) or 0
            if id and drawable then
                if drawable < 0 then
                    ClearPedProp(ped, id)
                else
                    SetPedPropIndex(ped, id, drawable, texture, true)
                end
            end
        end
    end

    return true
end

local function applyAppearance(appearance)
    if type(appearance) ~= 'table' then return false end

    if illeniumReady() then
        local ok, err = pcall(function()
            exports['illenium-appearance']:setPlayerAppearance(appearance)
        end)
        if ok then
            currentModelName = tostring(appearance.model or currentModelName)
            return true
        end
        debugLog(('Illenium apply failed, using native fallback: %s'):format(err))
    end

    return nativeApplyAppearance(appearance)
end

local function getOwnedAppearance(characterId)
    local ok, appearance = pcall(function()
        return lib.callback.await('himo_appearance:server:getPreview', false, characterId)
    end)

    if not ok then
        debugLog(('Preview lookup failed: %s'):format(appearance))
        return nil
    end

    return appearance
end

local function prepareCharacter(character)
    if type(character) ~= 'table' then return false end

    local appearance = character.id and tonumber(character.id) and tonumber(character.id) > 0
        and getOwnedAppearance(character.id) or nil

    if appearance and applyAppearance(appearance) then
        return true
    end

    applyDefaultModel(character.gender)
    return false
end

local function saveCapturedAppearance()
    local appearance = captureAppearance()
    if not appearance then return false, 'Player ped is unavailable.' end

    local ok, saved, reason = pcall(function()
        return lib.callback.await('himo_appearance:server:save', false, appearance)
    end)

    if not ok then return false, tostring(saved) end
    return saved == true, reason
end

local function randomiseFallbackClothes()
    local ped = PlayerPedId()
    for _, componentId in ipairs({ 3, 4, 6, 8, 11 }) do
        local count = GetNumberOfPedDrawableVariations(ped, componentId)
        if count and count > 0 then
            local drawable = math.random(0, count - 1)
            local textures = GetNumberOfPedTextureVariations(ped, componentId, drawable)
            local texture = textures and textures > 0 and math.random(0, textures - 1) or 0
            SetPedComponentVariation(ped, componentId, drawable, texture, 0)
        end
    end
end

local function openFallbackEditor(character, required)
    if fallbackEditorOpen then return false end
    fallbackEditorOpen = true

    local function showMenu()
        lib.registerContext({
            id = 'himo_appearance_fallback',
            title = required and 'Create your appearance' or 'Edit appearance',
            canClose = not required,
            onExit = function()
                fallbackEditorOpen = false
            end,
            options = {
                {
                    title = 'Randomise outfit',
                    description = 'Illenium Appearance is unavailable; use the Himothee fallback clothing generator.',
                    icon = 'dice',
                    onSelect = function()
                        randomiseFallbackClothes()
                        showMenu()
                    end
                },
                {
                    title = 'Reset clothing',
                    icon = 'rotate-left',
                    onSelect = function()
                        applyDefaultModel(character.gender)
                        showMenu()
                    end
                },
                {
                    title = 'Save & Finish',
                    icon = 'floppy-disk',
                    onSelect = function()
                        local saved, reason = saveCapturedAppearance()
                        if not saved then
                            lib.notify({ title = 'HimotheeCore', description = reason or 'Appearance save failed.', type = 'error' })
                            showMenu()
                            return
                        end
                        fallbackEditorOpen = false
                        lib.hideContext(false)
                        TriggerEvent('himo_appearance:client:saved')
                    end
                }
            }
        })
        lib.showContext('himo_appearance_fallback')
    end

    showMenu()
    return true
end

local function openEditor(character, required)
    if type(character) ~= 'table' then return false end

    if illeniumReady() then
        if required then
            debugLog(('Opening Illenium first-character creator for %s'):format(character.citizen_id or '?'))
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
        else
            debugLog(('Opening Illenium full appearance editor for %s'):format(character.citizen_id or '?'))
            TriggerEvent('illenium-appearance:client:openClothingShop', true)
        end
        return true
    end

    lib.notify({
        title = 'HimotheeCore',
        description = 'Illenium Appearance is unavailable. Using fallback clothing editor.',
        type = 'warning'
    })
    return openFallbackEditor(character, required)
end

local function loadCurrent()
    local ok, appearance = pcall(function()
        return lib.callback.await('himo_appearance:server:getCurrent', false)
    end)
    if not ok or not appearance then return false end
    return applyAppearance(appearance)
end

exports('PrepareCharacter', prepareCharacter)
exports('ApplyAppearance', applyAppearance)
exports('LoadCurrent', loadCurrent)
exports('CaptureAppearance', captureAppearance)
exports('OpenEditor', openEditor)

RegisterCommand('himoappearance', function()
    local character = exports['himo_core']:GetCharacter()
    if not character then
        lib.notify({ title = 'HimotheeCore', description = 'Load a character first.', type = 'error' })
        return
    end
    openEditor(character, false)
end, false)
