local function hasItem(items, amount)
    amount = tonumber(amount) or 1
    if type(items) == 'string' then
        return (exports.ox_inventory:Search('count', items) or 0) >= amount
    end
    if type(items) ~= 'table' then return false end
    if #items > 0 then
        for _, item in ipairs(items) do
            if (exports.ox_inventory:Search('count', item) or 0) < amount then return false end
        end
        return true
    end
    for item, required in pairs(items) do
        if (exports.ox_inventory:Search('count', item) or 0) < (tonumber(required) or amount) then return false end
    end
    return true
end

local function getItemsByName(item)
    local slots = exports.ox_inventory:Search('slots', item)
    return type(slots) == 'table' and slots or {}
end
local function getItemByName(item)
    local slots = getItemsByName(item)
    for _, slot in pairs(slots) do return slot end
end
local function openInventory(inventoryType, data)
    inventoryType = tostring(inventoryType or 'player')
    if inventoryType == 'inventory' then inventoryType = 'stash' end
    return exports.ox_inventory:openInventory(inventoryType, data)
end

exports('HasItem', hasItem)
exports('GetItemByName', getItemByName)
exports('GetItemsByName', getItemsByName)
exports('GetItemBySlot', function(slot) return exports.ox_inventory:GetSlot(tonumber(slot)) end)
exports('GetPlayerItems', function() return exports.ox_inventory:GetPlayerItems() or {} end)
exports('OpenInventory', openInventory)
exports('CloseInventory', function() return exports.ox_inventory:closeInventory() end)
exports('SetCurrentStash', function() return true end)
exports('Health', function()
    if GetResourceState('ox_inventory') ~= 'started' then return false, 'ox_inventory-not-started' end
    local ok, items = pcall(function() return exports.ox_inventory:GetPlayerItems() end)
    return ok and type(items) == 'table', ok and 'qb-inventory->ox_inventory' or tostring(items)
end)

RegisterNetEvent('inventory:client:ItemBox', function(item, action, amount)
    local label = type(item) == 'table' and (item.label or item.name) or tostring(item or 'Item')
    lib.notify({ description = ('%s %s%s'):format(action == 'remove' and 'Removed' or 'Received', label, amount and (' x' .. tostring(amount)) or ''), type = action == 'remove' and 'inform' or 'success' })
end)
RegisterNetEvent('inventory:client:SetCurrentStash', function() end)
