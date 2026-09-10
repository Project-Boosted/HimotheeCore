local CONTEXT_ID = 'himo_spawn_selector'
local selectorOpen = false

local fixedSpawns = {
    {
        title = 'Legion Square',
        description = 'Central Los Santos',
        icon = 'city',
        coords = { x = 215.76, y = -810.12, z = 30.73, w = 157.0 }
    },
    {
        title = 'Los Santos International',
        description = 'Airport arrivals',
        icon = 'plane-arrival',
        coords = { x = -1037.72, y = -2737.87, z = 20.17, w = 329.0 }
    },
    {
        title = 'Sandy Shores',
        description = 'Blaine County',
        icon = 'sun',
        coords = { x = 1853.20, y = 3689.51, z = 34.27, w = 210.0 }
    },
    {
        title = 'Paleto Bay',
        description = 'North coast',
        icon = 'mountain',
        coords = { x = -104.83, y = 6469.32, z = 31.63, w = 226.0 }
    }
}

local function validLastPosition(character)
    if type(character) ~= 'table' then return nil end

    local x = tonumber(character.position_x)
    local y = tonumber(character.position_y)
    local z = tonumber(character.position_z)
    local w = tonumber(character.heading) or 0.0

    if not x or not y or not z then return nil end
    if math.abs(x) < 0.01 and math.abs(y) < 0.01 and math.abs(z) < 0.01 then return nil end

    return { x = x, y = y, z = z, w = w }
end

local function choose(coords, label, isNewCharacter)
    if not selectorOpen then return end
    selectorOpen = false
    lib.hideContext(false)

    TriggerEvent('himo_spawn:client:selected', {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
        w = tonumber(coords.w) or 0.0,
        label = label,
        isNewCharacter = isNewCharacter == true
    })
end

local function openSpawnSelector(character, isNewCharacter)
    selectorOpen = true

    local options = {}
    local last = validLastPosition(character)

    if last and not isNewCharacter then
        options[#options + 1] = {
            title = 'Last Location',
            description = 'Return to where this character last logged out.',
            icon = 'location-dot',
            onSelect = function()
                choose(last, 'Last Location', false)
            end
        }
    end

    for i = 1, #fixedSpawns do
        local entry = fixedSpawns[i]
        options[#options + 1] = {
            title = entry.title,
            description = entry.description,
            icon = entry.icon,
            onSelect = function()
                choose(entry.coords, entry.title, isNewCharacter)
            end
        }
    end

    lib.registerContext({
        id = CONTEXT_ID,
        title = isNewCharacter and 'Choose your first spawn' or 'Choose spawn location',
        canClose = false,
        options = options
    })

    lib.showContext(CONTEXT_ID)
end

exports('Open', openSpawnSelector)

RegisterNetEvent('himo_spawn:client:open', function(character, isNewCharacter)
    openSpawnSelector(character, isNewCharacter)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if selectorOpen then
        selectorOpen = false
        lib.hideContext(false)
    end
end)
