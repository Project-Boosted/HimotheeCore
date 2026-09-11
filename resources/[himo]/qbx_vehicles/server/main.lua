local QbxState = { OUT = 0, GARAGED = 1, IMPOUNDED = 2 }

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function decode(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback or {} end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or (fallback or {})
end

local function encode(value)
    return json.encode(type(value) == 'table' and value or {})
end

local function toQbxState(value)
    value = tostring(value or ''):lower()
    if value == 'stored' or value == 'garaged' then return QbxState.GARAGED end
    if value == 'impounded' or value == 'impound' then return QbxState.IMPOUNDED end
    return QbxState.OUT
end

local function fromQbxState(value)
    value = tonumber(value)
    if value == QbxState.GARAGED then return 'stored' end
    if value == QbxState.IMPOUNDED then return 'impounded' end
    return 'out'
end

local function ownerCharacterId(citizenId)
    if not citizenId or citizenId == '' then return nil end
    return tonumber(MySQL.scalar.await([[
        SELECT `id` FROM `himo_characters`
        WHERE `citizen_id` = ? AND `is_deleted` = 0
        LIMIT 1
    ]], { citizenId }))
end

local function citizenIdForOwner(characterId)
    if not characterId then return nil end
    return MySQL.scalar.await('SELECT `citizen_id` FROM `himo_characters` WHERE `id` = ? LIMIT 1', { characterId })
end

local function rowToVehicle(row)
    if not row then return nil end
    local props = decode(row.properties)
    props.plate = props.plate or row.plate
    props.engineHealth = props.engineHealth or tonumber(row.engine_health) or 1000
    props.bodyHealth = props.bodyHealth or tonumber(row.body_health) or 1000
    props.fuelLevel = props.fuelLevel or tonumber(row.fuel) or 100

    local metadata = decode(row.metadata)
    return {
        id = tonumber(row.id),
        citizenid = row.citizen_id or citizenIdForOwner(row.owner_character_id),
        modelName = row.model,
        garage = row.garage,
        state = toQbxState(row.state),
        depotPrice = tonumber(metadata.depotPrice) or 0,
        props = props,
        coords = metadata.coords
    }
end

local function randomPlate()
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local digits = '0123456789'
    local function pick(pool)
        local index = math.random(1, #pool)
        return pool:sub(index, index)
    end

    for _ = 1, 50 do
        local plate = ('H%s%s%s%s%s%s%s'):format(
            pick(letters), pick(letters), pick(digits), pick(digits), pick(digits), pick(letters), pick(letters)
        )
        local exists = MySQL.scalar.await('SELECT 1 FROM `himo_vehicles` WHERE `plate` = ? LIMIT 1', { plate })
        if not exists then return plate end
    end
    return ('H%07d'):format(math.random(0, 9999999))
end

local function getRows(filters)
    filters = type(filters) == 'table' and filters or {}
    local where, params = {}, {}

    if filters.vehicleId then
        where[#where + 1] = 'v.`id` = ?'
        params[#params + 1] = tonumber(filters.vehicleId)
    end
    if filters.citizenid then
        where[#where + 1] = 'c.`citizen_id` = ?'
        params[#params + 1] = tostring(filters.citizenid)
    end
    if filters.garage then
        where[#where + 1] = 'v.`garage` = ?'
        params[#params + 1] = tostring(filters.garage)
    end

    local query = [[
        SELECT v.*, c.`citizen_id`
        FROM `himo_vehicles` v
        LEFT JOIN `himo_characters` c ON c.`id` = v.`owner_character_id`
    ]]
    if #where > 0 then query = query .. ' WHERE ' .. table.concat(where, ' AND ') end
    query = query .. ' ORDER BY v.`id` ASC'

    local rows = MySQL.query.await(query, params) or {}
    if filters.states == nil then return rows end

    local allowed = {}
    if type(filters.states) == 'table' then
        for _, state in ipairs(filters.states) do allowed[tonumber(state)] = true end
    else
        allowed[tonumber(filters.states)] = true
    end

    local filtered = {}
    for _, row in ipairs(rows) do
        if allowed[toQbxState(row.state)] then filtered[#filtered + 1] = row end
    end
    return filtered
end

local function getPlayerVehicles(filters)
    local result = {}
    for _, row in ipairs(getRows(filters)) do result[#result + 1] = rowToVehicle(row) end
    return result
end

local function getPlayerVehicle(vehicleId, filters)
    filters = type(filters) == 'table' and filters or {}
    filters.vehicleId = tonumber(vehicleId)
    local vehicles = getPlayerVehicles(filters)
    return vehicles[1]
end

local function getVehicleIdByPlate(plate)
    return tonumber(MySQL.scalar.await(
        'SELECT `id` FROM `himo_vehicles` WHERE TRIM(`plate`) = ? LIMIT 1',
        { trim(plate) }
    ))
end

local function doesPlayerVehiclePlateExist(plate)
    return getVehicleIdByPlate(plate) ~= nil
end

local function createPlayerVehicle(request)
    request = type(request) == 'table' and request or {}
    local model = tostring(request.model or '')
    if model == '' then return nil, { code = 'invalid_model', message = 'model is required' } end

    local ownerId = ownerCharacterId(request.citizenid)
    if request.citizenid and not ownerId then
        return nil, { code = 'invalid_owner', message = 'Himothee character was not found' }
    end

    local props = type(request.props) == 'table' and request.props or {}
    local plate = trim(props.plate)
    if plate == '' then plate = randomPlate() end
    if doesPlayerVehiclePlateExist(plate) then
        return nil, { code = 'plate_exists', message = 'vehicle plate already exists' }
    end

    props.plate = plate
    props.engineHealth = tonumber(props.engineHealth) or 1000
    props.bodyHealth = tonumber(props.bodyHealth) or 1000
    props.fuelLevel = tonumber(props.fuelLevel) or 100

    local id = MySQL.insert.await([[
        INSERT INTO `himo_vehicles`
            (`owner_character_id`, `plate`, `model`, `vehicle_type`, `garage`, `state`,
             `fuel`, `engine_health`, `body_health`, `properties`, `metadata`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        ownerId,
        plate,
        model,
        request.vehicleType or 'automobile',
        request.garage,
        request.garage and 'stored' or 'out',
        props.fuelLevel,
        props.engineHealth,
        props.bodyHealth,
        encode(props),
        encode({ coords = request.coords, depotPrice = 0 })
    })

    return tonumber(id)
end

local function setPlayerVehicleOwner(vehicleId, citizenId)
    local ownerId = citizenId and ownerCharacterId(citizenId) or nil
    if citizenId and not ownerId then
        return false, { code = 'invalid_owner', message = 'Himothee character was not found' }
    end

    local changed = MySQL.update.await('UPDATE `himo_vehicles` SET `owner_character_id` = ? WHERE `id` = ?', {
        ownerId, tonumber(vehicleId)
    })
    return changed ~= nil and changed > 0
end

local function deletePlayerVehicles(idType, idValue)
    local allowed = { citizenid = true, plate = true, vehicleId = true }
    if not allowed[idType] then return false, { code = 'invalid_id_type', message = 'unsupported vehicle id type' } end

    local changed
    if idType == 'citizenid' then
        changed = MySQL.update.await([[
            DELETE v FROM `himo_vehicles` v
            JOIN `himo_characters` c ON c.`id` = v.`owner_character_id`
            WHERE c.`citizen_id` = ?
        ]], { tostring(idValue) })
    elseif idType == 'plate' then
        changed = MySQL.update.await('DELETE FROM `himo_vehicles` WHERE TRIM(`plate`) = ?', { trim(idValue) })
    else
        changed = MySQL.update.await('DELETE FROM `himo_vehicles` WHERE `id` = ?', { tonumber(idValue) })
    end
    return changed ~= nil
end

local function saveVehicle(vehicle, options)
    options = type(options) == 'table' and options or {}
    vehicle = tonumber(vehicle)
    if not vehicle then return false, { code = 'invalid_entity', message = 'vehicle entity is required' } end

    local entity = Entity(vehicle)
    local vehicleId = entity and entity.state and tonumber(entity.state.vehicleid) or nil
    if not vehicleId and DoesEntityExist(vehicle) then vehicleId = getVehicleIdByPlate(GetVehicleNumberPlateText(vehicle)) end
    if not vehicleId then return false, { code = 'not_owned', message = 'vehicle is not registered in HimotheeCore' } end

    local existing = MySQL.single.await('SELECT * FROM `himo_vehicles` WHERE `id` = ? LIMIT 1', { vehicleId })
    if not existing then return false, { code = 'not_owned', message = 'vehicle record was not found' } end

    local props = decode(existing.properties)
    if type(options.props) == 'table' then
        for key, value in pairs(options.props) do props[key] = value end
    end

    local metadata = decode(existing.metadata)
    if options.coords then metadata.coords = options.coords end
    if options.depotPrice ~= nil then metadata.depotPrice = tonumber(options.depotPrice) or 0 end

    local plate = trim(props.plate ~= nil and props.plate or existing.plate)
    local fuel = tonumber(props.fuelLevel) or tonumber(existing.fuel) or 100
    local engine = tonumber(props.engineHealth) or tonumber(existing.engine_health) or 1000
    local body = tonumber(props.bodyHealth) or tonumber(existing.body_health) or 1000

    MySQL.update.await([[
        UPDATE `himo_vehicles`
        SET `plate` = ?, `garage` = ?, `state` = ?, `fuel` = ?,
            `engine_health` = ?, `body_health` = ?, `properties` = ?, `metadata` = ?
        WHERE `id` = ?
    ]], {
        plate,
        options.garage ~= nil and options.garage or existing.garage,
        options.state ~= nil and fromQbxState(options.state) or existing.state,
        fuel, engine, body, encode(props), encode(metadata), vehicleId
    })

    TriggerEvent('qbx_vehicles:server:vehicleSaved', vehicleId)
    return true
end

exports('DoesPlayerVehiclePlateExist', doesPlayerVehiclePlateExist)
exports('GetPlayerVehicles', getPlayerVehicles)
exports('GetPlayerVehicle', getPlayerVehicle)
exports('CreatePlayerVehicle', createPlayerVehicle)
exports('SetPlayerVehicleOwner', setPlayerVehicleOwner)
exports('DeletePlayerVehicles', deletePlayerVehicles)
exports('GetVehicleIdByPlate', getVehicleIdByPlate)
exports('SaveVehicle', saveVehicle)
