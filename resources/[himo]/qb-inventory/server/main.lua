local function addItem(source, item, amount, slot, info, reason)
    local success, response = exports.ox_inventory:AddItem(source, item, tonumber(amount) or 1, info, slot)
    return success == true, response
end

local function removeItem(source, item, amount, slot, reason)
    local metadata
    if slot then
        local slotData = exports.ox_inventory:GetSlot(source, tonumber(slot))
        metadata = slotData and slotData.metadata or nil
    end
    local success, response = exports.ox_inventory:RemoveItem(source, item, tonumber(amount) or 1, metadata, slot)
    return success == true, response
end

local function getItemByName(source, item)
    local slots = exports.ox_inventory:Search(source, 'slots', item)
    if type(slots) ~= 'table' then return nil end
    for _, slot in pairs(slots) do return slot end
end

local function getItemsByName(source, item)
    local slots = exports.ox_inventory:Search(source, 'slots', item)
    return type(slots) == 'table' and slots or {}
end

local function getItemBySlot(source, slot)
    return exports.ox_inventory:GetSlot(source, tonumber(slot))
end

local function hasItem(source, items, amount)
    amount = tonumber(amount) or 1
    if type(items) == 'string' then
        return (exports.ox_inventory:GetItemCount(source, items) or 0) >= amount
    end
    if type(items) ~= 'table' then return false end

    if #items > 0 then
        for _, item in ipairs(items) do
            if (exports.ox_inventory:GetItemCount(source, item) or 0) < amount then return false end
        end
        return true
    end

    for item, required in pairs(items) do
        if (exports.ox_inventory:GetItemCount(source, item) or 0) < (tonumber(required) or amount) then return false end
    end
    return true
end

local function getInventory(source)
    return exports.ox_inventory:GetInventory(source)
end

local function canAddItem(source, item, amount)
    local ok = exports.ox_inventory:CanCarryItem(source, item, tonumber(amount) or 1)
    return ok == true, ok == true and nil or 'weight'
end

local function clearInventory(source, filterItems)
    return exports.ox_inventory:ClearInventory(source, filterItems)
end

local function createShop(shopData)
    shopData = type(shopData) == 'table' and shopData or {}
    local name = shopData.name or shopData.id
    if not name then return false end
    exports.ox_inventory:RegisterShop(name, {
        name = shopData.label or shopData.name or name,
        inventory = shopData.slots or shopData.items or {},
        locations = shopData.locations,
        targets = shopData.targets,
        groups = shopData.groups
    })
    return true
end

local function openInventory(source, identifier, data)
    data = type(data) == 'table' and data or {}
    identifier = tostring(identifier or '')

    if identifier == 'player' then
        return exports.ox_inventory:forceOpenInventory(source, 'player', tonumber(data.id or data.source))
    end
    if identifier == 'shop' then
        return exports.ox_inventory:forceOpenInventory(source, 'shop', data.id or data.name or data.type)
    end
    if identifier == 'stash' then
        local stash = data.id or data.name or data.stash
        if not stash then return false end
        if data.label or data.maxweight or data.slots then
            exports.ox_inventory:RegisterStash(
                stash,
                data.label or stash,
                tonumber(data.slots) or 50,
                tonumber(data.maxweight or data.weight) or 120000,
                data.owner,
                data.groups,
                data.coords
            )
        end
        return exports.ox_inventory:forceOpenInventory(source, 'stash', { id = stash, owner = data.owner })
    end

    -- Older qb-inventory resources commonly pass a stash id directly.
    if identifier ~= '' then
        exports.ox_inventory:RegisterStash(
            identifier,
            data.label or identifier,
            tonumber(data.slots) or 50,
            tonumber(data.maxweight or data.weight) or 120000,
            data.owner,
            data.groups,
            data.coords
        )
        return exports.ox_inventory:forceOpenInventory(source, 'stash', { id = identifier, owner = data.owner })
    end
    return false
end

exports('AddItem', addItem)
exports('RemoveItem', removeItem)
exports('GetItemByName', getItemByName)
exports('GetItemsByName', getItemsByName)
exports('GetItemBySlot', getItemBySlot)
exports('HasItem', hasItem)
exports('GetInventory', getInventory)
exports('GetInventoryItems', function(source) return exports.ox_inventory:GetInventoryItems(source) or {} end)
exports('CanAddItem', canAddItem)
exports('ClearInventory', clearInventory)
exports('CreateShop', createShop)
exports('OpenInventory', openInventory)
exports('OpenInventoryById', function(source, playerId)
    return exports.ox_inventory:forceOpenInventory(source, 'player', tonumber(playerId))
end)
exports('GetTotalWeight', function(items)
    local total = 0
    for _, item in pairs(type(items) == 'table' and items or {}) do
        total = total + ((tonumber(item.weight) or 0) * (tonumber(item.count or item.amount) or 0))
    end
    return total
end)
