local QB = exports['qb-core']:GetCoreObject()

local function fallbackVehicle(name, brand, model, price, category, vehicleType)
    return {
        name = name,
        brand = brand,
        model = model,
        price = price,
        category = category,
        type = vehicleType or 'automobile',
        hash = joaat(model)
    }
end

local function fallbackCatalog()
    return {
        adder = fallbackVehicle('Adder', 'Truffade', 'adder', 86065, 'super'),
        blista = fallbackVehicle('Blista', 'Dinka', 'blista', 18000, 'compacts'),
        buffalo = fallbackVehicle('Buffalo', 'Bravado', 'buffalo', 42000, 'sports'),
        sultan = fallbackVehicle('Sultan', 'Karin', 'sultan', 45000, 'sports'),
        elegy = fallbackVehicle('Elegy RH8', 'Annis', 'elegy', 95000, 'sports'),
        dominator = fallbackVehicle('Dominator', 'Vapid', 'dominator', 52000, 'muscle'),
        futo = fallbackVehicle('Futo', 'Karin', 'futo', 22000, 'sports'),
        kuruma = fallbackVehicle('Kuruma', 'Karin', 'kuruma', 62000, 'sports'),
        baller = fallbackVehicle('Baller', 'Gallivanter', 'baller', 65000, 'suvs'),
        granger = fallbackVehicle('Granger', 'Declasse', 'granger', 52000, 'suvs'),
        bison = fallbackVehicle('Bison', 'Bravado', 'bison', 35000, 'vans'),
        rumpo = fallbackVehicle('Rumpo', 'Bravado', 'rumpo', 28000, 'vans'),
        mule = fallbackVehicle('Mule', 'Maibatsu', 'mule', 52000, 'commercial'),
        pounder = fallbackVehicle('Pounder', 'MTL', 'pounder', 85000, 'commercial'),
        taxi = fallbackVehicle('Taxi', 'Vapid', 'taxi', 30000, 'service'),
        bus = fallbackVehicle('Bus', 'Brute', 'bus', 60000, 'service'),
        police = fallbackVehicle('Police Cruiser', 'Vapid', 'police', 0, 'emergency'),
        ambulance = fallbackVehicle('Ambulance', 'Brute', 'ambulance', 0, 'emergency'),
        firetruk = fallbackVehicle('Fire Truck', 'MTL', 'firetruk', 0, 'emergency'),
        towtruck = fallbackVehicle('Tow Truck', 'Vapid', 'towtruck', 55000, 'utility'),
        flatbed = fallbackVehicle('Flatbed', 'MTL', 'flatbed', 65000, 'utility'),
        bati = fallbackVehicle('Bati 801', 'Pegassi', 'bati', 18000, 'motorcycles', 'bike'),
        sanchez = fallbackVehicle('Sanchez', 'Maibatsu', 'sanchez', 12000, 'motorcycles', 'bike'),
        dinghy = fallbackVehicle('Dinghy', 'Nagasaki', 'dinghy', 45000, 'boats', 'boat'),
        frogger = fallbackVehicle('Frogger', 'Maibatsu', 'frogger', 950000, 'helicopters', 'heli'),
        luxor = fallbackVehicle('Luxor', 'Buckingham', 'luxor', 1600000, 'planes', 'plane')
    }
end

local function catalogCount(catalog)
    local count = 0
    for _ in pairs(type(catalog) == 'table' and catalog or {}) do
        count = count + 1
    end
    return count
end

local function loadVehicleCatalog()
    local ok, catalog = pcall(require, 'shared.vehicles')
    local sourceName = 'pinned Qbox catalogue'

    if not ok or type(catalog) ~= 'table' or next(catalog) == nil then
        catalog = fallbackCatalog()
        sourceName = 'Himothee fallback catalogue'
        print(('[HimotheeCompat] WARNING: full Qbox vehicle catalogue unavailable (%s). Using %d fallback vehicles.'):format(
            ok and 'empty table' or tostring(catalog), catalogCount(catalog)
        ))
    end

    QB.Shared.Vehicles = catalog

    local count = catalogCount(catalog)
    GlobalState['himothee_core:vehicleCatalogCount'] = count
    GlobalState['himothee_core:vehicleCatalogSource'] = sourceName

    print(('[HimotheeCompat] Loaded %d vehicle definitions into QBCore.Shared.Vehicles from %s.'):format(count, sourceName))
    return catalog, count, sourceName
end

loadVehicleCatalog()

exports('ReloadVehicleCatalog', loadVehicleCatalog)
exports('GetVehicleCatalogCount', function()
    return catalogCount(QB.Shared.Vehicles)
end)
