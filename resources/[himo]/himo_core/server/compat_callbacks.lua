CreateThread(function()
    local deadline = GetGameTimer() + 30000
    while GetResourceState('qb-core') ~= 'started' and GetGameTimer() < deadline do Wait(250) end
    if GetResourceState('qb-core') ~= 'started' then
        print('[HimotheeCompat] QB callback health probe not registered: qb-core did not start in time.')
        return
    end

    local ok, registered = pcall(function()
        return exports['qb-core']:CreateCallback('himo:compat:ping', function(source, cb, value)
            cb(value == 'ping' and 'pong' or 'invalid')
        end)
    end)

    if not ok then
        print(('[HimotheeCompat] Failed to register QB callback health probe: %s'):format(tostring(registered)))
    elseif registered ~= true then
        print(('[HimotheeCompat] QB callback health probe registration returned %s.'):format(tostring(registered)))
    else
        print('[HimotheeCompat] QB callback health probe registered.')
    end
end)
