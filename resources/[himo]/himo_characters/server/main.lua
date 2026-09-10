local actionTimes = {}

local function canAct(source, cooldownMs)
    local now = GetGameTimer()
    local last = actionTimes[source] or 0
    if now - last < (cooldownMs or 500) then
        return false
    end
    actionTimes[source] = now
    return true
end

local function ensureAccount(source)
    local ok, accountId, reason = pcall(function()
        return exports['himo_core']:EnsureAccount(source)
    end)

    if not ok then
        return nil, ('Core account export failed: %s'):format(accountId)
    end

    return accountId, reason
end

lib.callback.register('himo_characters:server:list', function(source)
    local accountId, reason = ensureAccount(source)
    if not accountId then return nil, reason or 'Account is not ready.' end

    local ok, characters = pcall(function()
        return exports['himo_core']:GetCharacters(source)
    end)
    if not ok then return nil, tostring(characters) end

    return {
        accountId = accountId,
        characters = characters or {},
        maxCharacters = math.max(1, GetConvarInt('himo:maxCharacters', 4)),
        loadedCharacter = exports['himo_core']:GetCharacter(source),
        worldReady = exports['himo_core']:IsPlayerLoaded(source)
    }
end)

lib.callback.register('himo_characters:server:load', function(source, characterId)
    if not canAct(source, 500) then return nil, 'Please wait a moment.' end

    characterId = tonumber(characterId)
    if not characterId or characterId < 1 then return nil, 'Invalid character.' end

    local accountId, reason = ensureAccount(source)
    if not accountId then return nil, reason or 'Account is not ready.' end

    local current = exports['himo_core']:GetCharacter(source)
    if current then
        if tonumber(current.id) == characterId then return current end
        return nil, 'A character is already loaded. Switch character first.'
    end

    local ok, character, err = pcall(function()
        return exports['himo_core']:LoadCharacter(source, characterId)
    end)

    if not ok then return nil, tostring(character) end
    if not character then return nil, err or 'Character load failed.' end
    return character
end)

lib.callback.register('himo_characters:server:create', function(source, data)
    if not canAct(source, 1000) then return nil, 'Please wait a moment.' end
    if type(data) ~= 'table' then return nil, 'Invalid character data.' end

    local accountId, reason = ensureAccount(source)
    if not accountId then return nil, reason or 'Account is not ready.' end
    if exports['himo_core']:GetCharacter(source) then
        return nil, 'Unload the current character before creating another.'
    end

    local ok, character, err = pcall(function()
        return exports['himo_core']:CreateCharacter(source, {
            firstName = data.firstName,
            lastName = data.lastName,
            dateOfBirth = data.dateOfBirth,
            gender = data.gender,
            nationality = data.nationality or 'British'
        })
    end)

    if not ok then return nil, tostring(character) end
    if not character then return nil, err or 'Character creation failed.' end

    local loaded, loadErr = exports['himo_core']:LoadCharacter(source, character.id)
    if not loaded then return nil, loadErr or 'New character could not be loaded.' end

    return loaded
end)

lib.callback.register('himo_characters:server:logout', function(source)
    if not canAct(source, 800) then return false, 'Please wait a moment.' end

    local character = exports['himo_core']:GetCharacter(source)
    if not character then return true end

    pcall(function() exports['himo_core']:SavePlayerPosition(source) end)
    exports['himo_core']:UnloadCharacter(source)
    return true
end)

AddEventHandler('playerDropped', function()
    actionTimes[source] = nil
end)
