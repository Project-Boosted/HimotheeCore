local clientCallbacks = {}
local sharedMirror = {
    Items = {}, Vehicles = {}, Weapons = {}, Locations = {}, StarterItems = {}, Jobs = {}, Gangs = {}
}

-- Keep the public QBCore object local to the qb-core facade. Returning a table
-- from himo_qb_bridge, mutating it here, then exporting it again adds a second
-- resource boundary and can drop dynamically attached functions such as
-- TriggerCallback. Real QB scripts expect this exact object to own its methods.
local QBCore = {
    Functions = {},
    Shared = sharedMirror
}

local function bridgeCore()
    local ok, object = pcall(function()
        return exports['himo_qb_bridge']:GetCoreObject()
    end)
    return ok and type(object) == 'table' and object or nil
end

local function callBridge(functionName, ...)
    local object = bridgeCore()
    local fn = object and object.Functions and object.Functions[functionName]
    if type(fn) ~= 'function' then return nil end
    return fn(...)
end

local function triggerCallback(name, cb, ...)
    if type(name) ~= 'string' or type(cb) ~= 'function' then return false end
    clientCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
    return true
end

QBCore.Functions.TriggerCallback = triggerCallback
QBCore.Functions.GetPlayerData = function(cb)
    local data = callBridge('GetPlayerData') or {}
    if type(cb) == 'function' then cb(data) end
    return data
end
QBCore.Functions.GetPlayer = function()
    return QBCore.Functions.GetPlayerData()
end
QBCore.Functions.Notify = function(...)
    return callBridge('Notify', ...)
end

for _, functionName in ipairs({
    'Progressbar', 'HasItem', 'GetCoords', 'GetVehicle', 'GetPlate',
    'SpawnVehicle', 'DeleteVehicle'
}) do
    local name = functionName
    QBCore.Functions[name] = function(...)
        return callBridge(name, ...)
    end
end

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    local cb = clientCallbacks[name]
    if not cb then return end
    clientCallbacks[name] = nil
    cb(...)
end)

RegisterNetEvent('himo_qb_bridge:client:setShared', function(jobs, gangs, items, vehicles)
    if type(jobs) == 'table' then sharedMirror.Jobs = jobs end
    if type(gangs) == 'table' then sharedMirror.Gangs = gangs end
    if type(items) == 'table' then sharedMirror.Items = items end
    if type(vehicles) == 'table' then sharedMirror.Vehicles = vehicles end
    QBCore.Shared = sharedMirror
end)

exports('GetCoreObject', function()
    return QBCore
end)

exports('GetShared', function(namespace, item)
    local value = QBCore.Shared[namespace]
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
