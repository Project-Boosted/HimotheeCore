HimoPermissions = HimoPermissions or {}

local roleCache = {}

local function normalize(permission)
    permission = tostring(permission or '')
    if permission == '' then return nil end
    if permission:sub(1, 5) == 'himo.' then return permission end
    return 'himo.' .. permission
end

local function sourceKey(source)
    return tonumber(source) or source
end

local function loadAccount(accountId)
    accountId = tonumber(accountId)
    if not accountId then return { roles = {}, permissions = {} } end
    if roleCache[accountId] then return roleCache[accountId] end

    local rows = MySQL.query.await([[
        SELECT ar.`role_name`, rp.`permission`
        FROM `himo_account_roles` ar
        LEFT JOIN `himo_role_permissions` rp ON rp.`role_name` = ar.`role_name`
        WHERE ar.`account_id` = ?
    ]], { accountId }) or {}

    local data = { roles = {}, permissions = {} }
    for _, row in ipairs(rows) do
        data.roles[row.role_name] = true
        if row.permission then data.permissions[row.permission] = true end
    end

    roleCache[accountId] = data
    return data
end

function HimoPermissions.invalidate(accountId)
    if accountId then roleCache[tonumber(accountId)] = nil else roleCache = {} end
end

-- Runtime bootstrap is intentionally owned by the framework, not the SQL migration.
-- This works for both a fresh server and an upgraded development database whose
-- txAdmin master account is not linked to a FiveM provider identifier.
function HimoPermissions.ensureOwner()
    if GetConvarInt('himo:autoBootstrapOwner', 1) ~= 1 then
        return false, nil, 'Owner bootstrap is disabled.'
    end

    local existingOwner = MySQL.scalar.await([[
        SELECT `account_id`
        FROM `himo_account_roles`
        WHERE `role_name` = 'owner'
        ORDER BY `account_id` ASC
        LIMIT 1
    ]])
    if existingOwner then
        return true, tonumber(existingOwner), 'existing'
    end

    local firstAccountId = MySQL.scalar.await([[
        SELECT `id`
        FROM `himo_accounts`
        ORDER BY `id` ASC
        LIMIT 1
    ]])
    firstAccountId = tonumber(firstAccountId)
    if not firstAccountId then
        return false, nil, 'No Himothee account exists yet.'
    end

    local inserted = MySQL.insert.await([[
        INSERT IGNORE INTO `himo_account_roles`
            (`account_id`, `role_name`, `granted_by_account_id`)
        VALUES (?, 'owner', NULL)
    ]], { firstAccountId })

    -- INSERT IGNORE may return 0 if another thread won the race; resolve again.
    local ownerAccountId = MySQL.scalar.await([[
        SELECT `account_id`
        FROM `himo_account_roles`
        WHERE `role_name` = 'owner'
        ORDER BY `account_id` ASC
        LIMIT 1
    ]])
    ownerAccountId = tonumber(ownerAccountId)
    if not ownerAccountId then
        return false, nil, 'Could not create the initial owner role.'
    end

    HimoPermissions.invalidate(ownerAccountId)
    if inserted and tonumber(inserted) and tonumber(inserted) > 0 then
        HimoLogger.info(('Bootstrapped Himothee owner role for account %d.'):format(ownerAccountId))
    end
    return true, ownerAccountId, 'bootstrapped'
end

function HimoPermissions.bootstrapOwner(accountId)
    accountId = tonumber(accountId)
    if not accountId then return false end
    local ok, ownerAccountId = HimoPermissions.ensureOwner()
    return ok and ownerAccountId == accountId
end

function HimoPermissions.hasAccount(accountId, permission)
    local ace = normalize(permission)
    if not ace then return false end
    local data = loadAccount(accountId)
    return data.permissions['himo.*'] == true or data.permissions[ace] == true
end

function HimoPermissions.has(source, permission)
    source = sourceKey(source)
    if source == 0 then return true end

    local ace = normalize(permission)
    if not ace then return false end

    if IsPlayerAceAllowed(source, ace) == true then return true end

    local accountId = HimoAccounts and HimoAccounts[source] or nil
    if not accountId then return false end
    return HimoPermissions.hasAccount(accountId, ace)
end

function HimoPermissions.any(source, permissions)
    if type(permissions) == 'string' then return HimoPermissions.has(source, permissions) end
    if type(permissions) ~= 'table' then return false end
    for _, permission in ipairs(permissions) do
        if HimoPermissions.has(source, permission) then return true end
    end
    return false
end

function HimoPermissions.getRoles(source)
    source = sourceKey(source)
    local accountId = HimoAccounts and HimoAccounts[source] or nil
    if not accountId then return {} end
    local data = loadAccount(accountId)
    local roles = {}
    for role in pairs(data.roles) do roles[#roles + 1] = role end
    table.sort(roles)
    return roles
end

function HimoPermissions.grantRole(targetAccountId, roleName, grantedByAccountId)
    targetAccountId = tonumber(targetAccountId)
    grantedByAccountId = tonumber(grantedByAccountId)
    roleName = tostring(roleName or ''):lower()
    if not targetAccountId or roleName == '' then return false, 'Account and role are required.' end

    local exists = MySQL.scalar.await('SELECT 1 FROM `himo_roles` WHERE `name` = ? LIMIT 1', { roleName })
    if not exists then return false, 'Unknown role.' end

    MySQL.insert.await([[
        INSERT INTO `himo_account_roles` (`account_id`, `role_name`, `granted_by_account_id`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE `granted_by_account_id` = VALUES(`granted_by_account_id`), `granted_at` = CURRENT_TIMESTAMP
    ]], { targetAccountId, roleName, grantedByAccountId })
    HimoPermissions.invalidate(targetAccountId)
    return true
end

function HimoPermissions.revokeRole(targetAccountId, roleName)
    targetAccountId = tonumber(targetAccountId)
    roleName = tostring(roleName or ''):lower()
    if not targetAccountId or roleName == '' then return false, 'Account and role are required.' end

    if roleName == 'owner' then
        local owners = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM `himo_account_roles` WHERE `role_name` = 'owner'")) or 0
        if owners <= 1 then return false, 'Cannot remove the last owner.' end
    end

    MySQL.update.await('DELETE FROM `himo_account_roles` WHERE `account_id` = ? AND `role_name` = ?', { targetAccountId, roleName })
    HimoPermissions.invalidate(targetAccountId)
    return true
end

function HimoPermissions.require(source, permission)
    if HimoPermissions.has(source, permission) then return true end
    TriggerClientEvent('chat:addMessage', source, {
        color = { 255, 90, 90 },
        args = { 'HimotheeCore', ('Permission denied: %s'):format(normalize(permission) or 'unknown') }
    })
    return false
end

exports('HasPermission', HimoPermissions.has)
exports('HasAnyPermission', HimoPermissions.any)
exports('GetRoles', HimoPermissions.getRoles)
exports('GrantRole', HimoPermissions.grantRole)
exports('RevokeRole', HimoPermissions.revokeRole)
