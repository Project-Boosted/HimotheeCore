local function psResourceHealth(name)
    local state = GetResourceState(name)
    return state == 'started', state, GetResourceMetadata(name, 'version', 0) or 'unknown'
end

local function tableExists(name)
    local count = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
    ]], { name })
    return tonumber(count) == 1
end

HimoCommands.register('himopstest', {}, function(source, args, raw, respond)
    if source == 0 then return end

    local required = {
        'PolyZone',
        'screenshot-basic',
        'fivem-freecam',
        'ox_doorlock',
        'ps_lib',
        'ps-realtor',
        'ps-housing',
        'ps-dispatch',
        'ps-mdt',
        'ps-adminmenu',
    }

    local resourcesOk = true
    for _, name in ipairs(required) do
        local ok, state, version = psResourceHealth(name)
        if not ok then resourcesOk = false end
        respond(source, ('PS resource | %s=%s (%s v%s)'):format(name, tostring(ok), state, version))
    end

    local dbChecks = {
        players = tableExists('players'),
        player_vehicles = tableExists('player_vehicles'),
        properties = tableExists('properties'),
        ox_doorlock = tableExists('ox_doorlock'),
        mdt_profiles = tableExists('mdt_profiles'),
    }

    local databaseOk = true
    local dbParts = {}
    for _, name in ipairs({ 'players', 'player_vehicles', 'properties', 'ox_doorlock', 'mdt_profiles' }) do
        local ok = dbChecks[name]
        if not ok then databaseOk = false end
        dbParts[#dbParts + 1] = ('%s=%s'):format(name, tostring(ok))
    end
    respond(source, 'PS database | ' .. table.concat(dbParts, ' '))

    local mirrorOk, mirrorResult = pcall(function()
        return exports.himo_qb_bridge:SyncProjectSlothMirrors()
    end)
    mirrorOk = mirrorOk and mirrorResult == true
    respond(source, ('PS bridge | mirror=%s'):format(tostring(mirrorOk)))

    local jobs = MySQL.query.await([[
        SELECT name FROM himo_jobs
        WHERE name IN ('police', 'ambulance', 'realestate') AND is_active = 1
    ]]) or {}
    local jobsOk = #jobs == 3
    respond(source, ('PS jobs | police/ambulance/realestate=%s (%d/3)'):format(tostring(jobsOk), #jobs))

    if resourcesOk and databaseOk and mirrorOk and jobsOk then
        respond(source, 'PROJECT SLOTH TEST PASS | housing + realtor + dispatch + MDT + admin menu loaded on HimotheeCore')
    else
        respond(source, 'PROJECT SLOTH TEST FAIL | inspect the failed resource/database/bridge line above', { 255, 90, 90 })
    end
end)
