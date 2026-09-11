local function truthy(value)
    return value == true or value == 1 or value == '1'
end

local function safeProbe(fn)
    local ok, result, detail = pcall(fn)
    if not ok then return false, tostring(result) end
    if result == false then return false, tostring(detail or 'returned false') end
    return true, tostring(detail or 'ok')
end

local function boolText(value)
    return value and 'true' or 'false'
end

CreateThread(function()
    local deadline = GetGameTimer() + 30000
    while GetResourceState('qb-core') ~= 'started' and GetGameTimer() < deadline do Wait(250) end
    if GetResourceState('qb-core') ~= 'started' then return end

    local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if not ok or not core or not core.Functions or type(core.Functions.CreateCallback) ~= 'function' then return end

    core.Functions.CreateCallback('himo:compat:ping', function(source, cb, value)
        cb(value == 'ping' and 'pong' or 'invalid')
    end)
end)

HimoCommands.register('himostatus', {}, function(source, args, raw, respond)
    if source == 0 then return end
    local player = exports['himo_core']:GetPlayer(source)
    if not player then respond(source, 'No Himothee Player Object is loaded.') return end

    local job = player.Functions.GetPrimaryJob()
    local hunger = player.Functions.GetMetadata('hunger', 100)
    local thirst = player.Functions.GetMetadata('thirst', 100)
    local stress = player.Functions.GetMetadata('stress', 0)
    respond(source, ('%s | job %s:%s | duty %s | hunger %s | thirst %s | stress %s'):format(
        player.Functions.GetIdentifier() or 'unknown',
        job and job.job_name or 'none', job and job.grade or 'none',
        job and (truthy(job.on_duty) and 'ON' or 'OFF') or 'OFF',
        hunger, thirst, stress
    ))
end)

HimoCommands.register('himoperms', {}, function(source, args, raw, respond)
    if source == 0 then return end
    local accountId = HimoAccounts[tonumber(source) or source]
    local roles = HimoPermissions.getRoles(source)
    local roleText = #roles > 0 and table.concat(roles, ',') or 'none'
    respond(source, ('account=%s | roles=%s | staff=%s | admin=%s | dev=%s | owner=%s'):format(
        accountId or 'none', roleText,
        tostring(HimoPermissions.has(source, 'staff')),
        tostring(HimoPermissions.has(source, 'admin')),
        tostring(HimoPermissions.has(source, 'dev')),
        tostring(HimoPermissions.has(source, 'owner'))
    ))
end)

