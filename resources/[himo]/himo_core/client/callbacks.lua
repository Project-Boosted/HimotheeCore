local registered = {}

local function fullName(name)
    name = tostring(name or '')
    if name == '' then return nil end
    if name:sub(1, 5) == 'himo:' then return name end
    return 'himo:' .. name
end

exports('AwaitServerCallback', function(name, ...)
    local callbackName = fullName(name)
    if not callbackName then return nil end
    return lib.callback.await(callbackName, false, ...)
end)

exports('RegisterClientCallback', function(name, handler)
    local callbackName = fullName(name)
    if not callbackName or type(handler) ~= 'function' then return false end
    if registered[callbackName] then return false end

    registered[callbackName] = true
    lib.callback.register(callbackName, handler)
    return true
end)
