HimoCallbacks = HimoCallbacks or { registered = {} }

local function fullName(name)
    name = tostring(name or '')
    if name == '' then return nil end
    if name:sub(1, 5) == 'himo:' then return name end
    return 'himo:' .. name
end

function HimoCallbacks.register(name, handler)
    local callbackName = fullName(name)
    if not callbackName or type(handler) ~= 'function' then
        return false, 'A callback name and handler are required.'
    end
    if HimoCallbacks.registered[callbackName] then
        return false, ('Callback %s is already registered.'):format(callbackName)
    end

    HimoCallbacks.registered[callbackName] = true
    lib.callback.register(callbackName, handler)
    return true
end

function HimoCallbacks.awaitClient(name, source, ...)
    local callbackName = fullName(name)
    if not callbackName then return nil, 'Callback name is required.' end
    source = tonumber(source) or source
    return lib.callback.await(callbackName, source, ...)
end

exports('RegisterServerCallback', HimoCallbacks.register)
exports('AwaitClientCallback', HimoCallbacks.awaitClient)
