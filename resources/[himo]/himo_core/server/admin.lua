local function boolArg(value)
    value = tostring(value or ''):lower()
    if value == '1' or value == 'true' or value == 'on' or value == 'yes' then return true end
    if value == '0' or value == 'false' or value == 'off' or value == 'no' then return false end
    return nil
end

HimoCommands.register('himostage', { permission = 'staff' }, function(source, args, raw, respond)
    respond(source, ('%s v%s | Stage %s | schema %d | ready=%s'):format(
        HimoConfig.FrameworkName, HimoConfig.Version, HimoConfig.Stage,
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
    local gang = player.Functions.GetPrimaryGroup('gang')
    local session = HimoSessions.get(target)
    respond(source, ('src=%s citizen=%s char=%s account=%s ready=%s job=%s:%s duty=%s gang=%s:%s session=%s'):format(
        target,
        data and data.citizen_id or 'none', data and data.id or 'none', HimoAccounts[target] or 'none',
        tostring(HimoReadyPlayers[target] == true),
        job and job.job_name or 'none', job and job.grade or 'none',
        job and tostring(job.on_duty) or 'false',
        gang and gang.group_name or 'none', gang and gang.grade or 'none',
        session and session.token or 'none'
    ))
end)

HimoCommands.register('himosetjob', { permission = 'admin' }, function(source, args, raw, respond)
    local target, jobName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    if not target or not jobName then respond(source, 'Usage: /himosetjob <serverId> <job> <grade>') return end
    local ok, reason = HimoJobs.add(target, jobName, grade, true)
    if not ok then respond(source, ('Set job failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Set player %d primary job to %s grade %d.'):format(target, jobName, grade))
end)

HimoCommands.register('himoaddjob', { permission = 'admin' }, function(source, args, raw, respond)
    local target, jobName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    if not target or not jobName then respond(source, 'Usage: /himoaddjob <serverId> <job> <grade>') return end
    local ok, reason = HimoJobs.add(target, jobName, grade, false)
    if not ok then respond(source, ('Add job failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Added %s grade %d to player %d.'):format(jobName, grade, target))
end)

HimoCommands.register('himosetgroup', { permission = 'admin' }, function(source, args, raw, respond)
    local target, groupName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    if not target or not groupName then respond(source, 'Usage: /himosetgroup <serverId> <group> <grade>') return end
    local ok, reason = HimoGroups.add(target, groupName, grade, true)
    if not ok then respond(source, ('Set group failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Set player %d primary group to %s grade %d.'):format(target, groupName, grade))
end)

HimoCommands.register('himoaddgroup', { permission = 'admin' }, function(source, args, raw, respond)
    local target, groupName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    if not target or not groupName then respond(source, 'Usage: /himoaddgroup <serverId> <group> <grade>') return end
    local ok, reason = HimoGroups.add(target, groupName, grade, false)
    if not ok then respond(source, ('Add group failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Added %s grade %d to player %d.'):format(groupName, grade, target))
end)

HimoCommands.register('himoduty', {}, function(source, args, raw, respond)
    if source == 0 then return end
    local desired = boolArg(args[1])
    local current = HimoJobs.getPrimary(source)
    if not current then respond(source, 'No primary job is loaded.') return end
    if desired == nil then desired = not (current.on_duty == true or current.on_duty == 1 or current.on_duty == '1') end

    local ok, reason = HimoJobs.setDuty(source, current.job_name, desired)
    if not ok then respond(source, ('Duty change failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('%s duty: %s'):format(current.job_label or current.job_name, desired and 'ON' or 'OFF'))
end)

HimoCommands.register('himometadata', { permission = 'admin' }, function(source, args, raw, respond)
    local target, key = tonumber(args[1]), args[2]
    if not target or not key then respond(source, 'Usage: /himometadata <serverId> <key> [value]') return end

    if args[3] == nil then
        respond(source, ('%s[%s] = %s'):format(target, key, json.encode(HimoMetadata.get(target, key, nil))))
        return
    end

    local rawValue = table.concat(args, ' ', 3)
    local value = rawValue
    if rawValue == 'true' then value = true
    elseif rawValue == 'false' then value = false
    elseif rawValue == 'null' then value = nil
    elseif tonumber(rawValue) ~= nil then value = tonumber(rawValue) end

    local ok, reason = HimoMetadata.set(target, key, value)
    if not ok then respond(source, ('Metadata update failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Updated player %d metadata %s.'):format(target, key))
end)

HimoCommands.register('himograntrole', { permission = 'owner' }, function(source, args, raw, respond)
    local target = tonumber(args[1])
    local roleName = tostring(args[2] or ''):lower()
    if not target or roleName == '' then
        respond(source, 'Usage: /himograntrole <serverId> <owner|admin|staff|dev>')
        return
    end

    local targetAccountId = HimoAccounts[target]
    if not targetAccountId then respond(source, 'Target player has no loaded Himothee account.') return end
    local grantedBy = HimoAccounts[tonumber(source) or source]
    local ok, reason = HimoPermissions.grantRole(targetAccountId, roleName, grantedBy)
    if not ok then respond(source, ('Grant role failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Granted role %s to account %d (player %d).'):format(roleName, targetAccountId, target))
end)

HimoCommands.register('himorevokerole', { permission = 'owner' }, function(source, args, raw, respond)
    local target = tonumber(args[1])
    local roleName = tostring(args[2] or ''):lower()
    if not target or roleName == '' then
        respond(source, 'Usage: /himorevokerole <serverId> <owner|admin|staff|dev>')
        return
    end

    local targetAccountId = HimoAccounts[target]
    if not targetAccountId then respond(source, 'Target player has no loaded Himothee account.') return end
    local ok, reason = HimoPermissions.revokeRole(targetAccountId, roleName)
    if not ok then respond(source, ('Revoke role failed: %s'):format(reason or 'unknown error')) return end
    respond(source, ('Revoked role %s from account %d (player %d).'):format(roleName, targetAccountId, target))
end)
