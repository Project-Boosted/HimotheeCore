local SharedCatalog = {
    Items = {},
    Vehicles = {},
    Weapons = {},
    Locations = {},
    StarterItems = {},
    Jobs = {},
    Gangs = {}
}

local allowed = {
    Items = true,
    Vehicles = true,
    Weapons = true,
    Locations = true,
    StarterItems = true,
    Jobs = true,
    Gangs = true
}

local function setSharedCatalog(namespace, value)
    if not allowed[namespace] then return false end
    SharedCatalog[namespace] = type(value) == 'table' and value or {}
    TriggerEvent('himo_qb_bridge:server:sharedCatalogChanged', namespace)
    return true
end

local function getSharedCatalog(namespace)
    if namespace == nil then return SharedCatalog end
    return SharedCatalog[namespace]
end

exports('SetSharedCatalog', setSharedCatalog)
exports('GetSharedCatalog', getSharedCatalog)
