local clientCallbacks = {}
local sharedMirror = {
    Items = {}, Vehicles = {}, Weapons = {}, Locations = {}, StarterItems = {}, Jobs = {}, Gangs = {}
}

local function triggerCallback(name, cb, ...)
    if type(name) ~= 'string' or type(cb) ~= 'function' then return end
    clientCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
end

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    local cb = clientCallbacks[name]
    if not cb then return end
    clientCallbacks[name] = nil
    cb(...)
end)

RegisterNetEvent('himo_qb_bridge:client:setShared', function(jobs, gangs, items, vehicles)
    sharedMirror.Jobs = type(jobs) == 'table' and jobs or sharedMirror.Jobs
    sharedMirror.Gangs = type(gangs) == 'table' and gangs or sharedMirror.Gangs
    sharedMirror.Items = type(items) == 'table' and items or sharedMirror.Items
    sharedMirror.Vehicles = type(vehicles) == 'table' and vehicles or sharedMirror.Vehicles
end)

local function core()
    local object = exports['himo_qb_bridge']:GetCoreObject()
    object.Functions = object.Functions or {}
    object.Shared = object.Shared or {}
    object.Functions.TriggerCallback = triggerCallback

    for namespace, value in pairs(sharedMirror) do
        if type(value) == 'table' and next(value) ~= nil then
            object.Shared[namespace] = value
        end
    end

    return object
end

exports('GetCoreObject', function()
    return core()
end)

exports('GetShared', function(namespace, item)
    local shared = core().Shared or {}
    local value = shared[namespace]
    if not value then return nil end
    return item and value[item] or value
end)

exports('DrawText', function(text, position)
    lib.showTextUI(tostring(text), { position = position or 'right-center' })
end)

exports('HideText', function()
    lib.hideTextUI()
end)

exports('KeyPressed', function()
    lib.hideTextUI()
end)

exports('ChangeText', function(text, position)
    lib.hideTextUI()
    lib.showTextUI(tostring(text), { position = position or 'right-center' })
end)
