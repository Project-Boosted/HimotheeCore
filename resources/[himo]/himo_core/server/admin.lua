local function boolArg(value)
    value = tostring(value or ''):lower()
    if value == '1' or value == 'true' or value == 'on' or value == 'yes' then return true end
    if value == '0' or value == 'false' or value == 'off' or value == 'no' then return false end
    return nil
end

HimoCommands.register('himostage', { permission = 'staff' }, function(source, args, raw, respond)
    respond(source, ('%s v%s | Stage 1C | schema %d | ready=%s'):format(
        HimoConfig.FrameworkName,
        HimoConfig.Version,
        HimoDatabase.schemaVersion or 0,
        tostring(GlobalState['himothee_core:ready'] == true)
    ))
end)

HimoCommands.register('himodebugplayer', { permission = 'staff' }, function(source, args, raw, respond)
    local target = tonumber(args[1]) or tonumber(source)
    local player = exports['himo_core']:GetPlayer(target)
    if not player then
        respond(source, ('Player %s has no loaded Himothee Player Object.'):format(target))
        return
    end

    local data = player.Functions.GetData()
    local job = player.Functions.GetPrimaryJob()
    local session = HimoSessions.get(target)
    respond(source, ('src=%s citizen=%s char=%s account=%s ready=%s job=%s grade=%s duty=%s session=%s'):format(
        target,
        data and data.citizen_id or 'none',
        data and data.id or 'none',
        HimoAccounts[target] or 'none',
        tostring(HimoReadyPlayers[target] == true),
        job and job.job_name or 'none',
        job and job.grade or 'none',
        job and tostring(job.on_duty) or 'false',
        session and session.token or 'none'
    ))
end)

HimoCommands.register('himosetjob', { permission = 'admin' }, function(source, args, raw, respond)
    local target = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0
    if not target or not jobName then
        respond(source, 'Usage: /himosetjob <serverId> <job> <grade>')
        return
    end

    local ok, reason = HimoJobs.add(target, jobName, grade, true)
    if not ok then
        respond(source, ('Set job failed: %s'):format(reason or 'unknown error'))
        return
    end
    respond(source, ('Set player %d primary job to %s grade %d.'):format(target, jobName, grade))
end)

HimoCommands.register('himoaddjob', { permission = 'admin' }, function(source, args, raw, respond)
    local target = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0
    if not target or not jobName then
        respond(source, 'Usage: /himoaddjob <serverId> <job> <grade>')
        return
    end

    local ok, reason = HimoJobs.add(target, jobName, grade, false)
    if not ok then
        respond(source, ('Add job failed: %s'):format(reason or 'unknown error'))
        return
    end
    respond(source, ('Added %s grade %d to player %d.'):format(jobName, grade, target))
end)

HimoCommands.register('himoduty', {}, function(source, args, raw, respond)
    if source == 0 then return end
    local desired = boolArg(args[1])
    local current = HimoJobs.getPrimary(source)
    if not current then
        respond(source, 'No primary job is loaded.')
        return
    end
    if desired == nil then
        desired = not (current.on_duty == true or current.on_duty == 1 or current.on_duty == '1')
    end

    local ok, reason = HimoJobs.setDuty(source, current.job_name, desired)
    if not ok then
        respond(source, ('Duty change failed: %s'):format(reason or 'unknown error'))
        return
    end
    respond(source, ('%s duty: %s'):format(current.job_label or current.job_name, desired and 'ON' or 'OFF'))
end)

HimoCommands.register('himometadata', { permission = 'admin' }, function(source, args, raw, respond)
    local target = tonumber(args[1])
    local key = args[2]
    if not target or not key then
        respond(source, 'Usage: /himometadata <serverId> <key> [value]')
        return
    end

    if args[3] == nil then
        local value = HimoMetadata.get(target, key, nil)
        respond(source, ('%s[%s] = %s'):format(target, key, json.encode(value)))
        return
    end

    local rawValue = table.concat(args, ' ', 3)
    local value = rawValue
    if rawValue == 'true' then value = true
    elseif rawValue == 'false' then value = false
    elseif rawValue == 'null' then value = nil
    elseif tonumber(rawValue) ~= nil then value = tonumber(rawValue) end

    local ok, reason = HimoMetadata.set(target, key, value)
    if not ok then
        respond(source, ('Metadata update failed: %s'):format(reason or 'unknown error'))
        return
    end
    respond(source, ('Updated player %d metadata %s.'):format(target, key))
end)
