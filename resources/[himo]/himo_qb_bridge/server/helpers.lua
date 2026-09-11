local QBCore = exports['himo_qb_bridge']:GetCoreObject()

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$') or ''
end

local function round(value, decimals)
    value = tonumber(value) or 0
    decimals = tonumber(decimals) or 0
    local power = 10 ^ decimals
    return math.floor(value * power + 0.5) / power
end

QBCore.Shared.Trim = trim
QBCore.Shared.Round = round

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

-- Project Sloth expects the real FiveM identifier requested by type. The base
-- Himothee player object deliberately uses citizen_id as its framework identity,
-- so expose QBCore's identifier contract separately here.
QBCore.Functions.GetIdentifier = function(source, idType)
    source = tonumber(source) or source
    idType = tostring(idType or 'license'):lower()

    local ok, identifier = pcall(GetPlayerIdentifierByType, source, idType)
    if ok and identifier and identifier ~= '' then return identifier end

    local prefix = idType .. ':'
    for _, value in ipairs(GetPlayerIdentifiers(source) or {}) do
        if value:sub(1, #prefix) == prefix then return value end
    end
    return nil
end

local permissionMap = {
    mod = 'staff',
    admin = 'admin',
    god = 'admin',
    staff = 'staff',
    dev = 'dev',
    owner = 'owner',
}

local function hasOnePermission(source, permission)
    permission = tostring(permission or ''):lower()
    if permission == '' then return false end

    -- Respect native qbcore.* ACEs too, because txAdmin/server.cfg installations
    -- may already grant them. Himothee roles remain the persistent authority.
    if IsPlayerAceAllowed(source, 'qbcore.' .. permission) then return true end

    local mapped = permissionMap[permission] or permission
    return exports.himo_core:HasPermission(source, mapped) == true
end

QBCore.Functions.HasPermission = function(source, permission)
    if type(permission) == 'table' then
        for _, value in pairs(permission) do
            if hasOnePermission(source, value) then return true end
        end
        return false
    end
    return hasOnePermission(source, permission)
end

local rawGetPlayer = QBCore.Functions.GetPlayer
local rawGetQBPlayers = QBCore.Functions.GetQBPlayers
local rawGetPlayerByCitizenId = QBCore.Functions.GetPlayerByCitizenId

local function decoratePlayer(player, source)
    if not player or type(player) ~= 'table' then return player end
    player.PlayerData = player.PlayerData or {}
    source = tonumber(source or player.PlayerData.source) or source or player.PlayerData.source

    player.PlayerData.source = source
    player.PlayerData.license = QBCore.Functions.GetIdentifier(source, 'license')
    player.PlayerData.name = GetPlayerName(source) or player.PlayerData.name or ''
    if player.PlayerData.optin == nil then player.PlayerData.optin = true end
    return player
end

QBCore.Functions.GetPlayer = function(source)
    return decoratePlayer(rawGetPlayer(source), source)
end

QBCore.Functions.GetQBPlayers = function()
    local players = rawGetQBPlayers() or {}
    for source, player in pairs(players) do
        decoratePlayer(player, source)
    end
    return players
end

QBCore.Functions.GetPlayerByCitizenId = function(citizenId)
    local player = rawGetPlayerByCitizenId(citizenId)
    return decoratePlayer(player, player and player.PlayerData and player.PlayerData.source)
end

-- Match QBCore's admin-duty contract. New sessions default to opted in, just as
-- upstream QBCore does, while the value can still be toggled for the session.
QBCore.Functions.IsOptin = function(source)
    if not QBCore.Functions.GetIdentifier(source, 'license') then return false end
    if not QBCore.Functions.HasPermission(source, 'admin') then return false end
    local player = QBCore.Functions.GetPlayer(source)
    return player ~= nil and player.PlayerData.optin ~= false
end

QBCore.Functions.ToggleOptin = function(source)
    if not QBCore.Functions.GetIdentifier(source, 'license') then return false end
    if not QBCore.Functions.HasPermission(source, 'admin') then return false end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end

    local nextValue = player.PlayerData.optin == false
    local success = player.Functions.SetPlayerData('optin', nextValue)
    if success then player.PlayerData.optin = nextValue end
    return success == true, nextValue
end

-- ps-adminmenu's Set Perms action expects QBCore permission names. Persist them
-- through Himothee's native role system and also add the conventional QB ACE for
-- the current session. "god" intentionally maps to admin, not framework owner.
QBCore.Functions.AddPermission = function(source, permission)
    source = tonumber(source) or source
    permission = tostring(permission or ''):lower()
    local role = permissionMap[permission]
    if not role then return false end

    local character = exports.himo_core:GetCharacter(source)
    local accountId = character and tonumber(character.account_id)
    if not accountId then return false end

    local ok, granted = pcall(function()
        return exports.himo_core:GrantRole(accountId, role, nil)
    end)
    if not ok or granted ~= true then return false end

    ExecuteCommand(('add_principal player.%s qbcore.%s'):format(source, permission))
    return true
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
