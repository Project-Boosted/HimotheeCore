-- HimotheeCore Stage 1E - Project Sloth compatibility bridge.
-- Project Sloth still expects the traditional QBCore players/player_vehicles
-- persistence surfaces for offline records. The database migration creates those
-- surfaces; this runtime keeps them refreshed from HimotheeCore native storage.

local function qb()
    return exports.himo_qb_bridge:GetCoreObject()
end

local function decode(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback or {} end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or (fallback or {})
end

local syncCharactersSql = [[
INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata, inventory)
SELECT
    c.citizen_id,
    c.slot,
    (SELECT i.identifier FROM himo_identifiers i WHERE i.account_id = c.account_id AND i.provider = 'license' ORDER BY i.id LIMIT 1),
    CONCAT(c.first_name, ' ', c.last_name),
    JSON_OBJECT(
        'cash', COALESCE((SELECT b.balance FROM himo_account_balances b WHERE b.character_id = c.id AND b.account_type = 'cash' LIMIT 1), 0),
        'bank', COALESCE((SELECT b.balance FROM himo_account_balances b WHERE b.character_id = c.id AND b.account_type = 'bank' LIMIT 1), 0)
    ),
    JSON_OBJECT(
        'firstname', c.first_name, 'lastname', c.last_name,
        'birthdate', COALESCE(DATE_FORMAT(c.date_of_birth, '%Y-%m-%d'), ''),
        'gender', COALESCE(c.gender, ''), 'nationality', COALESCE(c.nationality, ''),
        'phone', COALESCE(c.phone_number, ''), 'account', c.citizen_id
    ),
    COALESCE((
        SELECT JSON_OBJECT(
            'name', cj.job_name, 'label', j.label, 'type', COALESCE(j.type, 'none'),
            'onduty', cj.on_duty, 'isboss', g.is_boss, 'payment', g.salary,
            'grade', JSON_OBJECT('name', g.name, 'level', cj.grade)
        )
        FROM himo_character_jobs cj
        JOIN himo_jobs j ON j.name = cj.job_name
        JOIN himo_job_grades g ON g.job_name = cj.job_name AND g.grade = cj.grade
        WHERE cj.character_id = c.id AND cj.is_primary = 1
        LIMIT 1
    ), JSON_OBJECT('name', 'unemployed', 'label', 'Unemployed', 'type', 'civilian', 'onduty', 0, 'isboss', 0, 'payment', 0, 'grade', JSON_OBJECT('name', 'unemployed', 'level', 0))),
    JSON_OBJECT('name', 'none', 'label', 'No Gang', 'isboss', 0, 'grade', JSON_OBJECT('name', 'none', 'level', 0)),
    JSON_OBJECT(
        'x', COALESCE(m.position_x, 0), 'y', COALESCE(m.position_y, 0),
        'z', COALESCE(m.position_z, 0), 'w', COALESCE(m.heading, 0)
    ),
    COALESCE(m.metadata, JSON_OBJECT()),
    c.inventory
FROM himo_characters c
LEFT JOIN himo_character_metadata m ON m.character_id = c.id
WHERE c.is_deleted = 0
ON DUPLICATE KEY UPDATE
    cid = VALUES(cid), license = VALUES(license), name = VALUES(name),
    money = VALUES(money), charinfo = VALUES(charinfo), job = VALUES(job),
    position = VALUES(position), metadata = VALUES(metadata), inventory = VALUES(inventory)
]]

local syncVehiclesSql = [[
INSERT INTO player_vehicles
    (id, citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state, glovebox, trunk,
     mdt_vehicle_information, mdt_vehicle_points, mdt_vehicle_status, mdt_vehicle_stolen,
     mdt_vehicle_boloactive, mdt_vehicle_image)
SELECT
    v.id, c.citizen_id, v.model, v.model, v.properties, v.plate, v.garage,
    ROUND(v.fuel), v.engine_health, v.body_health,
    CASE WHEN v.state = 'stored' THEN 1 WHEN v.state = 'impound' THEN 2 ELSE 0 END,
    v.glovebox, v.trunk, v.mdt_vehicle_information, v.mdt_vehicle_points,
    v.mdt_vehicle_status, v.mdt_vehicle_stolen, v.mdt_vehicle_boloactive, v.mdt_vehicle_image
FROM himo_vehicles v
LEFT JOIN himo_characters c ON c.id = v.owner_character_id
ON DUPLICATE KEY UPDATE
    citizenid = VALUES(citizenid), vehicle = VALUES(vehicle), hash = VALUES(hash), mods = VALUES(mods),
    garage = VALUES(garage), fuel = VALUES(fuel), engine = VALUES(engine), body = VALUES(body), state = VALUES(state),
    glovebox = VALUES(glovebox), trunk = VALUES(trunk),
    mdt_vehicle_information = VALUES(mdt_vehicle_information),
    mdt_vehicle_points = VALUES(mdt_vehicle_points),
    mdt_vehicle_status = VALUES(mdt_vehicle_status),
    mdt_vehicle_stolen = VALUES(mdt_vehicle_stolen),
    mdt_vehicle_boloactive = VALUES(mdt_vehicle_boloactive),
    mdt_vehicle_image = VALUES(mdt_vehicle_image)
]]

local function syncProjectSlothMirrors()
    local okCharacters, errCharacters = pcall(MySQL.query.await, syncCharactersSql)
    if not okCharacters then
        print(('[himo_qb_bridge] Project Sloth players mirror sync failed: %s'):format(tostring(errCharacters)))
        return false
    end

    local okVehicles, errVehicles = pcall(MySQL.query.await, syncVehiclesSql)
    if not okVehicles then
        print(('[himo_qb_bridge] Project Sloth player_vehicles mirror sync failed: %s'):format(tostring(errVehicles)))
        return false
    end

    return true
end

local function getOfflinePlayer(citizenId)
    citizenId = tostring(citizenId or '')
    if citizenId == '' then return nil end

    local row = MySQL.single.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { citizenId })
    if not row then return nil end

    local playerData = {
        source = 0,
        citizenid = row.citizenid,
        cid = tonumber(row.cid) or 1,
        license = row.license,
        name = row.name,
        money = decode(row.money),
        charinfo = decode(row.charinfo),
        job = decode(row.job),
        gang = decode(row.gang),
        position = decode(row.position),
        metadata = decode(row.metadata),
        items = decode(row.inventory),
        offline = true,
    }

    return { PlayerData = playerData, Offline = true }
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(250) end
    Wait(1000)

    local object = qb()
    object.Functions.GetOfflinePlayerByCitizenId = getOfflinePlayer

    syncProjectSlothMirrors()

    while true do
        Wait(15000)
        syncProjectSlothMirrors()
    end
end)

-- Fast-path refreshes around character/job lifecycle changes. The periodic sync
-- remains as a safety net for changes made by other resources directly in SQL.
AddEventHandler('himo_core:server:playerLoaded', function()
    SetTimeout(250, syncProjectSlothMirrors)
end)

AddEventHandler('himo_core:server:jobsChanged', function()
    SetTimeout(100, syncProjectSlothMirrors)
end)

AddEventHandler('himo_core:server:groupsChanged', function()
    SetTimeout(100, syncProjectSlothMirrors)
end)

exports('SyncProjectSlothMirrors', syncProjectSlothMirrors)
exports('GetOfflinePlayerByCitizenId', getOfflinePlayer)
