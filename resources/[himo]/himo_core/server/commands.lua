HimoCommands = HimoCommands or { registered = {} }

local function respond(source, message, color)
    if source == 0 then
        print(('[HimotheeCore] %s'):format(message))
        return
    end

    TriggerClientEvent('chat:addMessage', source, {
        color = color or { 173, 92, 255 },
        args = { 'HimotheeCore', tostring(message) }
    })
end

function HimoCommands.register(name, options, handler)
    name = tostring(name or ''):lower()
    if name == '' or type(handler) ~= 'function' then return false end
    if HimoCommands.registered[name] then return false end

    options = type(options) == 'table' and options or {}
    HimoCommands.registered[name] = true

    RegisterCommand(name, function(source, args, raw)
        local permission = options.permission
        if permission and not HimoPermissions.has(source, permission) then
            respond(source, ('Permission denied: himo.%s'):format(permission:gsub('^himo%.', '')), { 255, 90, 90 })
            return
        end

        local ok, err = pcall(handler, source, args, raw, respond)
        if not ok then
            HimoLogger.error(('Command /%s failed: %s'):format(name, err))
            respond(source, 'Command failed. Check the server console.', { 255, 90, 90 })
        end
    end, false)

    return true
end

exports('RegisterFrameworkCommand', HimoCommands.register)
