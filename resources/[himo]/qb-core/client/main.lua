local sharedMirror = {
    Items = {}, Vehicles = {}, Weapons = {}, Locations = {}, StarterItems = {}, Jobs = {}, Gangs = {}
}

local function isFunction(value)
    if type(value) == 'table' then
        return value.__cfx_functionReference ~= nil and type(value.__cfx_functionReference) == 'string'
    end
    return type(value) == 'function'
end

sharedMirror.IsFunction = isFunction
sharedMirror.Trim = function(value)
    return tostring(value or ''):match('^%s*(.-)%s*$') or ''
end
sharedMirror.Round = function(value, decimals)
    value = tonumber(value) or 0
    decimals = tonumber(decimals) or 0
    local power = 10 ^ decimals
    return math.floor(value * power + 0.5) / power
end

local QBCore = {
    Functions = {},
    PlayerData = {},
    Shared = sharedMirror,
    ServerCallbacks = {},
    ClientCallbacks = {}
}

local function refreshPlayerData()
    local ok, data = pcall(function()
        return exports.himo_qb_bridge:GetPlayerData()
    end)
    if ok and type(data) == 'table' then
        data.name = data.name or GetPlayerName(PlayerId()) or ''
        QBCore.PlayerData = data
    end
    return QBCore.PlayerData
end

-- Match the current QBCore callback contract. Callback funcrefs crossing a
-- resource boundary can arrive as CFX function-reference tables, so use the
-- same IsFunction semantics as upstream QBCore rather than plain type().
function QBCore.Functions.TriggerCallback(name, ...)
    if type(name) ~= 'string' or name == '' then return nil end

    local args = { ... }
    local cb
    if isFunction(args[1]) then
        cb = args[1]
        table.remove(args, 1)
    end

    local pending = promise.new()
    QBCore.ServerCallbacks[name] = {
        callback = cb,
        promise = pending
    }

    TriggerServerEvent('QBCore:Server:TriggerCallback', name, table.unpack(args))

    if cb == nil then
        Citizen.Await(pending)
        return pending.value
    end

    return true
end

QBCore.Functions.GetPlayerData = function(cb)
    local data = refreshPlayerData()
    if isFunction(cb) then cb(data) end
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
QBCore.Functions.GetVehicleProperties = function(...)
    return exports.himo_qb_bridge:GetVehicleProperties(...)
end
QBCore.Functions.SetVehicleProperties = function(...)
    return exports.himo_qb_bridge:SetVehicleProperties(...)
end
QBCore.Functions.SpawnVehicle = function(...)
    return exports.himo_qb_bridge:SpawnVehicle(...)
end
QBCore.Functions.DeleteVehicle = function(...)
    return exports.himo_qb_bridge:DeleteVehicle(...)
end

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    local entry = QBCore.ServerCallbacks[name]
    if not entry then return end

    entry.promise:resolve(...)
    if entry.callback then entry.callback(...) end
    QBCore.ServerCallbacks[name] = nil
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if type(data) == 'table' then
        data.name = data.name or GetPlayerName(PlayerId()) or ''
        QBCore.PlayerData = data
    end
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
exports('TriggerCallback', function(name, ...)
    return QBCore.Functions.TriggerCallback(name, ...)
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

CreateThread(function()
    while not exports.himo_core:IsCharacterLoaded() do Wait(250) end
    refreshPlayerData()
end)
