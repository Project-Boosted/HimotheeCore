local QBCore = exports['himo_qb_bridge']:GetCoreObject()

QBCore.Functions.Notify = function(source, text, notifyType, duration)
    local description = type(text) == 'table' and (text.text or text.caption) or tostring(text)
    TriggerClientEvent('ox_lib:notify', source, {
        description = description,
        type = notifyType or 'inform',
        duration = tonumber(duration) or 5000
    })
end

QBCore.Functions.GetCoords = function(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

QBCore.Functions.GetPlayersOnDuty = function(jobName)
    local count, players = 0, {}
    for source, player in pairs(QBCore.Functions.GetQBPlayers()) do
        local job = player.PlayerData and player.PlayerData.job
        if job and job.name == jobName and job.onduty then
            count = count + 1
            players[#players + 1] = source
        end
    end
    return players, count
end

QBCore.Functions.GetDutyCount = function(jobName)
    local _, count = QBCore.Functions.GetPlayersOnDuty(jobName)
    return count
end

QBCore.Functions.GetBucketObjects = function()
    local ok, players, entities = pcall(function()
        return exports.qbx_core:GetBucketObjects()
    end)
    if ok then return players, entities end
    return {}, {}
end
