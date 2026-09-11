local function playerData()
    local ok, data = pcall(function()
        return exports['qb-core']:GetPlayerData()
    end)
    return ok and type(data) == 'table' and data or {}
end

local function shared(namespace)
    local ok, data = pcall(function()
        return exports['qb-core']:GetShared(namespace)
    end)
    return ok and type(data) == 'table' and data or {}
end

local function groups(primaryOnly)
    local data = playerData()
    local result = {}
    if data.job and data.job.name then result[data.job.name] = tonumber(data.job.grade and data.job.grade.level) or 0 end
    if data.gang and data.gang.name then result[data.gang.name] = tonumber(data.gang.grade and data.gang.grade.level) or 0 end

    if not primaryOnly then
        for _, row in ipairs(exports.himo_core:GetJobs() or {}) do
            if row.job_name then result[row.job_name] = tonumber(row.grade) or 0 end
        end
        for _, row in ipairs(exports.himo_core:GetGroups() or {}) do
            if row.group_name then result[row.group_name] = tonumber(row.grade) or 0 end
        end
    end
    return result, data.citizenid
end

local function matches(filter, primaryOnly)
    local current, citizenId = groups(primaryOnly)
    if type(filter) == 'string' then
        return filter == citizenId or current[filter] ~= nil
    elseif type(filter) == 'table' then
        if #filter > 0 then
            for _, value in ipairs(filter) do
                if value == citizenId or current[value] ~= nil then return true end
            end
            return false
        end
        for name, requiredGrade in pairs(filter) do
            if name == citizenId then return true end
            local grade = current[name]
            if grade ~= nil and grade >= (tonumber(requiredGrade) or 0) then return true end
        end
    end
    return false
end

local function publishGroups(groupName, groupGrade)
    local snapshot = groups(false)

    TriggerEvent('qbx_core:client:setGroups', snapshot)

    if groupName then
        TriggerEvent('qbx_core:client:onGroupUpdate', groupName, groupGrade)
    end
end

exports('GetPlayerData', playerData)
exports('GetGroups', function()
    local current = groups(false)
    return current
end)
exports('HasGroup', function(filter) return matches(filter, false) end)
exports('HasPrimaryGroup', function(filter) return matches(filter, true) end)
exports('GetJobs', function() return shared('Jobs') end)
exports('GetGangs', function() return shared('Gangs') end)
exports('GetJob', function(name) return shared('Jobs')[name] end)
exports('GetGang', function(name) return shared('Gangs')[name] end)
exports('GetVehiclesByName', function(vehicle)
    local vehicles = shared('Vehicles')
    return vehicle and vehicles[vehicle] or vehicles
end)
exports('GetWeapons', function(weapon)
    local weapons = shared('Weapons')
    return weapon and weapons[weapon] or weapons
end)
exports('GetLocations', function() return shared('Locations') end)
exports('Notify', function(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    local description = type(text) == 'table' and (text.text or text.caption) or tostring(text)
    lib.notify({
        title = subTitle,
        description = description,
        type = notifyType or 'inform',
        duration = duration or 5000,
        position = notifyPosition or 'top-right',
        style = notifyStyle,
        icon = notifyIcon,
        iconColor = notifyIconColor
    })
end)

RegisterNetEvent('himo_core:client:characterLoaded', function()
    SetTimeout(0, function()
        publishGroups()
    end)
end)

RegisterNetEvent('himo_core:client:jobsChanged', function(_, primary)
    publishGroups(primary and primary.job_name or nil, primary and tonumber(primary.grade) or nil)
end)

RegisterNetEvent('himo_core:client:groupsChanged', function(_, primary)
    publishGroups(primary and primary.group_name or nil, primary and tonumber(primary.grade) or nil)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= 'ox_inventory' then return end
    SetTimeout(250, function()
        publishGroups()
    end)
end)
