local QB = exports['qb-core']:GetCoreObject()
local VERSION = '1.23.0'

local function resolveSource(identifier)
    if type(identifier) == 'number' then return identifier end
    local numeric = tonumber(identifier)
    if numeric and GetPlayerName(numeric) then return numeric end

    if type(identifier) == 'string' then
        local byCitizen = QB.Functions.GetPlayerByCitizenId(identifier)
        if byCitizen and byCitizen.PlayerData then return byCitizen.PlayerData.source end

        for _, source in ipairs(GetPlayers()) do
            local src = tonumber(source)
            for _, playerIdentifier in ipairs(GetPlayerIdentifiers(src)) do
                if playerIdentifier == identifier then return src end
            end
        end
    end
end

local function getPlayer(identifier)
    local source = resolveSource(identifier)
    return source and QB.Functions.GetPlayer(source) or nil
end

local function combinedGroups(source)
    local result = {}
    for _, row in ipairs(exports.himo_core:GetJobs(source) or {}) do
        result[row.job_name] = tonumber(row.grade) or 0
    end
    for _, row in ipairs(exports.himo_core:GetGroups(source) or {}) do
        result[row.group_name] = tonumber(row.grade) or 0
    end
    return result
end

local function matchesFilter(source, filter, primaryOnly)
    local player = getPlayer(source)
    if not player then return false end
    local citizenId = player.PlayerData.citizenid
    local groups = combinedGroups(source)

    if primaryOnly then
        groups = {}
        local job, gang = player.PlayerData.job, player.PlayerData.gang
        if job and job.name then groups[job.name] = tonumber(job.grade and job.grade.level) or 0 end
        if gang and gang.name then groups[gang.name] = tonumber(gang.grade and gang.grade.level) or 0 end
    end

    if type(filter) == 'string' then
        return filter == citizenId or groups[filter] ~= nil
    elseif type(filter) == 'table' then
        if #filter > 0 then
            for _, value in ipairs(filter) do
                if value == citizenId or groups[value] ~= nil then return true end
            end
            return false
        end
        for name, requiredGrade in pairs(filter) do
            if name == citizenId then return true end
            local grade = groups[name]
            if grade ~= nil and grade >= (tonumber(requiredGrade) or 0) then return true end
        end
    end
    return false
end

