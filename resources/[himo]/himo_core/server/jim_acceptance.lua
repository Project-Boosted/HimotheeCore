local function resourceHealth(name)
    local state = GetResourceState(name)
    return state == 'started', state, GetResourceMetadata(name, 'version', 0) or 'unknown'
end

HimoCommands.register('himojimtest', {}, function(source, args, raw, respond)
    if source == 0 then return end

    local bridgeOk, bridgeState, bridgeVersion = resourceHealth('jim_bridge')
    local miningOk, miningState, miningVersion = resourceHealth('jim-mining')
    local recycleOk, recycleState, recycleVersion = resourceHealth('jim-recycle')

    local cacheOk = false
    local cacheDetail = 'jim_bridge-not-started'
    if bridgeOk then
        local ok, cache = pcall(function()
            return exports.jim_bridge:GetSharedData()
        end)
        if ok and type(cache) == 'table' then
            local itemsOk = type(cache.Items) == 'table' and next(cache.Items) ~= nil
            local jobsOk = type(cache.Jobs) == 'table' and next(cache.Jobs) ~= nil
            local vehiclesOk = type(cache.Vehicles) == 'table' and next(cache.Vehicles) ~= nil
            cacheOk = itemsOk and jobsOk and vehiclesOk
            cacheDetail = ('items=%s jobs=%s vehicles=%s'):format(
                tostring(itemsOk), tostring(jobsOk), tostring(vehiclesOk)
            )
        else
            cacheDetail = ok and 'cache-invalid' or tostring(cache)
        end
    end

    local inventoryOk = GetResourceState('ox_inventory') == 'started'

    respond(source, ('Jim gameplay | bridge=%s(%s v%s) | mining=%s(%s v%s) | recycle=%s(%s v%s)'):format(
        tostring(bridgeOk), bridgeState, bridgeVersion,
        tostring(miningOk), miningState, miningVersion,
        tostring(recycleOk), recycleState, recycleVersion
    ))
    respond(source, ('Jim dependencies | cache=%s(%s) | ox_inventory=%s'):format(
        tostring(cacheOk), cacheDetail, tostring(inventoryOk)
    ))

    if bridgeOk and miningOk and recycleOk and cacheOk and inventoryOk then
        respond(source, 'JIM GAMEPLAY TEST PASS | jim-mining + jim-recycle loaded on HimotheeCore')
    else
        respond(source, 'JIM GAMEPLAY TEST FAIL | check server console for the first resource that did not start cleanly', { 255, 90, 90 })
    end
end)
