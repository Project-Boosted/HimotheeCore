RegisterNetEvent('himo_qb_bridge:client:setShared', function(jobs, gangs, items, vehicles)
    local core = exports['himo_qb_bridge']:GetCoreObject()
    core.Shared.Jobs = type(jobs) == 'table' and jobs or core.Shared.Jobs or {}
    core.Shared.Gangs = type(gangs) == 'table' and gangs or core.Shared.Gangs or {}
    core.Shared.Items = type(items) == 'table' and items or core.Shared.Items or {}
    core.Shared.Vehicles = type(vehicles) == 'table' and vehicles or core.Shared.Vehicles or {}
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('himo_qb_bridge:server:requestShared')
end)
