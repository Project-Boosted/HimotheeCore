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

local function pushShared(target)
    local core = exports['himo_qb_bridge']:GetCoreObject()
    TriggerClientEvent(
        'himo_qb_bridge:client:setShared',
        target or -1,
        core.Shared.Jobs or {},
        core.Shared.Gangs or {},
        core.Shared.Items or {},
        core.Shared.Vehicles or {}
    )
end

CreateThread(function()
    while GlobalState['himothee_core:ready'] ~= true do Wait(100) end

    local core = exports['himo_qb_bridge']:GetCoreObject()
    core.Shared.Jobs = exports.himo_core:GetJobDefinitions() or {}
    core.Shared.Gangs = exports.himo_core:GetGroupDefinitions('gang') or {}
    core.Shared.Jobs.unemployed = core.Shared.Jobs.unemployed or {
        label = 'Unemployed', type = 'none', defaultDuty = false,
        grades = { [0] = { name = 'Unemployed', payment = 0, isboss = false } }
    }
    core.Shared.Gangs.none = core.Shared.Gangs.none or {
        label = 'No Gang', grades = { [0] = { name = 'none', isboss = false } }
    }

    pushShared(-1)

    local deadline = GetGameTimer() + 30000
    while GetResourceState('ox_inventory') ~= 'started' and GetGameTimer() < deadline do Wait(250) end
    if GetResourceState('ox_inventory') == 'started' then
        local ok, oxItems = pcall(function() return exports.ox_inventory:Items() end)
        if ok and type(oxItems) == 'table' then
            core.Shared.Items = mapOxItems(oxItems)
            pushShared(-1)
            local count = 0
            for _ in pairs(core.Shared.Items) do count = count + 1 end
            print(('[HimotheeCompat] Loaded %d ox_inventory item definitions into QBCore.Shared.Items.'):format(count))
        else
            print('[HimotheeCompat] ox_inventory started but its item catalog could not be read.')
        end
    end
end)

RegisterNetEvent('himo_qb_bridge:server:requestShared', function()
    pushShared(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'ox_inventory' then return end
    CreateThread(function()
        Wait(1000)
        local ok, oxItems = pcall(function() return exports.ox_inventory:Items() end)
        if not ok or type(oxItems) ~= 'table' then return end
        local core = exports['himo_qb_bridge']:GetCoreObject()
        core.Shared.Items = mapOxItems(oxItems)
        pushShared(-1)
    end)
end)
