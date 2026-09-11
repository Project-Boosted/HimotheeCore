local VERSION = '1.23.0'

local function qb()
    return exports['qb-core']:GetCoreObject()
end

local function hasEntries(value)
    return type(value) == 'table' and next(value) ~= nil
end

local function fallbackJobs()
    return {
        unemployed = {
            label = 'Unemployed', type = 'none', defaultDuty = false, offDutyPay = false,
            grades = { [0] = { name = 'Unemployed', label = 'Unemployed', payment = 0, isboss = false } }
        }
    }
end

local function fallbackGangs()
    return {
        none = {
            label = 'No Gang', type = 'gang',
            grades = { [0] = { name = 'none', label = 'none', isboss = false } }
        }
    }
end

local function sharedCatalog(namespace)
    local authoritative = exports.himo_qb_bridge:GetSharedCatalog(namespace)
    if hasEntries(authoritative) then return authoritative end

    if namespace == 'Jobs' then
        local native = exports.himo_core:GetJobDefinitions() or {}
        if hasEntries(native) then
            exports.himo_qb_bridge:SetSharedCatalog('Jobs', native)
            return native
        end
        return fallbackJobs()
    end

    if namespace == 'Gangs' then
        local native = exports.himo_core:GetGroupDefinitions('gang') or {}
        if hasEntries(native) then
            exports.himo_qb_bridge:SetSharedCatalog('Gangs', native)
            return native
        end
        return fallbackGangs()
    end

    local object = qb()
    local shared = object and object.Shared and object.Shared[namespace]
    return type(shared) == 'table' and shared or {}
end

local function vehicleCatalog()
    local authoritative = exports.himo_qb_bridge:GetSharedCatalog('Vehicles')
    if hasEntries(authoritative) then return authoritative end

    local ok, loaded = pcall(function()
        return exports.qbx_core:GetLoadedVehicleCatalog()
    end)
    if ok and hasEntries(loaded) then return loaded end

    local object = qb()
    return object and object.Shared and object.Shared.Vehicles or {}
end

local function resolveSource(identifier)
    if type(identifier) == 'number' then return identifier end
    local numeric = tonumber(identifier)
    if numeric and GetPlayerName(numeric) then return numeric end

    if type(identifier) == 'string' then
        local object = qb()
        local byCitizen = object.Functions.GetPlayerByCitizenId(identifier)
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
    if not source then return nil end
    return qb().Functions.GetPlayer(source)
end

local function combinedGroups(source)
    local result = {}
    for _, row in ipairs(exports.himo_core:GetJobs(source) or {}) do
        if row.job_name then result[row.job_name] = tonumber(row.grade) or 0 end
    end
    for _, row in ipairs(exports.himo_core:GetGroups(source) or {}) do
        if row.group_name then result[row.group_name] = tonumber(row.grade) or 0 end
    end
    return result
end

local function matchesFilter(source, filter, primaryOnly)
    local player = getPlayer(source)
    if not player then return false end
    local groups = combinedGroups(source)

    if primaryOnly then
        groups = {}
        local job, gang = player.PlayerData.job, player.PlayerData.gang
        if job and job.name then groups[job.name] = tonumber(job.grade and job.grade.level) or 0 end
        if gang and gang.name then groups[gang.name] = tonumber(gang.grade and gang.grade.level) or 0 end
    end

    if type(filter) == 'string' then
        return filter == player.PlayerData.citizenid or groups[filter] ~= nil
    end
    if type(filter) ~= 'table' then return false end

    if #filter > 0 then
        for _, value in ipairs(filter) do
            if value == player.PlayerData.citizenid or groups[value] ~= nil then return true end
        end
        return false
    end

    for name, requiredGrade in pairs(filter) do
        if name == player.PlayerData.citizenid then return true end
        local grade = groups[name]
        if grade ~= nil and grade >= (tonumber(requiredGrade) or 0) then return true end
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
exports('GetPlayerByCitizenId', function(citizenId) return qb().Functions.GetPlayerByCitizenId(citizenId) end)
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
exports('GetQBPlayers', function() return qb().Functions.GetQBPlayers() end)
exports('GetPlayersData', function()
    local data = {}
    for _, player in pairs(qb().Functions.GetQBPlayers()) do data[#data + 1] = player.PlayerData end
    return data
end)

exports('GetJobs', function() return sharedCatalog('Jobs') end)
exports('GetGangs', function() return sharedCatalog('Gangs') end)
exports('GetJob', function(name)
    local jobs = sharedCatalog('Jobs')
    return jobs[name]
end)
exports('GetGang', function(name)
    local gangs = sharedCatalog('Gangs')
    return gangs[name]
end)
exports('GetVehiclesByName', function(vehicle)
    local vehicles = vehicleCatalog()
    return vehicle and vehicles[vehicle] or vehicles
end)
exports('GetWeapons', function(weapon)
    local weapons = sharedCatalog('Weapons')
    return weapon and weapons[weapon] or weapons
end)
exports('GetLocations', function() return sharedCatalog('Locations') end)

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
exports('GetGroups', function(source) return combinedGroups(resolveSource(source) or source) end)
exports('HasGroup', function(source, filter) return matchesFilter(resolveSource(source) or source, filter, false) end)
exports('HasPrimaryGroup', function(source, filter) return matchesFilter(resolveSource(source) or source, filter, true) end)
exports('IsGradeBoss', function(groupName, grade)
    grade = tonumber(grade) or 0
    local group = sharedCatalog('Jobs')[groupName] or sharedCatalog('Gangs')[groupName]
    local gradeData = group and group.grades and (group.grades[grade] or group.grades[tostring(grade)])
    return gradeData and (gradeData.isboss == true or gradeData.isBoss == true) or false
end)

exports('GetDutyCountJob', function(jobName)
    local players, count = {}, 0
    for source, player in pairs(qb().Functions.GetQBPlayers()) do
        local job = player.PlayerData.job
        if job and job.name == jobName and job.onduty then
            count = count + 1
            players[#players + 1] = source
        end
    end
    return count, players
end)
exports('GetDutyCountType', function(jobType)
    local players, count = {}, 0
    for source, player in pairs(qb().Functions.GetQBPlayers()) do
        local job = player.PlayerData.job
        if job and job.type == jobType and job.onduty then
            count = count + 1
            players[#players + 1] = source
        end
    end
    return count, players
end)

exports('CreateUseableItem', function(itemName, cb) return qb().Functions.CreateUseableItem(itemName, cb) end)
exports('CanUseItem', function(itemName) return qb().Functions.CanUseItem(itemName) end)
exports('HasPermission', function(source, permission) return qb().Functions.HasPermission(source, permission) end)
exports('Notify', function(source, text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    local description = type(text) == 'table' and (text.caption or text.text) or tostring(text)
    TriggerClientEvent('ox_lib:notify', source, {
        title = subTitle, description = description, type = notifyType or 'inform', duration = duration or 5000,
        position = notifyPosition or 'top-right', style = notifyStyle, icon = notifyIcon, iconColor = notifyIconColor
    })
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
    local players = {}
    for _, source in ipairs(GetPlayers()) do
        source = tonumber(source)
        players[source] = GetPlayerRoutingBucket(source)
    end
    return players, {}
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
        if GetEntityRoutingBucket(entity) == bucket then entities[#entities + 1] = entity end
    end
    for _, entity in ipairs(GetAllVehicles()) do
        if GetEntityRoutingBucket(entity) == bucket then entities[#entities + 1] = entity end
    end
    return #entities > 0 and entities or false
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
