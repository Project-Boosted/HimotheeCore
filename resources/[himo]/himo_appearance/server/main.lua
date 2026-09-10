local MAX_APPEARANCE_BYTES = 262144

local function decodeAppearance(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return nil end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then return nil end
    return decoded
end

local function ensureAccount(source)
    local accountId = exports['himo_core']:GetAccountId(source)
    if accountId then return accountId end

    local ok, resolved = pcall(function()
        return exports['himo_core']:EnsureAccount(source)
    end)

    if ok then return resolved end
    return nil
end

local function fetchOwnedAppearance(source, characterId)
    local accountId = ensureAccount(source)
    if not accountId then return nil end

    local row = MySQL.single.await([[
        SELECT a.`model`, a.`appearance`
        FROM `himo_character_appearance` a
        INNER JOIN `himo_characters` c ON c.`id` = a.`character_id`
        WHERE a.`character_id` = ?
          AND c.`account_id` = ?
          AND c.`is_deleted` = 0
        LIMIT 1
    ]], { characterId, accountId })

    if not row then return nil end

    local appearance = decodeAppearance(row.appearance)
    if not appearance then return nil end
    appearance.model = appearance.model or row.model

    return appearance
end

lib.callback.register('himo_appearance:server:getPreview', function(source, characterId)
    characterId = tonumber(characterId)
    if not characterId or characterId < 1 then return nil end
    return fetchOwnedAppearance(source, characterId)
end)

lib.callback.register('himo_appearance:server:getCurrent', function(source)
    local characterId = exports['himo_core']:GetCharacterId(source)
    if not characterId then return nil end
    return fetchOwnedAppearance(source, characterId)
end)

lib.callback.register('himo_appearance:server:save', function(source, appearance)
    local characterId = exports['himo_core']:GetCharacterId(source)
    if not characterId then
        return false, 'No HimotheeCore character is loaded.'
    end

    if type(appearance) ~= 'table' then
        return false, 'Appearance payload is invalid.'
    end

    local encoded = json.encode(appearance)
    if type(encoded) ~= 'string' or #encoded == 0 then
        return false, 'Appearance could not be encoded.'
    end

    if #encoded > MAX_APPEARANCE_BYTES then
        return false, 'Appearance payload is too large.'
    end

    local model = tostring(appearance.model or 'mp_m_freemode_01')
    if #model > 80 then model = model:sub(1, 80) end

    MySQL.prepare.await([[
        INSERT INTO `himo_character_appearance` (`character_id`, `model`, `appearance`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `model` = VALUES(`model`),
            `appearance` = VALUES(`appearance`),
            `updated_at` = CURRENT_TIMESTAMP
    ]], { characterId, model, encoded })

    return true
end)
