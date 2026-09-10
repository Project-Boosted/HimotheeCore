HimoAccounts = HimoAccounts or {}

math.randomseed(os.time())

local function sourceKey(value)
    return tonumber(value) or value
end

local function chat(source, message)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 173, 92, 255 },
        args = { 'HimotheeCore', message }
    })
end

local function ensureAccountLoaded(playerSource)
    playerSource = sourceKey(playerSource)

    if HimoAccounts[playerSource] then
        return HimoAccounts[playerSource]
    end

    if not HimoDatabase.awaitReady(15000) then
        return nil, 'HimotheeCore database is not ready.'
    end

    local ok, accountId, reason = pcall(function()
        local id, err = HimoIdentifiers.ensureAccount(playerSource)
        return id, err
    end)

    if not ok then
        HimoLogger.error(('Account resolution failed for source %s: %s'):format(playerSource, accountId))
        return nil, 'HimotheeCore could not load your account.'
    end

    if not accountId then
        return nil, reason or 'HimotheeCore could not resolve your account.'
    end

    HimoAccounts[playerSource] = accountId
    return accountId
end

local function capturePlayerPosition(playerSource)
    playerSource = sourceKey(playerSource)
    if not HimoPlayers[playerSource] then return false end

    local ok, saved = pcall(function()
        local ped = GetPlayerPed(playerSource)
        if not ped or ped <= 0 then return false end

        local coords = GetEntityCoords(ped)
        if not coords then return false end

        return HimoCharacters.savePosition(playerSource, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = GetEntityHeading(ped)
        })
    end)

    if not ok then
        HimoLogger.error(('Position save failed for source %s: %s'):format(playerSource, saved))
        return false
    end

    return saved == true
end

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local connectingSource = sourceKey(source)
    deferrals.defer()
    Wait(0)
    deferrals.update('HimotheeCore: validating database...')

    if not HimoDatabase.awaitReady(15000) then
        deferrals.done('HimotheeCore database is not ready. Please contact server staff.')
        return
    end

    deferrals.update('HimotheeCore: loading account...')

    local accountId, reason = ensureAccountLoaded(connectingSource)
    if not accountId then
        HimoLogger.error(('Account load failed for %s: %s'):format(playerName, reason or 'unknown error'))
        deferrals.done(reason or 'HimotheeCore rejected the connection.')
        return
    end

    HimoLogger.debug(('Connection account resolved: temporary source %s -> account %d'):format(
        connectingSource, accountId
    ))

    deferrals.done()
end)

-- FiveM uses a temporary source during playerConnecting and assigns the final
-- in-game source when playerJoining fires. Carry the account mapping across
-- that boundary so all later framework calls use the live player source.
AddEventHandler('playerJoining', function(oldId)
    local joinedSource = sourceKey(source)
    local temporarySource = sourceKey(oldId)

    local accountId = HimoAccounts[temporarySource]
        or HimoAccounts[tostring(oldId)]

    if accountId then
        HimoAccounts[joinedSource] = accountId
        HimoAccounts[temporarySource] = nil
        HimoAccounts[tostring(oldId)] = nil

        HimoLogger.debug(('Join account migrated: source %s -> %s, account %d'):format(
            temporarySource, joinedSource, accountId
        ))
        return
    end

    -- Defensive fallback for unusual resource restarts/timing. At this point
    -- the final player source exists, so identifiers can be resolved again.
    CreateThread(function()
        local resolved, reason = ensureAccountLoaded(joinedSource)
        if resolved then
            HimoLogger.debug(('Join account re-resolved for source %s -> account %d'):format(
                joinedSource, resolved
            ))
        else
            HimoLogger.error(('Could not resolve joined source %s: %s'):format(
                joinedSource, reason or 'unknown error'
            ))
        end
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local droppedSource = sourceKey(source)
    local character = HimoPlayers[droppedSource]

    if character then
        capturePlayerPosition(droppedSource)

        HimoDatabase.audit({
            accountId = HimoAccounts[droppedSource],
            characterId = character.id,
            source = droppedSource,
            action = 'player.dropped',
            targetType = 'character',
            targetId = character.id,
            data = { reason = reason }
        })
        HimoCharacters.unload(droppedSource)
    end

    HimoAccounts[droppedSource] = nil
end)

RegisterNetEvent('himo_core:server:savePosition', function()
    capturePlayerPosition(source)
end)

RegisterCommand('himoaccount', function(source)
    if source == 0 then
        HimoLogger.info('himoaccount must be run by an in-game player.')
        return
    end

    local accountId, reason = ensureAccountLoaded(source)
    if not accountId then
        chat(source, ('Account load failed: %s'):format(reason or 'unknown error'))
        return
    end

    chat(source, ('Account ID: %s'):format(accountId))
end, false)

RegisterCommand('himocreate', function(source, args)
    if source == 0 then return end
    if #args < 4 then
        chat(source, 'Usage: /himocreate Firstname Lastname YYYY-MM-DD gender')
        return
    end

    local accountId, accountReason = ensureAccountLoaded(source)
    if not accountId then
        chat(source, ('Account load failed: %s'):format(accountReason or 'unknown error'))
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

    local accountId, accountReason = ensureAccountLoaded(source)
    if not accountId then
        chat(source, ('Account load failed: %s'):format(accountReason or 'unknown error'))
        return
    end

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
    return HimoAccounts[sourceKey(source)]
end)

exports('EnsureAccount', function(source)
    return ensureAccountLoaded(source)
end)

exports('GetCharacter', function(source)
    return HimoPlayers[sourceKey(source)]
end)

exports('GetCharacterId', function(source)
    local character = HimoPlayers[sourceKey(source)]
    return character and character.id or nil
end)

exports('GetCharacters', function(source)
    local key = sourceKey(source)
    local accountId = HimoAccounts[key]
    if not accountId then return {} end
    return HimoCharacters.list(accountId)
end)

exports('CreateCharacter', function(source, data)
    local key = sourceKey(source)
    local accountId = HimoAccounts[key] or ensureAccountLoaded(key)
    if not accountId then return nil, 'Account is not loaded.' end
    return HimoCharacters.create(key, data)
end)

exports('LoadCharacter', function(source, characterId)
    local key = sourceKey(source)
    local accountId = HimoAccounts[key] or ensureAccountLoaded(key)
    if not accountId then return nil, 'Account is not loaded.' end
    return HimoCharacters.load(key, characterId)
end)

exports('UnloadCharacter', function(source)
    return HimoCharacters.unload(sourceKey(source))
end)

exports('SaveCharacterPosition', function(source, position)
    return HimoCharacters.savePosition(sourceKey(source), position)
end)

exports('SavePlayerPosition', function(source)
    return capturePlayerPosition(source)
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

CreateThread(function()
    while true do
        Wait(HimoConfig.AutoSaveMs)

        local saved = 0
        for playerSource in pairs(HimoPlayers) do
            if capturePlayerPosition(playerSource) then
                saved = saved + 1
            end
        end

        if HimoConfig.Debug and saved > 0 then
            HimoLogger.debug(('Autosaved positions for %d loaded character(s).'):format(saved))
        end
    end
end)
