-- HimotheeCore direct-source fallback vehicle catalogue.
-- The txAdmin recipe replaces this file with the pinned upstream Qbox catalogue.
local function vehicle(name, brand, model, price, category, vehicleType)
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

return {
    adder = vehicle('Adder', 'Truffade', 'adder', 86065, 'super'),
    blista = vehicle('Blista', 'Dinka', 'blista', 18000, 'compacts'),
    buffalo = vehicle('Buffalo', 'Bravado', 'buffalo', 42000, 'sports'),
    sultan = vehicle('Sultan', 'Karin', 'sultan', 45000, 'sports'),
    elegy = vehicle('Elegy RH8', 'Annis', 'elegy', 95000, 'sports'),
    dominator = vehicle('Dominator', 'Vapid', 'dominator', 52000, 'muscle'),
    futo = vehicle('Futo', 'Karin', 'futo', 22000, 'sports'),
    kuruma = vehicle('Kuruma', 'Karin', 'kuruma', 62000, 'sports'),
    baller = vehicle('Baller', 'Gallivanter', 'baller', 65000, 'suvs'),
    granger = vehicle('Granger', 'Declasse', 'granger', 52000, 'suvs'),
    bison = vehicle('Bison', 'Bravado', 'bison', 35000, 'vans'),
    rumpo = vehicle('Rumpo', 'Bravado', 'rumpo', 28000, 'vans'),
    mule = vehicle('Mule', 'Maibatsu', 'mule', 52000, 'commercial'),
    pounder = vehicle('Pounder', 'MTL', 'pounder', 85000, 'commercial'),
    taxi = vehicle('Taxi', 'Vapid', 'taxi', 30000, 'service'),
    bus = vehicle('Bus', 'Brute', 'bus', 60000, 'service'),
    police = vehicle('Police Cruiser', 'Vapid', 'police', 0, 'emergency'),
    ambulance = vehicle('Ambulance', 'Brute', 'ambulance', 0, 'emergency'),
    firetruk = vehicle('Fire Truck', 'MTL', 'firetruk', 0, 'emergency'),
    towtruck = vehicle('Tow Truck', 'Vapid', 'towtruck', 55000, 'utility'),
    flatbed = vehicle('Flatbed', 'MTL', 'flatbed', 65000, 'utility'),
    bati = vehicle('Bati 801', 'Pegassi', 'bati', 18000, 'motorcycles', 'bike'),
    sanchez = vehicle('Sanchez', 'Maibatsu', 'sanchez', 12000, 'motorcycles', 'bike'),
    dinghy = vehicle('Dinghy', 'Nagasaki', 'dinghy', 45000, 'boats', 'boat'),
    frogger = vehicle('Frogger', 'Maibatsu', 'frogger', 950000, 'helicopters', 'heli'),
    luxor = vehicle('Luxor', 'Buckingham', 'luxor', 1600000, 'planes', 'plane')
}
