local function core()
    return exports['himo_qb_bridge']:GetCoreObject()
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

exports('GetPlayer', function(source)
    return core().Functions.GetPlayer(source)
end)

exports('GetPlayerByCitizenId', function(citizenId)
    return core().Functions.GetPlayerByCitizenId(citizenId)
end)
