local zoneIds = {}
local optionSerial = 0

local function vec3(value)
    if type(value) == 'vector3' then return value end
    if type(value) ~= 'table' then return vector3(0.0, 0.0, 0.0) end
    return vector3(
        tonumber(value.x or value[1]) or 0.0,
        tonumber(value.y or value[2]) or 0.0,
        tonumber(value.z or value[3]) or 0.0
    )
end

local function mergeGroups(option)
    local groups
    local function add(value)
        if value == nil then return end
        if type(value) == 'string' then
            groups = groups or {}
            groups[value] = 0
        elseif type(value) == 'table' then
            groups = groups or {}
            if #value > 0 then
                for _, name in ipairs(value) do groups[name] = 0 end
            else
                for name, grade in pairs(value) do groups[name] = tonumber(grade) or 0 end
            end
        end
    end
    add(option.job)
    add(option.gang)
    return groups
end

local function citizenAllowed(requirement)
    if requirement == nil then return true end
    local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if not ok or not core or not core.Functions then return false end
    local data = core.Functions.GetPlayerData()
    local citizenId = data and data.citizenid
    if type(requirement) == 'string' then return citizenId == requirement end
    if type(requirement) == 'table' then
        if requirement[citizenId] ~= nil then return requirement[citizenId] == true or tonumber(requirement[citizenId]) ~= nil end
        for _, id in ipairs(requirement) do if id == citizenId then return true end end
    end
    return false
end

