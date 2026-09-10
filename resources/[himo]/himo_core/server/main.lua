HimoAccounts = HimoAccounts or {}

math.randomseed(os.time())
HimoState.setFrameworkReady(false)

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

        local health = nil
        local armour = nil
        if type(GetEntityHealth) == 'function' then health = GetEntityHealth(ped) end
        if type(GetPedArmour) == 'function' then armour = GetPedArmour(ped) end

        return HimoCharacters.savePosition(playerSource, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = GetEntityHeading(ped),
            health = health,
            armour = armour
        })
    end)

    if not ok then
        HimoLogger.error(('Position save failed for source %s: %s'):format(playerSource, saved))
        return false
    end

    return saved == true
end

HimoSavePlayer = capturePlayerPosition

local function saveAllPlayers(reason, closeSessions)
    local saved = 0
    local sources = {}
    for playerSource in pairs(HimoPlayers) do sources[#sources + 1] = playerSource end

    for _, playerSource in ipairs(sources) do
        if capturePlayerPosition(playerSource) then saved = saved + 1 end
        if closeSessions then HimoSessions.endSession(playerSource, reason or 'server_shutdown') end
    end

    if saved > 0 or HimoConfig.Debug then
        HimoLogger.info(('Save-all completed: %d/%d loaded character(s) saved (%s).'):format(
            saved, #sources, reason or 'manual'
        ))
    end
    return saved
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

    deferrals.update('HimotheeCore: checking active session...')
    local reserved, sessionOrReason = HimoSessions.reserve(connectingSource, accountId)
    if not reserved then
        HimoAccounts[connectingSource] = nil
        HimoLogger.info(('Duplicate session rejected for account %s (%s).'):format(accountId, playerName))
        deferrals.done(sessionOrReason or 'This HimotheeCore account is already connected.')
        return
    end

    HimoLogger.debug(('Connection account resolved: temporary source %s -> account %d'):format(
        connectingSource, accountId
    ))
    deferrals.done()
end)

AddEventHandler('playerJoining', function(oldId)
    local joinedSource = sourceKey(source)
    local temporarySource = sourceKey(oldId)
    local accountId = HimoAccounts[temporarySource] or HimoAccounts[tostring(oldId)]

    if accountId then
        HimoAccounts[joinedSource] = accountId
        HimoAccounts[temporarySource] = nil
        HimoAccounts[tostring(oldId)] = nil
        HimoSessions.migrate(temporarySource, joinedSource)

        HimoLogger.debug(('Join account migrated: source %s -> %s, account %d'):format(
            temporarySource, joinedSource, accountId
        ))

        CreateThread(function()
            local activated, reason = HimoSessions.activate(joinedSource)
            if not activated then
                HimoLogger.error(('Session activation failed for source %s: %s'):format(joinedSource, reason or 'unknown'))
            end
        end)
        return
    end

    CreateThread(function()
        local resolved, reason = ensureAccountLoaded(joinedSource)
        if not resolved then
            HimoLogger.error(('Could not resolve joined source %s: %s'):format(joinedSource, reason or 'unknown error'))
            return
        end

        local reserved, reserveReason = HimoSessions.reserve(joinedSource, resolved)
        if not reserved then
            HimoLogger.error(('Could not reserve joined source %s: %s'):format(joinedSource, reserveReason or 'unknown error'))
            DropPlayer(joinedSource, reserveReason or 'Duplicate HimotheeCore session.')
            return
        end

        local activated, activateReason = HimoSessions.activate(joinedSource)
        if not activated then
            HimoLogger.error(('Could not activate joined source %s: %s'):format(joinedSource, activateReason or 'unknown error'))
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

    HimoSessions.endSession(droppedSource, reason or 'player_dropped')
    HimoAccounts[droppedSource] = nil
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function(eventData)
    HimoState.setFrameworkReady(false)
    saveAllPlayers('txadmin_shutdown', true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    HimoState.setFrameworkReady(false)
    saveAllPlayers('resource_stop', true)
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
        firstName = args[1], lastName = args[2], dateOfBirth = args[3],
        gender = args[4], nationality = 'British'
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
    local character = HimoPlayers[sourceKey(source)]
    if not character then
        chat(source, 'No character is currently loaded.')
        return
    end
    chat(source, ('%s %s | character #%d | %s'):format(
        character.first_name, character.last_name, character.id, character.citizen_id
    ))
end, false)

RegisterCommand('himoplayer', function(source)
    if source == 0 then return end
    local player = HimoPlayerObjects[sourceKey(source)]
    if not player then
        chat(source, 'Player Object is not loaded.')
        return
    end

    local job = player.Functions.GetPrimaryJob()
    local cash = player.Functions.GetMoney('cash') or 0
    local bank = player.Functions.GetMoney('bank') or 0
    chat(source, ('Player Object OK | %s | cash $%d | bank $%d | job %s'):format(
        player.Functions.GetIdentifier() or 'unknown', cash, bank,
        job and job.job_name or 'none'
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

exports('SaveAllPlayers', function(reason)
    return saveAllPlayers(reason or 'export', false)
end)

exports('GetBalance', HimoMoney.getBalance)
exports('AddMoney', HimoMoney.add)
exports('RemoveMoney', HimoMoney.remove)

CreateThread(function()
    if not HimoDatabase.awaitReady(15000) then
        HimoLogger.error('Startup health check FAILED: database unavailable.')
        return
    end

    if not HimoSessions.initialize() then
        HimoLogger.error('Startup health check FAILED: session service unavailable.')
        return
    end

    HimoState.setFrameworkReady(true)
    HimoLogger.info(('Started %s v%s | Stage %s | schema %d | max characters %d'):format(
        HimoConfig.FrameworkName,
        HimoConfig.Version,
        HimoConfig.Stage,
        HimoDatabase.schemaVersion,
        HimoConfig.MaxCharacters
    ))
end)

CreateThread(function()
    while true do
        Wait(HimoConfig.AutoSaveMs)
        local saved = saveAllPlayers('autosave', false)
        if HimoConfig.Debug and saved > 0 then
            HimoLogger.debug(('Autosaved positions for %d loaded character(s).'):format(saved))
        end
    end
end)