exports('GetCoreVersion', function() return VERSION end)
exports('GetSource', function(identifier) return resolveSource(identifier) or 0 end)
exports('GetUserId', function(identifier)
    local source = resolveSource(identifier)
    return source and (exports.himo_core:GetAccountId(source) or 0) or 0
end)
exports('GetPlayer', getPlayer)
exports('GetPlayerByCitizenId', function(citizenId) return QB.Functions.GetPlayerByCitizenId(citizenId) end)
exports('GetPlayerByUserId', function(userId)
    userId = tonumber(userId)
    if not userId then return nil end
    for _, source in ipairs(GetPlayers()) do
        local src = tonumber(source)
        if exports.himo_core:GetAccountId(src) == userId then return getPlayer(src) end
    end
end)
exports('GetPlayerByPhone', function(number)
    number = tostring(number or '')
    for _, source in ipairs(GetPlayers()) do
        local player = getPlayer(tonumber(source))
        if player and player.PlayerData.charinfo and player.PlayerData.charinfo.phone == number then return player end
    end
end)
exports('GetQBPlayers', function() return QB.Functions.GetQBPlayers() end)
exports('GetPlayersData', function()
    local data = {}
    for _, player in pairs(QB.Functions.GetQBPlayers()) do data[#data + 1] = player.PlayerData end
    return data
end)

exports('GetJobs', function() return QB.Shared.Jobs or {} end)
exports('GetGangs', function() return QB.Shared.Gangs or {} end)
exports('GetJob', function(name) return QB.Shared.Jobs and QB.Shared.Jobs[name] or nil end)
exports('GetGang', function(name) return QB.Shared.Gangs and QB.Shared.Gangs[name] or nil end)
exports('GetVehiclesByName', function(vehicle)
    local vehicles = QB.Shared.Vehicles or {}
    return vehicle and vehicles[vehicle] or vehicles
end)
exports('GetWeapons', function(weapon)
    local weapons = QB.Shared.Weapons or {}
    return weapon and weapons[weapon] or weapons
end)
exports('GetLocations', function() return QB.Shared.Locations or {} end)

exports('GetMetadata', function(identifier, key)
    local player = getPlayer(identifier)
    return player and player.Functions.GetMetaData(key) or nil
end)
exports('SetMetadata', function(identifier, key, value)
    local player = getPlayer(identifier)
    return player and player.Functions.SetMetaData(key, value) or false
end)

exports('SetJobDuty', function(identifier, onDuty)
    local player = getPlayer(identifier)
    return player and player.Functions.SetJobDuty(onDuty == true) or false
end)
exports('SetJob', function(identifier, jobName, grade)
    local player = getPlayer(identifier)
    return player and player.Functions.SetJob(jobName, tonumber(grade) or 0) or false
end)
exports('AddPlayerToJob', function(citizenId, jobName, grade)
    local source = resolveSource(citizenId)
    return source and exports.himo_core:AddJob(source, jobName, tonumber(grade) or 0, false) or false
end)
exports('RemovePlayerFromJob', function(citizenId, jobName)
    local source = resolveSource(citizenId)
    return source and exports.himo_core:RemoveJob(source, jobName) or false
end)
exports('SetPlayerPrimaryJob', function(citizenId, jobName)
    local source = resolveSource(citizenId)
    return source and exports.himo_core:SetPrimaryJob(source, jobName) or false
end)

exports('SetGang', function(identifier, gangName, grade)
    local player = getPlayer(identifier)
    return player and player.Functions.SetGang(gangName, tonumber(grade) or 0) or false
end)
exports('AddPlayerToGang', function(citizenId, gangName, grade)
    local source = resolveSource(citizenId)
    return source and exports.himo_core:AddGroup(source, gangName, tonumber(grade) or 0, false) or false
end)
exports('RemovePlayerFromGang', function(citizenId, gangName)
    local source = resolveSource(citizenId)
    return source and exports.himo_core:RemoveGroup(source, gangName) or false
end)
exports('SetPlayerPrimaryGang', function(citizenId, gangName)
    local source = resolveSource(citizenId)
    return source and exports.himo_core:SetPrimaryGroup(source, gangName) or false
end)

exports('GetGroups', function(source)
    source = resolveSource(source) or source
    return combinedGroups(source)
end)
exports('HasGroup', function(source, filter) return matchesFilter(resolveSource(source) or source, filter, false) end)
exports('HasPrimaryGroup', function(source, filter) return matchesFilter(resolveSource(source) or source, filter, true) end)

exports('IsGradeBoss', function(groupName, grade)
    grade = tonumber(grade) or 0
    local group = (QB.Shared.Jobs and QB.Shared.Jobs[groupName]) or (QB.Shared.Gangs and QB.Shared.Gangs[groupName])
    local gradeData = group and group.grades and (group.grades[grade] or group.grades[tostring(grade)])
    return gradeData and (gradeData.isboss == true or gradeData.isBoss == true) or false
end)

exports('GetDutyCountJob', function(jobName)
    local players, count = {}, 0
    for source, player in pairs(QB.Functions.GetQBPlayers()) do
        local job = player.PlayerData.job
        if job and job.name == jobName and job.onduty then count += 1 players[#players + 1] = source end
    end
    return count, players
end)
exports('GetDutyCountType', function(jobType)
    local players, count = {}, 0
    for source, player in pairs(QB.Functions.GetQBPlayers()) do
        local job = player.PlayerData.job
        if job and job.type == jobType and job.onduty then count += 1 players[#players + 1] = source end
    end
    return count, players
end)

exports('CreateUseableItem', function(itemName, cb)
    return QB.Functions.CreateUseableItem(itemName, cb)
end)
exports('CanUseItem', function(itemName)
    return QB.Functions.CanUseItem(itemName)
end)

exports('SetPlayerBucket', function(source, bucket)
    source, bucket = tonumber(source), tonumber(bucket)
    if not source or not bucket then return false end
    local player = Player(source)
    if player and player.state then player.state:set('instance', bucket, true) end
    SetPlayerRoutingBucket(source, bucket)
    return true
end)
exports('SetEntityBucket', function(entity, bucket)
    entity, bucket = tonumber(entity), tonumber(bucket)
    if not entity or not bucket then return false end
    SetEntityRoutingBucket(entity, bucket)
    return true
end)
exports('GetBucketObjects', function()
    local players, entities = {}, {}
    for _, source in ipairs(GetPlayers()) do
        source = tonumber(source)
        players[source] = GetPlayerRoutingBucket(source)
    end
    return players, entities
end)
exports('GetPlayersInBucket', function(bucket)
    bucket = tonumber(bucket)
    if not bucket then return false end
    local players = {}
    for _, source in ipairs(GetPlayers()) do
        source = tonumber(source)
        if GetPlayerRoutingBucket(source) == bucket then players[#players + 1] = source end
    end
    return #players > 0 and players or false
end)
exports('GetEntitiesInBucket', function(bucket)
    bucket = tonumber(bucket)
    if not bucket then return false end
    local entities = {}
    for _, entity in ipairs(GetAllObjects()) do
        if GetEntityRoutingBucket(entity) == bucket then entities[#entities + 1] = entity end
    end
    for _, entity in ipairs(GetAllPeds()) do
        if GetEntityRoutingBucket(entity) == bucket and not IsPedAPlayer(entity) then entities[#entities + 1] = entity end
    end
    for _, entity in ipairs(GetAllVehicles()) do
        if GetEntityRoutingBucket(entity) == bucket then entities[#entities + 1] = entity end
    end
    return #entities > 0 and entities or false
end)

exports('HasPermission', function(source, permission)
    return QB.Functions.HasPermission(source, permission)
end)
exports('Notify', function(source, text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    local description = type(text) == 'table' and (text.caption or text.text) or tostring(text)
    TriggerClientEvent('ox_lib:notify', source, {
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

exports('Save', function(source) return exports.himo_core:SavePlayerPosition(resolveSource(source) or source) end)
exports('Logout', function(source) return exports.himo_core:UnloadCharacter(resolveSource(source) or source) end)

AddEventHandler('himo_core:server:playerLoaded', function(source)
    local state = Player(source).state
    if state then
        state:set('isLoggedIn', true, true)
        state:set('loadInventory', true, true)
    end
    TriggerClientEvent('qbx_core:client:setGroups', source, combinedGroups(source))
end)
AddEventHandler('himo_core:server:characterUnloaded', function(source)
    local state = Player(source).state
    if state then
        state:set('loadInventory', false, true)
        state:set('isLoggedIn', false, true)
    end
    TriggerEvent('qbx_core:server:playerLoggedOut', source)
end)
AddEventHandler('himo_core:server:jobsChanged', function(source, jobs, primary)
    if primary then TriggerEvent('qbx_core:server:onGroupUpdate', source, primary.job_name, tonumber(primary.grade) or 0) end
    TriggerClientEvent('qbx_core:client:setGroups', source, combinedGroups(source))
end)
AddEventHandler('himo_core:server:groupsChanged', function(source, groups, primary)
    if primary then TriggerEvent('qbx_core:server:onGroupUpdate', source, primary.group_name, tonumber(primary.grade) or 0) end
    TriggerClientEvent('qbx_core:client:setGroups', source, combinedGroups(source))
end)
