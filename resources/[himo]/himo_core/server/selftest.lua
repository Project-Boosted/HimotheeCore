local function truthy(value)
    return value == true or value == 1 or value == '1'
end

HimoCommands.register('himostatus', {}, function(source, args, raw, respond)
    if source == 0 then return end
    local player = exports['himo_core']:GetPlayer(source)
    if not player then respond(source, 'No Himothee Player Object is loaded.') return end

    local job = player.Functions.GetPrimaryJob()
    local hunger = player.Functions.GetMetadata('hunger', 100)
    local thirst = player.Functions.GetMetadata('thirst', 100)
    local stress = player.Functions.GetMetadata('stress', 0)
    respond(source, ('%s | job %s:%s | duty %s | hunger %s | thirst %s | stress %s'):format(
        player.Functions.GetIdentifier() or 'unknown',
        job and job.job_name or 'none', job and job.grade or 'none',
        job and (truthy(job.on_duty) and 'ON' or 'OFF') or 'OFF',
        hunger, thirst, stress
    ))
end)

HimoCommands.register('himocoretest', { permission = 'staff' }, function(source, args, raw, respond)
    local target = tonumber(args[1]) or tonumber(source)
    if not target or target == 0 then
        respond(source, 'Usage in-game: /himocoretest [serverId]')
        return
    end

    local failures = {}
    local player = exports['himo_core']:GetPlayer(target)
    local character = exports['himo_core']:GetCharacter(target)
    local session = HimoSessions.get(target)

    if not player then failures[#failures + 1] = 'player-object' end
    if not character then failures[#failures + 1] = 'character' end
    if not session or not session.active then failures[#failures + 1] = 'session' end
    if not exports['himo_core']:IsPlayerLoaded(target) then failures[#failures + 1] = 'world-ready' end
    if HimoState.getPlayer(target, 'himo:characterLoaded') ~= true then failures[#failures + 1] = 'character-statebag' end
    if HimoState.getPlayer(target, 'himo:playerLoaded') ~= true then failures[#failures + 1] = 'ready-statebag' end

    if player then
        if not player.Functions.GetPrimaryJob() then failures[#failures + 1] = 'primary-job' end
        if player.Functions.GetMetadata('hunger', nil) == nil then failures[#failures + 1] = 'metadata' end
        if type(player.Functions.GetGroups()) ~= 'table' then failures[#failures + 1] = 'groups' end
    end

    if #failures == 0 then
        respond(source, ('CORE TEST PASS | player %d | %s | schema %d | session %s'):format(
            target, character.citizen_id, HimoDatabase.schemaVersion or 0,
            session and session.token or 'none'
        ))
    else
        respond(source, ('CORE TEST FAIL | player %d | %s'):format(target, table.concat(failures, ', ')))
    end
end)
