HimoAccounts = HimoAccounts or {}

math.randomseed(os.time())

local function chat(source, message)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 173, 92, 255 },
        args = { 'HimotheeCore', message }
    })
end

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)
    deferrals.update('HimotheeCore: validating database...')

    if not HimoDatabase.awaitReady(15000) then
        deferrals.done('HimotheeCore database is not ready. Please contact server staff.')
        return
    end

    deferrals.update('HimotheeCore: loading account...')

    local ok, accountId, reason = pcall(function()
        local id, err = HimoIdentifiers.ensureAccount(source)
        return id, err
    end)

    if not ok then
        HimoLogger.error(('Account load failed for %s: %s'):format(playerName, accountId))
        deferrals.done('HimotheeCore could not load your account.')
        return
    end

    if not accountId then
        deferrals.done(reason or 'HimotheeCore rejected the connection.')
        return
    end

    HimoAccounts[source] = accountId
    deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local character = HimoPlayers[source]

    if character then
        HimoDatabase.audit({
            accountId = HimoAccounts[source],
            characterId = character.id,
            source = source,
            action = 'player.dropped',
            targetType = 'character',
            targetId = character.id,
            data = { reason = reason }
        })
        HimoCharacters.unload(source)
    end

    HimoAccounts[source] = nil
end)

RegisterCommand('himoaccount', function(source)
    if source == 0 then
        HimoLogger.info('himoaccount must be run by an in-game player.')
        return
    end
    chat(source, ('Account ID: %s'):format(HimoAccounts[source] or 'not loaded'))
end, false)

RegisterCommand('himocreate', function(source, args)
    if source == 0 then return end
    if #args < 4 then
        chat(source, 'Usage: /himocreate Firstname Lastname YYYY-MM-DD gender')
        return
    end

    local character, err = HimoCharacters.create(source, {
        firstName = args[1],
        lastName = args[2],
        dateOfBirth = args[3],
        gender = args[4],
        nationality = 'British'
    })

    if not character then
        chat(source, ('Create failed: %s'):format(err or 'unknown error'))
        return
    end

    chat(source, ('Created %s %s in slot %d (ID %d / %s).'):format(
        character.first_name, character.last_name, character.slot, character.id, character.citizen_id
    ))
end, false)

RegisterCommand('himoload', function(source, args)
    if source == 0 then return end
    local characterId = tonumber(args[1])
    if not characterId then
        chat(source, 'Usage: /himoload <characterId>')
        return
    end

    local character, err = HimoCharacters.load(source, characterId)
    if not character then
        chat(source, ('Load failed: %s'):format(err or 'unknown error'))
        return
    end

    chat(source, ('Loaded %s %s (%s).'):format(character.first_name, character.last_name, character.citizen_id))
end, false)

RegisterCommand('himowhoami', function(source)
    if source == 0 then return end
    local character = HimoPlayers[source]
    if not character then
        chat(source, 'No character is currently loaded.')
        return
    end
    chat(source, ('%s %s | character #%d | %s'):format(
        character.first_name, character.last_name, character.id, character.citizen_id
    ))
end, false)

exports('GetAccountId', function(source)
    return HimoAccounts[source]
end)

exports('GetCharacter', function(source)
    return HimoPlayers[source]
end)

exports('GetCharacterId', function(source)
    local character = HimoPlayers[source]
    return character and character.id or nil
end)

exports('GetCharacters', function(source)
    local accountId = HimoAccounts[source]
    if not accountId then return {} end
    return HimoCharacters.list(accountId)
end)

exports('CreateCharacter', function(source, data)
    return HimoCharacters.create(source, data)
end)

exports('LoadCharacter', function(source, characterId)
    return HimoCharacters.load(source, characterId)
end)

exports('UnloadCharacter', function(source)
    return HimoCharacters.unload(source)
end)

exports('SaveCharacterPosition', function(source, position)
    return HimoCharacters.savePosition(source, position)
end)

exports('GetBalance', HimoMoney.getBalance)
exports('AddMoney', HimoMoney.add)
exports('RemoveMoney', HimoMoney.remove)

CreateThread(function()
    if not HimoDatabase.awaitReady(15000) then
        HimoLogger.error('Startup health check FAILED: database unavailable.')
        return
    end

    HimoLogger.info(('Started %s v%s | schema %d | max characters %d'):format(
        HimoConfig.FrameworkName,
        HimoConfig.Version,
        HimoDatabase.schemaVersion,
        HimoConfig.MaxCharacters
    ))
end)
