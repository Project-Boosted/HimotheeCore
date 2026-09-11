RegisterNetEvent('himo_qb_bridge:client:setShared', function(jobs, gangs)
    local core = exports['himo_qb_bridge']:GetCoreObject()
    core.Shared.Jobs = type(jobs) == 'table' and jobs or core.Shared.Jobs or {}
    core.Shared.Gangs = type(gangs) == 'table' and gangs or core.Shared.Gangs or {}
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('himo_qb_bridge:server:requestShared')
end)