local function convertOptions(targetOptions, prefix)
    targetOptions = type(targetOptions) == 'table' and targetOptions or {}
    local sourceOptions = type(targetOptions.options) == 'table' and targetOptions.options or targetOptions
    local distance = tonumber(targetOptions.distance)
    local converted = {}

    for index, option in ipairs(sourceOptions) do
        optionSerial = optionSerial + 1
        local originalCanInteract = option.canInteract
        local action = option.action
        local optionName = option.name or ('himo_qbt_%s_%d_%d'):format(prefix or 'option', index, optionSerial)
        local entry = {
            name = optionName,
            label = tostring(option.label or optionName),
            icon = option.icon,
            distance = tonumber(option.distance) or distance,
            groups = mergeGroups(option),
            items = option.item,
            canInteract = function(entity, dist, coords, name, bone)
                if not citizenAllowed(option.citizenid) then return false end
                if type(originalCanInteract) == 'function' then
                    local ok, result = pcall(originalCanInteract, entity, dist, { coords = coords, name = name, bone = bone })
                    return ok and result ~= false
                end
                return true
            end
        }

        if type(action) == 'function' then
            entry.onSelect = function(data) action(data.entity) end
        elseif option.event then
            local optionType = tostring(option.type or 'client'):lower()
            if optionType == 'server' then
                entry.serverEvent = option.event
            elseif optionType == 'command' then
                entry.command = option.event
            else
                entry.event = option.event
            end
        end

        converted[#converted + 1] = entry
    end
    return converted
end

local function rememberZone(name, id)
    if name then zoneIds[tostring(name)] = id end
    return id
end

local function removeZone(name)
    local key = tostring(name)
    local id = zoneIds[key] or name
    exports.ox_target:removeZone(id)
    zoneIds[key] = nil
end

local function addBoxZone(name, center, length, width, zoneOptions, targetOptions)
    zoneOptions = type(zoneOptions) == 'table' and zoneOptions or {}
    local coords = vec3(center)
    local minZ, maxZ = tonumber(zoneOptions.minZ), tonumber(zoneOptions.maxZ)
    local height = minZ and maxZ and math.max(0.1, maxZ - minZ) or tonumber(zoneOptions.height) or 3.0
    if minZ and maxZ then coords = vector3(coords.x, coords.y, (minZ + maxZ) / 2.0) end

    return rememberZone(name, exports.ox_target:addBoxZone({
        name = tostring(name),
        coords = coords,
        size = vector3(tonumber(length) or 1.0, tonumber(width) or 1.0, height),
        rotation = tonumber(zoneOptions.heading or zoneOptions.rotation) or 0.0,
        debug = zoneOptions.debugPoly == true,
        options = convertOptions(targetOptions, tostring(name))
    }))
end

local function addCircleZone(name, center, radius, zoneOptions, targetOptions)
    zoneOptions = type(zoneOptions) == 'table' and zoneOptions or {}
    return rememberZone(name, exports.ox_target:addSphereZone({
        name = tostring(name),
        coords = vec3(center),
        radius = tonumber(radius) or 1.0,
        debug = zoneOptions.debugPoly == true,
        options = convertOptions(targetOptions, tostring(name))
    }))
end

local function addPolyZone(name, points, zoneOptions, targetOptions)
    zoneOptions = type(zoneOptions) == 'table' and zoneOptions or {}
    local mapped = {}
    for _, point in ipairs(type(points) == 'table' and points or {}) do mapped[#mapped + 1] = vec3(point) end
    return rememberZone(name, exports.ox_target:addPolyZone({
        name = tostring(name),
        points = mapped,
        thickness = tonumber(zoneOptions.maxZ and zoneOptions.minZ and (zoneOptions.maxZ - zoneOptions.minZ)) or 4.0,
        debug = zoneOptions.debugPoly == true,
        options = convertOptions(targetOptions, tostring(name))
    }))
end

local function addTargetEntity(entities, targetOptions)
    exports.ox_target:addLocalEntity(entities, convertOptions(targetOptions, 'entity'))
end
local function removeTargetEntity(entities, labels)
    exports.ox_target:removeLocalEntity(entities, labels)
end
local function addTargetModel(models, targetOptions)
    exports.ox_target:addModel(models, convertOptions(targetOptions, 'model'))
end
local function removeTargetModel(models, labels)
    exports.ox_target:removeModel(models, labels)
end

local function addGlobalPed(targetOptions) exports.ox_target:addGlobalPed(convertOptions(targetOptions, 'ped')) end
local function removeGlobalPed(labels) exports.ox_target:removeGlobalPed(labels) end
local function addGlobalVehicle(targetOptions) exports.ox_target:addGlobalVehicle(convertOptions(targetOptions, 'vehicle')) end
local function removeGlobalVehicle(labels) exports.ox_target:removeGlobalVehicle(labels) end
local function addGlobalObject(targetOptions) exports.ox_target:addGlobalObject(convertOptions(targetOptions, 'object')) end
local function removeGlobalObject(labels) exports.ox_target:removeGlobalObject(labels) end
local function addGlobalPlayer(targetOptions) exports.ox_target:addGlobalPlayer(convertOptions(targetOptions, 'player')) end
local function removeGlobalPlayer(labels) exports.ox_target:removeGlobalPlayer(labels) end

exports('AddBoxZone', addBoxZone)
exports('AddCircleZone', addCircleZone)
exports('AddPolyZone', addPolyZone)
exports('RemoveZone', removeZone)
exports('AddTargetEntity', addTargetEntity)
exports('RemoveTargetEntity', removeTargetEntity)
exports('AddTargetModel', addTargetModel)
exports('RemoveTargetModel', removeTargetModel)
exports('AddGlobalPed', addGlobalPed)
exports('RemoveGlobalPed', removeGlobalPed)
exports('AddGlobalVehicle', addGlobalVehicle)
exports('RemoveGlobalVehicle', removeGlobalVehicle)
exports('AddGlobalObject', addGlobalObject)
exports('RemoveGlobalObject', removeGlobalObject)
exports('AddGlobalPlayer', addGlobalPlayer)
exports('RemoveGlobalPlayer', removeGlobalPlayer)

exports('AllowTargeting', function(allow)
    exports.ox_target:disableTargeting(allow == false)
end)
