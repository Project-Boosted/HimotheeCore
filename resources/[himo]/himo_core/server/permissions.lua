HimoPermissions = HimoPermissions or {}

local function normalize(permission)
    permission = tostring(permission or '')
    if permission == '' then return nil end
    if permission:sub(1, 5) == 'himo.' then return permission end
    return 'himo.' .. permission
end

function HimoPermissions.has(source, permission)
    source = tonumber(source) or source
    if source == 0 then return true end

    local ace = normalize(permission)
    if not ace then return false end
    return IsPlayerAceAllowed(source, ace) == true
end

function HimoPermissions.any(source, permissions)
    if type(permissions) == 'string' then
        return HimoPermissions.has(source, permissions)
    end
    if type(permissions) ~= 'table' then return false end

    for _, permission in ipairs(permissions) do
        if HimoPermissions.has(source, permission) then return true end
    end
    return false
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
