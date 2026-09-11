local contextId = 'himo_qb_menu_compat'

local function invoke(entry)
    if type(entry.action) == 'function' then
        entry.action()
        return
    end

    local params = type(entry.params) == 'table' and entry.params or {}
    local event = params.event
    if not event then return end

    if params.isServer then
        TriggerServerEvent(event, params.args)
    elseif params.isCommand then
        ExecuteCommand(event)
    elseif params.isQBCommand then
        TriggerServerEvent('QBCore:CallCommand', event, params.args)
    elseif params.isAction and type(event) == 'function' then
        event(params.args)
    elseif type(event) == 'string' then
        TriggerEvent(event, params.args)
    end
end

local function normalise(data, sort, skipFirst)
    local entries = {}
    for index, entry in ipairs(type(data) == 'table' and data or {}) do
        if not entry.hidden then entries[#entries + 1] = { index = index, data = entry } end
    end

    if sort then
        local first
        if skipFirst and #entries > 0 then first = table.remove(entries, 1) end
        table.sort(entries, function(a, b)
            return tostring(a.data.header or '') < tostring(b.data.header or '')
        end)
        if first then table.insert(entries, 1, first) end
    end

    local options = {}
    for _, wrapped in ipairs(entries) do
        local entry = wrapped.data
        local isHeader = entry.isMenuHeader == true
        options[#options + 1] = {
            title = tostring(entry.header or 'Option'),
            description = entry.txt and tostring(entry.txt) or nil,
            icon = entry.icon,
            disabled = entry.disabled == true,
            readOnly = isHeader,
            onSelect = isHeader and nil or function() invoke(entry) end
        }
    end
    return options
end

local function openMenu(data, sort, skipFirst)
    if type(data) ~= 'table' or #data == 0 then return false end
    lib.registerContext({
        id = contextId,
        title = 'Menu',
        options = normalise(data, sort, skipFirst),
        onExit = function() TriggerEvent('qb-menu:client:menuClosed') end
    })
    lib.showContext(contextId)
    return true
end

local function closeMenu()
    lib.hideContext(false)
    return true
end

local function showHeader(data)
    return openMenu(data, false, false)
end

RegisterNetEvent('qb-menu:client:openMenu', openMenu)
RegisterNetEvent('qb-menu:client:closeMenu', closeMenu)

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('showHeader', showHeader)
