CreateThread(function()
    local deadline = GetGameTimer() + 30000
    while GetResourceState('qb-core') ~= 'started' and GetGameTimer() < deadline do Wait(250) end
    if GetResourceState('qb-core') ~= 'started' then return end

    local ok, err = pcall(function()
        exports['qb-core']:CreateCallback('himo:compat:ping', function(source, cb, value)
            cb(value == 'ping' and 'pong' or 'invalid')
        end)
    end)

    if not ok then
        print(('[HimotheeCompat] Failed to register QB callback health probe: %s'):format(tostring(err)))
    end
end)
