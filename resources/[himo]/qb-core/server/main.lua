local function core()
    local object = exports['himo_qb_bridge']:GetCoreObject()
    local authoritative = exports['himo_qb_bridge']:GetSharedCatalog()

    object.Shared = object.Shared or {}
    if type(authoritative) == 'table' then
        for namespace, value in pairs(authoritative) do
            if type(value) == 'table' then
                object.Shared[namespace] = value
            end
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

exports('GetPlayer', function(source)
    return core().Functions.GetPlayer(source)
end)

exports('GetPlayerByCitizenId', function(citizenId)
    return core().Functions.GetPlayerByCitizenId(citizenId)
end)

exports('CreateUseableItem', function(itemName, cb)
    return core().Functions.CreateUseableItem(itemName, cb)
end)

exports('CanUseItem', function(itemName)
    return core().Functions.CanUseItem(itemName)
end)
