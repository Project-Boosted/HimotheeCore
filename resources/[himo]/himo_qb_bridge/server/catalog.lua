CreateThread(function()
    while GlobalState['himothee_core:ready'] ~= true do Wait(100) end

    local core = exports['himo_qb_bridge']:GetCoreObject()
    local jobs = exports.himo_core:GetJobDefinitions() or {}
    local gangs = exports.himo_core:GetGroupDefinitions('gang') or {}

    core.Shared.Jobs = jobs
    core.Shared.Gangs = gangs
    core.Shared.Jobs.unemployed = core.Shared.Jobs.unemployed or {
        label = 'Unemployed', type = 'none', defaultDuty = false,
        grades = { [0] = { name = 'Unemployed', payment = 0, isboss = false } }
    }
    core.Shared.Gangs.none = core.Shared.Gangs.none or {
        label = 'No Gang', grades = { [0] = { name = 'none', isboss = false } }
    }

    TriggerClientEvent('himo_qb_bridge:client:setShared', -1, core.Shared.Jobs, core.Shared.Gangs)
end)

RegisterNetEvent('himo_qb_bridge:server:requestShared', function()
    local src = source
    local core = exports['himo_qb_bridge']:GetCoreObject()
    TriggerClientEvent('himo_qb_bridge:client:setShared', src, core.Shared.Jobs or {}, core.Shared.Gangs or {})
end)
