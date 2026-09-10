local editorOpen = false
local currentModelName = 'mp_m_freemode_01'

local componentLabels = {
    [1] = 'Masks',
    [2] = 'Hair',
    [3] = 'Arms / Torso',
    [4] = 'Legs',
    [5] = 'Bags',
    [6] = 'Shoes',
    [7] = 'Accessories',
    [8] = 'Undershirt',
    [9] = 'Body Armour',
    [10] = 'Decals',
    [11] = 'Tops / Jackets'
}

local propLabels = {
    [0] = 'Hats',
    [1] = 'Glasses',
    [2] = 'Ears',
    [6] = 'Watches',
    [7] = 'Bracelets'
}

local function debugLog(message)
    if GetConvarInt('himo:debug', 0) == 1 then
        print(('[HimotheeAppearance] %s'):format(message))
    end
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

local function captureAppearance()
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

local function applyAppearance(appearance)
    if type(appearance) ~= 'table' then return false end

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

    local appearance = getOwnedAppearance(character.id)
    if appearance and applyAppearance(appearance) then
        return true
    end

    applyDefaultModel(character.gender)
    return false
end

local function saveAppearance()
    local appearance = captureAppearance()
    if not appearance then return false, 'Player ped is unavailable.' end

    local ok, saved, reason = pcall(function()
        return lib.callback.await('himo_appearance:server:save', false, appearance)
    end)

    if not ok then return false, tostring(saved) end
    return saved == true, reason
end

local function editComponent(componentId, label, reopen)
    local ped = PlayerPedId()
    local maxDrawable = math.max(0, GetNumberOfPedDrawableVariations(ped, componentId) - 1)
    local currentDrawable = GetPedDrawableVariation(ped, componentId)

    local drawableInput = lib.inputDialog(label, {
        {
            type = 'number',
            label = ('Drawable (0-%d)'):format(maxDrawable),
            min = 0,
            max = maxDrawable,
            default = currentDrawable,
            required = true
        }
    })

    if not drawableInput then reopen() return end
    local drawable = math.floor(tonumber(drawableInput[1]) or currentDrawable)
    SetPedComponentVariation(ped, componentId, drawable, 0, 0)

    local maxTexture = math.max(0, GetNumberOfPedTextureVariations(ped, componentId, drawable) - 1)
    local textureInput = lib.inputDialog(label .. ' texture', {
        {
            type = 'number',
            label = ('Texture (0-%d)'):format(maxTexture),
            min = 0,
            max = maxTexture,
            default = 0,
            required = true
        }
    })

    local texture = textureInput and math.floor(tonumber(textureInput[1]) or 0) or 0
    SetPedComponentVariation(ped, componentId, drawable, texture, 0)
    reopen()
end

local function editProp(propId, label, reopen)
    local ped = PlayerPedId()
    local maxDrawable = math.max(0, GetNumberOfPedPropDrawableVariations(ped, propId) - 1)
    local currentDrawable = GetPedPropIndex(ped, propId)

    local drawableInput = lib.inputDialog(label, {
        {
            type = 'number',
            label = ('Drawable (-1 clears, max %d)'):format(maxDrawable),
            min = -1,
            max = maxDrawable,
            default = currentDrawable,
            required = true
        }
    })

    if not drawableInput then reopen() return end
    local drawable = math.floor(tonumber(drawableInput[1]) or -1)
    if drawable < 0 then
        ClearPedProp(ped, propId)
        reopen()
        return
    end

    SetPedPropIndex(ped, propId, drawable, 0, true)
    local maxTexture = math.max(0, GetNumberOfPedPropTextureVariations(ped, propId, drawable) - 1)
    local textureInput = lib.inputDialog(label .. ' texture', {
        {
            type = 'number',
            label = ('Texture (0-%d)'):format(maxTexture),
            min = 0,
            max = maxTexture,
            default = 0,
            required = true
        }
    })

    local texture = textureInput and math.floor(tonumber(textureInput[1]) or 0) or 0
    SetPedPropIndex(ped, propId, drawable, texture, true)
    reopen()
end

local function randomiseClothes()
    local ped = PlayerPedId()
    local componentIds = { 3, 4, 6, 8, 11 }

    for _, componentId in ipairs(componentIds) do
        local count = GetNumberOfPedDrawableVariations(ped, componentId)
        if count and count > 0 then
            local drawable = math.random(0, count - 1)
            local textures = GetNumberOfPedTextureVariations(ped, componentId, drawable)
            local texture = textures and textures > 0 and math.random(0, textures - 1) or 0
            SetPedComponentVariation(ped, componentId, drawable, texture, 0)
        end
    end
end

local function openEditor(character, required)
    if editorOpen then return end
    editorOpen = true

    local function showMain()
        local options = {
            {
                title = 'Randomise outfit',
                description = 'Quickly generate a different clothing combination.',
                icon = 'dice',
                onSelect = function()
                    randomiseClothes()
                    showMain()
                end
            },
            {
                title = 'Reset to default clothes',
                icon = 'rotate-left',
                onSelect = function()
                    applyDefaultModel(character.gender)
                    showMain()
                end
            }
        }

        for componentId = 1, 11 do
            local label = componentLabels[componentId]
            if label then
                options[#options + 1] = {
                    title = label,
                    description = 'Choose drawable and texture IDs.',
                    icon = 'shirt',
                    onSelect = function()
                        editComponent(componentId, label, showMain)
                    end
                }
            end
        end

        for propId, label in pairs(propLabels) do
            options[#options + 1] = {
                title = label,
                description = 'Choose accessory drawable and texture IDs.',
                icon = 'glasses',
                onSelect = function()
                    editProp(propId, label, showMain)
                end
            }
        end

        options[#options + 1] = {
            title = 'Save & Finish',
            description = 'Save this clothing setup to your HimotheeCore character.',
            icon = 'floppy-disk',
            onSelect = function()
                local saved, reason = saveAppearance()
                if not saved then
                    lib.notify({ title = 'HimotheeCore', description = reason or 'Appearance save failed.', type = 'error' })
                    showMain()
                    return
                end

                editorOpen = false
                lib.hideContext(false)
                lib.notify({ title = 'HimotheeCore', description = 'Appearance saved.', type = 'success' })
                TriggerEvent('himo_appearance:client:saved')
            end
        }

        lib.registerContext({
            id = 'himo_appearance_editor',
            title = required and 'Create your appearance' or 'Edit appearance',
            canClose = not required,
            onExit = function()
                editorOpen = false
            end,
            options = options
        })
        lib.showContext('himo_appearance_editor')
    end

    showMain()
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
    if editorOpen then return end
    local character = exports['himo_core']:GetCharacter()
    if not character then
        lib.notify({ title = 'HimotheeCore', description = 'Load a character first.', type = 'error' })
        return
    end
    openEditor(character, false)
end, false)
