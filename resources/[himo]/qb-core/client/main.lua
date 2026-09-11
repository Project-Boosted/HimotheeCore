local clientCallbacks = {}
local sharedMirror = {
    Items = {}, Vehicles = {}, Weapons = {}, Locations = {}, StarterItems = {}, Jobs = {}, Gangs = {}
}

local QBCore = {
    Functions = {},
    PlayerData = {},
    Shared = sharedMirror
}

local function refreshPlayerData()
    local ok, data = pcall(function()
        return exports.himo_qb_bridge:GetPlayerData()
    end)
    if ok and type(data) == 'table' then
        QBCore.PlayerData = data
    end
    return QBCore.PlayerData
end

local function triggerCallback(name, cb, ...)
    if type(name) ~= 'string' or type(cb) ~= 'function' then return false end
    clientCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
    return true
end

QBCore.Functions.TriggerCallback = triggerCallback
QBCore.Functions.GetPlayerData = function(cb)
    local data = refreshPlayerData()
    if type(cb) == 'function' then cb(data) end
    return data
end
QBCore.Functions.GetPlayer = function()
    return QBCore.Functions.GetPlayerData()
end
QBCore.Functions.Notify = function(...)
    return exports.himo_qb_bridge:Notify(...)
end
QBCore.Functions.Progressbar = function(...)
    return exports.himo_qb_bridge:Progressbar(...)
end
QBCore.Functions.HasItem = function(...)
    return exports.himo_qb_bridge:HasItem(...)
end
QBCore.Functions.GetCoords = function(...)
    return exports.himo_qb_bridge:GetCoords(...)
end
QBCore.Functions.GetVehicle = function(...)
    return exports.himo_qb_bridge:GetVehicle(...)
end
QBCore.Functions.GetPlate = function(...)
    return exports.himo_qb_bridge:GetPlate(...)
end
QBCore.Functions.SpawnVehicle = function(...)
    return exports.himo_qb_bridge:SpawnVehicle(...)
end
QBCore.Functions.DeleteVehicle = function(...)
    return exports.himo_qb_bridge:DeleteVehicle(...)
end

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    local cb = clientCallbacks[name]
    if not cb then return end
    clientCallbacks[name] = nil
    cb(...)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if type(data) == 'table' then QBCore.PlayerData = data end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    QBCore.PlayerData = {}
end)

RegisterNetEvent('himo_qb_bridge:client:setShared', function(jobs, gangs, items, vehicles)
    if type(jobs) == 'table' then sharedMirror.Jobs = jobs end
    if type(gangs) == 'table' then sharedMirror.Gangs = gangs end
    if type(items) == 'table' then sharedMirror.Items = items end
    if type(vehicles) == 'table' then sharedMirror.Vehicles = vehicles end
    QBCore.Shared = sharedMirror
end)

local function getCoreObject(filters)
    if type(filters) ~= 'table' then return QBCore end
    local result = {}
    for i = 1, #filters do
        local key = filters[i]
        if QBCore[key] ~= nil then result[key] = QBCore[key] end
    end
    return result
end

exports('GetCoreObject', getCoreObject)
exports('GetPlayerData', function() return QBCore.Functions.GetPlayerData() end)
exports('TriggerCallback', triggerCallback)

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

CreateThread(function()
    while not exports.himo_core:IsCharacterLoaded() do Wait(250) end
    refreshPlayerData()
end)
