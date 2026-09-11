local QBCore = exports['himo_qb_bridge']:GetCoreObject()

QBCore.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    local data = {
        name = name,
        label = label,
        duration = duration,
        useWhileDead = useWhileDead,
        canCancel = canCancel,
        controlDisables = disableControls,
        animation = animation,
        prop = prop,
        propTwo = propTwo
    }

    exports.progressbar:Progress(data, function(cancelled)
        if cancelled then
            if type(onCancel) == 'function' then onCancel() end
        elseif type(onFinish) == 'function' then
            onFinish()
        end
    end)
end

QBCore.Functions.HasItem = function(item, amount)
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    amount = tonumber(amount) or 1
    if type(item) == 'string' then
        return (exports.ox_inventory:Search('count', item) or 0) >= amount
    end
    if type(item) ~= 'table' then return false end
    for name, required in pairs(item) do
        local count = exports.ox_inventory:Search('count', name) or 0
        if count < (tonumber(required) or amount) then return false end
    end
    return true
end

QBCore.Functions.GetCoords = function(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

QBCore.Functions.GetVehicle = function()
    local ped = PlayerPedId()
    return GetVehiclePedIsIn(ped, false)
end

QBCore.Functions.GetPlate = function(vehicle)
    if not vehicle or vehicle == 0 then return nil end
    return (GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

QBCore.Functions.SpawnVehicle = function(model, cb, coords, isNetworked)
    local hash = type(model) == 'number' and model or joaat(model)
    lib.requestModel(hash)
    coords = coords or GetEntityCoords(PlayerPedId())
    local heading = type(coords) == 'vector4' and coords.w or GetEntityHeading(PlayerPedId())
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, isNetworked ~= false, false)
    SetModelAsNoLongerNeeded(hash)
    if type(cb) == 'function' then cb(vehicle) end
    return vehicle
end

QBCore.Functions.DeleteVehicle = function(vehicle)
    if not vehicle or vehicle == 0 then return false end
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
    return not DoesEntityExist(vehicle)
end

-- Explicit exports are used by the public qb-core facade. Avoid returning a
-- CoreObject from this resource and then invoking function fields across a
-- second resource boundary.
exports('Progressbar', function(...) return QBCore.Functions.Progressbar(...) end)
exports('HasItem', function(...) return QBCore.Functions.HasItem(...) end)
exports('GetCoords', function(...) return QBCore.Functions.GetCoords(...) end)
exports('GetVehicle', function(...) return QBCore.Functions.GetVehicle(...) end)
exports('GetPlate', function(...) return QBCore.Functions.GetPlate(...) end)
exports('SpawnVehicle', function(...) return QBCore.Functions.SpawnVehicle(...) end)
exports('DeleteVehicle', function(...) return QBCore.Functions.DeleteVehicle(...) end)
