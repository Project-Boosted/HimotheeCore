local function core()
    return exports['himo_qb_bridge']:GetCoreObject()
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

exports('DrawText', function(text, position)
    lib.showTextUI(tostring(text), { position = position or 'right-center' })
end)

exports('HideText', function()
    lib.hideTextUI()
end)

exports('KeyPressed', function()
    lib.hideTextUI()
end)

exports('ChangeText', function(text, position)
    lib.hideTextUI()
    lib.showTextUI(tostring(text), { position = position or 'right-center' })
end)
