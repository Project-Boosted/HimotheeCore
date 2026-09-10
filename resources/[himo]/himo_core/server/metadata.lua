HimoMetadata = HimoMetadata or {}

local MAX_METADATA_BYTES = 65535

local function validKey(key)
    return type(key) == 'string'
        and #key >= 1
        and #key <= 64
        and key:match('^[%w_:%-%.]+$') ~= nil
        and key:sub(1, 2) ~= '__'
end

local function isPublicKey(key)
    return HimoConfig.ReplicatedMetadata and HimoConfig.ReplicatedMetadata[key] == true
end

local function clonePublic(metadata)
    local public = {}
    for key, value in pairs(metadata or {}) do
        if isPublicKey(key) then public[key] = value end
    end
    return public
end

local function persist(character)
    local encoded = json.encode(character.metadata or {})
    if type(encoded) ~= 'string' or #encoded > MAX_METADATA_BYTES then
        return false, 'Metadata payload is too large.'
    end

    MySQL.update.await([[
        UPDATE `himo_character_metadata`
        SET `metadata` = ?, `updated_at` = CURRENT_TIMESTAMP
        WHERE `character_id` = ?
    ]], { encoded, character.id })

    return true
end

function HimoMetadata.sync(source)
    source = tonumber(source) or source
    local character = HimoPlayers[source]
    if not character then return false end

    HimoState.setPlayer(source, 'himo:metadata', clonePublic(character.metadata))
    TriggerClientEvent('himo_core:client:metadataSnapshot', source, character.metadata or {})
    return true
end

function HimoMetadata.get(source, key, default)
    source = tonumber(source) or source
    local character = HimoPlayers[source]
    if not character then return default end
    if key == nil then return character.metadata or {} end
    if not validKey(key) then return default end

    local value = (character.metadata or {})[key]
    if value == nil then return default end
    return value
end

function HimoMetadata.set(source, key, value)
    source = tonumber(source) or source
    if not validKey(key) then return false, 'Invalid metadata key.' end

    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    character.metadata = character.metadata or {}
    local previous = character.metadata[key]
    character.metadata[key] = value

    local ok, reason = persist(character)
    if not ok then
        character.metadata[key] = previous
        return false, reason
    end

    if isPublicKey(key) then
        HimoState.setPlayer(source, 'himo:metadata', clonePublic(character.metadata))
    end

    TriggerClientEvent('himo_core:client:metadataChanged', source, key, value)
    TriggerEvent('himo_core:server:metadataChanged', source, key, value, previous)
    return true
end

function HimoMetadata.add(source, key, amount, minimum, maximum)
    amount = tonumber(amount)
    if not amount then return false, 'Metadata amount must be numeric.' end

    local current = tonumber(HimoMetadata.get(source, key, 0)) or 0
    local value = current + amount
    if minimum ~= nil then value = math.max(tonumber(minimum) or value, value) end
    if maximum ~= nil then value = math.min(tonumber(maximum) or value, value) end
    return HimoMetadata.set(source, key, value)
end

AddEventHandler('himo_core:server:characterLoaded', function(source)
    HimoMetadata.sync(source)
end)

exports('GetMetadata', HimoMetadata.get)
exports('SetMetadata', HimoMetadata.set)
exports('AddMetadata', HimoMetadata.add)
