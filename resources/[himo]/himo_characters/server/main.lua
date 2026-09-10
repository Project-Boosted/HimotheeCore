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

local function sendError(source, message)
    TriggerClientEvent('himo_characters:client:error', source, message or 'Unknown character error.')
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

local function sendCharacterList(source, notice)
    local accountId, reason = ensureAccount(source)
    if not accountId then
        sendError(source, reason or 'Your HimotheeCore account could not be loaded.')
        return false
    end

    local ok, characters = pcall(function()
        return exports['himo_core']:GetCharacters(source)
    end)

    if not ok then
        sendError(source, ('Could not load your characters: %s'):format(characters))
        return false
    end

    TriggerClientEvent('himo_characters:client:show', source, {
        accountId = accountId,
        characters = characters or {},
        maxCharacters = math.max(1, GetConvarInt('himo:maxCharacters', 4)),
        notice = notice
    })

    return true
end

RegisterNetEvent('himo_characters:server:bootstrap', function()
    local source = source
    if not canAct(source, 300) then return end

    local loaded = exports['himo_core']:GetCharacter(source)
    if loaded then
        TriggerClientEvent('himo_characters:client:resume', source, loaded)
        return
    end

    sendCharacterList(source)
end)

RegisterNetEvent('himo_characters:server:refresh', function()
    local source = source
    if not canAct(source, 400) then return end
    sendCharacterList(source)
end)

RegisterNetEvent('himo_characters:server:create', function(data)
    local source = source
    if not canAct(source, 1000) then
        sendError(source, 'Please wait a moment before creating another character.')
        return
    end

    if type(data) ~= 'table' then
        sendError(source, 'Invalid character data.')
        return
    end

    local accountId, reason = ensureAccount(source)
    if not accountId then
        sendError(source, reason or 'Your account is not ready.')
        return
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

    if not ok then
        sendError(source, ('Character creation failed: %s'):format(character))
        return
    end

    if not character then
        sendError(source, err or 'Character creation failed.')
        return
    end

    sendCharacterList(source, ('%s %s created successfully.'):format(
        character.first_name,
        character.last_name
    ))
end)

RegisterNetEvent('himo_characters:server:select', function(characterId)
    local source = source
    if not canAct(source, 750) then return end

    characterId = tonumber(characterId)
    if not characterId or characterId < 1 then
        sendError(source, 'Invalid character selection.')
        return
    end

    local accountId, reason = ensureAccount(source)
    if not accountId then
        sendError(source, reason or 'Your account is not ready.')
        return
    end

    local ok, character, err = pcall(function()
        return exports['himo_core']:LoadCharacter(source, characterId)
    end)

    if not ok then
        sendError(source, ('Character load failed: %s'):format(character))
        return
    end

    if not character then
        sendError(source, err or 'That character could not be loaded.')
        return
    end
end)

RegisterNetEvent('himo_characters:server:logout', function()
    local source = source
    if not canAct(source, 1000) then return end

    exports['himo_core']:SavePlayerPosition(source)
    exports['himo_core']:UnloadCharacter(source)
    sendCharacterList(source)
end)

AddEventHandler('playerDropped', function()
    actionTimes[source] = nil
end)