HimoCommands.register('himocompat', {}, function(source, args, raw, respond)
    if source == 0 then return end

    local checks = {}
    local details = {}

    checks.qb, details.qb = safeProbe(function()
        if GetResourceState('qb-core') ~= 'started' then return false, 'not-started' end
        local core = exports['qb-core']:GetCoreObject()
        local player = core and core.Functions and core.Functions.GetPlayer(source)
        return type(core) == 'table' and type(player) == 'table', 'player-object'
    end)

    checks.qbx, details.qbx = safeProbe(function()
        if GetResourceState('qbx_core') ~= 'started' then return false, 'not-started' end
        local player = exports.qbx_core:GetPlayer(source)
        local jobs = exports.qbx_core:GetJobs()
        return type(player) == 'table' and type(jobs) == 'table', 'player+jobs'
    end)

    checks.vehicles, details.vehicles = safeProbe(function()
        if GetResourceState('qbx_vehicles') ~= 'started' then return false, 'not-started' end
        exports.qbx_vehicles:GetVehicleIdByPlate('__HIMO_COMPAT_HEALTH__')
        return true, 'plate-api'
    end)

    checks.oxinv, details.oxinv = safeProbe(function()
        if GetResourceState('ox_inventory') ~= 'started' then return false, 'not-started' end
        local inventory = exports.ox_inventory:GetInventory(source)
        return type(inventory) == 'table', 'player-inventory'
    end)

    checks.qbinv, details.qbinv = safeProbe(function()
        if GetResourceState('qb-inventory') ~= 'started' then return false, 'not-started' end
        return exports['qb-inventory']:Health(source)
    end)

    checks.jim, details.jim = safeProbe(function()
        if GetResourceState('jim_bridge') ~= 'started' then return false, 'not-started' end
        local cache = exports.jim_bridge:GetSharedData()
        if type(cache) ~= 'table' then return false, 'cache-not-table' end
        if type(cache.Items) ~= 'table' then return false, 'items-missing' end
        if type(cache.Jobs) ~= 'table' then return false, 'jobs-missing' end
        return true, 'shared-cache'
    end)

    local clientReport
    local clientOk, clientErr = pcall(function()
        clientReport = lib.callback.await('himo:compat:clientHealth', source)
    end)
    if not clientOk or type(clientReport) ~= 'table' then
        clientReport = { callback = { ok = false, detail = clientOk and 'invalid-report' or tostring(clientErr) } }
    end

    respond(source, ('compat server | qb=%s | qbx=%s | vehicles=%s | oxinv=%s | qbinv=%s | jim=%s'):format(
        boolText(checks.qb), boolText(checks.qbx), boolText(checks.vehicles),
        boolText(checks.oxinv), boolText(checks.qbinv), boolText(checks.jim)
    ))

    local clientNames = { 'qb_core', 'qbx_core', 'qb_callback', 'ox_inventory', 'ox_target', 'qb_inventory', 'qb_target', 'qb_menu', 'qb_input', 'progressbar' }
    local clientParts = {}
    local allClient = true
    for _, name in ipairs(clientNames) do
        local result = clientReport[name]
        local passed = type(result) == 'table' and result.ok == true
        clientParts[#clientParts + 1] = ('%s=%s'):format(name:gsub('_', ''), boolText(passed))
        if not passed then allClient = false end
    end
    if clientReport.callback and clientReport.callback.ok == false then
        allClient = false
        clientParts[#clientParts + 1] = 'callback=false'
    end
    respond(source, 'compat client | ' .. table.concat(clientParts, ' | '))

    local failures = {}
    for name, passed in pairs(checks) do
        if not passed then failures[#failures + 1] = ('server:%s(%s)'):format(name, details[name] or 'failed') end
    end
    for name, result in pairs(clientReport) do
        if type(result) == 'table' and result.ok == false then
            failures[#failures + 1] = ('client:%s(%s)'):format(name, result.detail or 'failed')
        end
    end

    if #failures == 0 and allClient then
        respond(source, 'COMPAT TEST PASS | QB + QBX + callbacks + vehicles + ox_inventory + ox_target + Jim + helper facades')
    else
        table.sort(failures)
        respond(source, 'COMPAT TEST FAIL | ' .. table.concat(failures, ', '), { 255, 90, 90 })
    end
end)

HimoCommands.register('himocoretest', { permission = 'staff' }, function(source, args, raw, respond)
    local target = tonumber(args[1]) or tonumber(source)
    if not target or target == 0 then
        respond(source, 'Usage in-game: /himocoretest [serverId]')
        return
    end

    local failures = {}
    local player = exports['himo_core']:GetPlayer(target)
    local character = exports['himo_core']:GetCharacter(target)
    local session = HimoSessions.get(target)

    if not player then failures[#failures + 1] = 'player-object' end
    if not character then failures[#failures + 1] = 'character' end
    if not session or not session.active then failures[#failures + 1] = 'session' end
    if not exports['himo_core']:IsPlayerLoaded(target) then failures[#failures + 1] = 'world-ready' end
    if HimoState.getPlayer(target, 'himo:characterLoaded') ~= true then failures[#failures + 1] = 'character-statebag' end
    if HimoState.getPlayer(target, 'himo:playerLoaded') ~= true then failures[#failures + 1] = 'ready-statebag' end

    if player then
        if not player.Functions.GetPrimaryJob() then failures[#failures + 1] = 'primary-job' end
        if player.Functions.GetMetadata('hunger', nil) == nil then failures[#failures + 1] = 'metadata' end
        if type(player.Functions.GetGroups()) ~= 'table' then failures[#failures + 1] = 'groups' end
    end

    if #failures == 0 then
        respond(source, ('CORE TEST PASS | player %d | %s | schema %d | session %s'):format(
            target, character.citizen_id, HimoDatabase.schemaVersion or 0,
            session and session.token or 'none'
        ))
    else
        respond(source, ('CORE TEST FAIL | player %d | %s'):format(target, table.concat(failures, ', ')))
    end
end)
