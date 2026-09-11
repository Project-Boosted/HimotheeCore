local function runProbe(label, fn)
    local ok, result, detail = pcall(fn)
    if not ok then
        return { ok = false, detail = ('%s: %s'):format(label, tostring(result)) }
    end
    if result == false then
        return { ok = false, detail = detail or label }
    end
    return { ok = true, detail = detail or label }
end

local function callbackProbe()
    local core = exports['qb-core']:GetCoreObject()
    if not core or not core.Functions or type(core.Functions.TriggerCallback) ~= 'function' then
        return false, 'TriggerCallback-missing'
    end

    local pending = promise.new()
    local settled = false
    SetTimeout(3000, function()
        if settled then return end
        settled = true
        pending:resolve(false)
    end)

    core.Functions.TriggerCallback('himo:compat:ping', function(value)
        if settled then return end
        settled = true
        pending:resolve(value == 'pong')
    end, 'ping')

    return Citizen.Await(pending) == true, 'round-trip'
end

lib.callback.register('himo:compat:clientHealth', function()
    local report = {}

    report.ox_inventory = runProbe('ox_inventory', function()
        if GetResourceState('ox_inventory') ~= 'started' then return false, 'not-started' end
        local items = exports.ox_inventory:GetPlayerItems()
        return type(items) == 'table', 'player-inventory-loaded'
    end)

    report.ox_target = runProbe('ox_target', function()
        return GetResourceState('ox_target') == 'started', 'started'
    end)

    report.qb_inventory = runProbe('qb-inventory', function()
        return exports['qb-inventory']:Health()
    end)

    report.qb_target = runProbe('qb-target', function()
        return exports['qb-target']:Health()
    end)

    report.qb_menu = runProbe('qb-menu', function()
        return exports['qb-menu']:Health()
    end)

    report.qb_input = runProbe('qb-input', function()
        return exports['qb-input']:Health()
    end)

    report.progressbar = runProbe('progressbar', function()
        return exports.progressbar:Health()
    end)

    report.qb_core = runProbe('qb-core', function()
        local core = exports['qb-core']:GetCoreObject()
        local data = core and core.Functions and core.Functions.GetPlayerData and core.Functions.GetPlayerData()
        return type(data) == 'table' and type(data.citizenid) == 'string', 'PlayerData'
    end)

    report.qbx_core = runProbe('qbx_core', function()
        local data = exports.qbx_core:GetPlayerData()
        return type(data) == 'table' and type(data.citizenid) == 'string', 'PlayerData'
    end)

    report.qb_callback = runProbe('qb-callback', callbackProbe)

    return report
end)
