local permissionMap = {
    mod = 'staff',
    admin = 'admin',
    god = 'admin',
    staff = 'staff',
    dev = 'dev',
    owner = 'owner',
}

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$') or ''
end

local function round(value, decimals)
    value = tonumber(value) or 0
    decimals = tonumber(decimals) or 0
    local power = 10 ^ decimals
    return math.floor(value * power + 0.5) / power
end

local function getIdentifier(source, idType)
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

local function hasOnePermission(source, permission)
    source = tonumber(source) or source
    permission = tostring(permission or ''):lower()
    if permission == '' then return false end

    if IsPlayerAceAllowed(source, 'qbcore.' .. permission) then return true end

    local mapped = permissionMap[permission] or permission
    return exports.himo_core:HasPermission(source, mapped) == true
end

local function hasPermission(source, permission)
    if type(permission) == 'table' then
        for _, value in pairs(permission) do
            if hasOnePermission(source, value) then return true end
        end
        return false
    end
    return hasOnePermission(source, permission)
end

local function notify(source, text, notifyType, duration)
    local description = type(text) == 'table' and (text.text or text.caption) or tostring(text)
    TriggerClientEvent('ox_lib:notify', source, {
        description = description,
        type = notifyType or 'inform',
        duration = tonumber(duration) or 5000
    })
end

local function getCoords(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

local function decoratePlayer(player, source)
    if not player or type(player) ~= 'table' then return player end
    player.PlayerData = player.PlayerData or {}
    source = tonumber(source or player.PlayerData.source) or source or player.PlayerData.source

    player.PlayerData.source = source
    player.PlayerData.license = getIdentifier(source, 'license')
    player.PlayerData.name = GetPlayerName(source) or player.PlayerData.name or ''
    if player.PlayerData.optin == nil then player.PlayerData.optin = true end
    return player
end

local function addPermission(source, permission)
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

local function removePermission(source, permission)
    source = tonumber(source) or source
    permission = tostring(permission or ''):lower()
    local role = permissionMap[permission]
    if not role then return false end

    local character = exports.himo_core:GetCharacter(source)
    local accountId = character and tonumber(character.account_id)
    if not accountId then return false end

    local ok, revoked = pcall(function()
        return exports.himo_core:RevokeRole(accountId, role)
    end)
    if not ok or revoked ~= true then return false end

    ExecuteCommand(('remove_principal player.%s qbcore.%s'):format(source, permission))
    return true
end

local function attachCompatibility(object)
    object = type(object) == 'table' and object or {}
    object.Functions = type(object.Functions) == 'table' and object.Functions or {}
    object.Shared = type(object.Shared) == 'table' and object.Shared or {}

    -- These helpers must be attached in the public qb-core resource itself.
    -- Mutating a CoreObject after importing it from himo_qb_bridge only mutates
    -- the resource-boundary copy, which is why ps-adminmenu previously saw nil.
    object.Shared.Trim = trim
    object.Shared.Round = round

    local rawGetPlayer = object.Functions.GetPlayer
    local rawGetQBPlayers = object.Functions.GetQBPlayers
    local rawGetPlayerByCitizenId = object.Functions.GetPlayerByCitizenId

    object.Functions.GetIdentifier = getIdentifier
    object.Functions.HasPermission = hasPermission
    object.Functions.Notify = notify
    object.Functions.GetCoords = getCoords

    object.Functions.GetPlayer = function(source)
        if not rawGetPlayer then return nil end
        return decoratePlayer(rawGetPlayer(source), source)
    end

    object.Functions.GetQBPlayers = function()
        if not rawGetQBPlayers then return {} end
        local players = rawGetQBPlayers() or {}
        for source, player in pairs(players) do
            decoratePlayer(player, source)
        end
        return players
    end

    object.Functions.GetPlayerByCitizenId = function(citizenId)
        if not rawGetPlayerByCitizenId then return nil end
        local player = rawGetPlayerByCitizenId(citizenId)
        return decoratePlayer(player, player and player.PlayerData and player.PlayerData.source)
    end

    object.Functions.GetOfflinePlayerByCitizenId = function(citizenId)
        return exports.himo_qb_bridge:GetOfflinePlayerByCitizenId(citizenId)
    end

    object.Functions.IsOptin = function(source)
        if not getIdentifier(source, 'license') then return false end
        if not hasPermission(source, 'admin') then return false end
        local player = object.Functions.GetPlayer(source)
        return player ~= nil and player.PlayerData.optin ~= false
    end

    object.Functions.ToggleOptin = function(source)
        if not getIdentifier(source, 'license') then return false end
        if not hasPermission(source, 'admin') then return false end
        local player = object.Functions.GetPlayer(source)
        if not player then return false end

        local nextValue = player.PlayerData.optin == false
        local success = player.Functions.SetPlayerData('optin', nextValue)
        if success then player.PlayerData.optin = nextValue end
        return success == true, nextValue
    end

    object.Functions.AddPermission = addPermission
    object.Functions.RemovePermission = removePermission

    object.Functions.GetPlayersOnDuty = function(jobName)
        local count, players = 0, {}
        for source, player in pairs(object.Functions.GetQBPlayers()) do
            local job = player.PlayerData and player.PlayerData.job
            if job and job.name == jobName and job.onduty then
                count = count + 1
                players[#players + 1] = source
            end
        end
        return players, count
    end

    object.Functions.GetDutyCount = function(jobName)
        local _, count = object.Functions.GetPlayersOnDuty(jobName)
        return count
    end

    object.Functions.GetBucketObjects = function()
        local ok, players, entities = pcall(function()
            return exports.qbx_core:GetBucketObjects()
        end)
        if ok then return players, entities end
        return {}, {}
    end

    return object
end

local function core()
    local object = exports['himo_qb_bridge']:GetCoreObject()
    local authoritative = exports['himo_qb_bridge']:GetSharedCatalog()

    object.Shared = object.Shared or {}
    if type(authoritative) == 'table' then
        for namespace, value in pairs(authoritative) do
            if type(value) == 'table' then
                object.Shared[namespace] = value
            end
        end
    end

    return attachCompatibility(object)
end

exports('GetCoreObject', function()
    return core()
end)

exports('GetShared', function(namespace, item)
    local shared = core().Shared or {}
    local value = shared[namespace]
    if not value then return nil end
    return item and value[item] or value
end)

exports('GetPlayer', function(source)
    return core().Functions.GetPlayer(source)
end)

exports('GetPlayerByCitizenId', function(citizenId)
    return core().Functions.GetPlayerByCitizenId(citizenId)
end)

exports('GetOfflinePlayerByCitizenId', function(citizenId)
    return core().Functions.GetOfflinePlayerByCitizenId(citizenId)
end)

exports('CreateCallback', function(name, cb)
    return core().Functions.CreateCallback(name, cb)
end)

exports('CreateUseableItem', function(itemName, cb)
    return core().Functions.CreateUseableItem(itemName, cb)
end)

exports('CanUseItem', function(itemName)
    return core().Functions.CanUseItem(itemName)
end)
