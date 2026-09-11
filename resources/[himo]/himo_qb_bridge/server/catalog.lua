local function mapOxItems(items)
    local mapped = {}
    for name, item in pairs(type(items) == 'table' and items or {}) do
        mapped[name] = {
            name = name,
            label = item.label or name,
            weight = tonumber(item.weight) or 0,
            type = 'item',
            image = item.client and item.client.image or item.image,
            unique = item.stack == false,
            useable = item.consume ~= nil or item.server ~= nil or item.client ~= nil,
            shouldClose = item.close ~= false,
            description = item.description or '',
            stack = item.stack ~= false,
            close = item.close ~= false
        }
    end
    return mapped
end

local function countEntries(value)
    local count = 0
    for _ in pairs(type(value) == 'table' and value or {}) do count = count + 1 end
    return count
end

local function getShared(namespace)
    local value = exports['himo_qb_bridge']:GetSharedCatalog(namespace)
    return type(value) == 'table' and value or {}
end

local function setShared(namespace, value)
    return exports['himo_qb_bridge']:SetSharedCatalog(namespace, value)
end

local function pushShared(target)
    TriggerClientEvent(
        'himo_qb_bridge:client:setShared',
        target or -1,
        getShared('Jobs'),
        getShared('Gangs'),
        getShared('Items'),
        getShared('Vehicles')
    )
end

local function syncVehicleCatalog()
    if GetResourceState('qbx_core') ~= 'started' then return false end

    local ok, vehicles = pcall(function()
        local loaded = exports.qbx_core:GetLoadedVehicleCatalog()
        if type(loaded) == 'table' and next(loaded) ~= nil then return loaded end
        return exports.qbx_core:GetVehiclesByName()
    end)

    if not ok or type(vehicles) ~= 'table' or next(vehicles) == nil then
        return false
    end

    setShared('Vehicles', vehicles)
    print(('[HimotheeCompat] Synchronized %d QBX vehicle definitions into the authoritative QB shared catalogue.'):format(countEntries(vehicles)))
    return true
end

local function syncOxItems()
    if GetResourceState('ox_inventory') ~= 'started' then return false end

    local ok, oxItems = pcall(function() return exports.ox_inventory:Items() end)
    if not ok or type(oxItems) ~= 'table' then
        print('[HimotheeCompat] ox_inventory started but its item catalogue could not be read.')
        return false
    end

    local mapped = mapOxItems(oxItems)
    setShared('Items', mapped)
    print(('[HimotheeCompat] Loaded %d ox_inventory item definitions into QBCore.Shared.Items.'):format(countEntries(mapped)))
    return true
end

CreateThread(function()
    while GlobalState['himothee_core:ready'] ~= true do Wait(100) end

    local jobs = exports.himo_core:GetJobDefinitions() or {}
    local gangs = exports.himo_core:GetGroupDefinitions('gang') or {}

    jobs.unemployed = jobs.unemployed or {
        label = 'Unemployed', type = 'none', defaultDuty = false,
        grades = { [0] = { name = 'Unemployed', payment = 0, isboss = false } }
    }
    gangs.none = gangs.none or {
        label = 'No Gang', grades = { [0] = { name = 'none', isboss = false } }
    }

    setShared('Jobs', jobs)
    setShared('Gangs', gangs)
    pushShared(-1)

    local inventoryDeadline = GetGameTimer() + 30000
    while GetResourceState('ox_inventory') ~= 'started' and GetGameTimer() < inventoryDeadline do Wait(250) end
    syncOxItems()

    local qbxDeadline = GetGameTimer() + 30000
    while GetResourceState('qbx_core') ~= 'started' and GetGameTimer() < qbxDeadline do Wait(100) end
    syncVehicleCatalog()
end)

RegisterNetEvent('himo_qb_bridge:server:requestShared', function()
    syncVehicleCatalog()
    pushShared(source)
end)

AddEventHandler('himo_qb_bridge:server:sharedCatalogChanged', function()
    pushShared(-1)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'ox_inventory' then
        CreateThread(function()
            Wait(1000)
            syncOxItems()
        end)
    elseif resourceName == 'qbx_core' then
        -- qbx_core has completed its server scripts at this point, including its
        -- vehicle loader. Pull its explicit loader cache back into the actual
        -- Himothee QB authority before downstream resources (Jim) read it.
        syncVehicleCatalog()
    end
end)
