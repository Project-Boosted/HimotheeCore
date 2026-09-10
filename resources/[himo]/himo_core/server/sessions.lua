HimoSessions = HimoSessions or {
    byAccount = {},
    bySource = {},
    initialized = false
}

local function sourceKey(source)
    return tonumber(source) or source
end

local function instanceName()
    local value = GetConvar('himo:serverInstance', 'main')
    value = tostring(value or 'main'):gsub('[^%w_%-%.]', '')
    if value == '' then value = 'main' end
    return value:sub(1, 80)
end

local function token()
    return ('%08x%08x%08x'):format(
        os.time() % 0xffffffff,
        math.random(0, 0xffffffff),
        math.random(0, 0xffffffff)
    )
end

local function stale(session)
    if not session then return true end
    local source = sourceKey(session.source)
    return GetPlayerName(source) == nil
end

function HimoSessions.initialize()
    if HimoSessions.initialized then return true end
    if not HimoDatabase.awaitReady(15000) then return false end

    MySQL.update.await([[
        UPDATE `himo_player_sessions`
        SET `ended_at` = CURRENT_TIMESTAMP,
            `end_reason` = COALESCE(`end_reason`, 'server_restart')
        WHERE `server_instance` = ? AND `ended_at` IS NULL
    ]], { instanceName() })

    HimoSessions.initialized = true
    return true
end

function HimoSessions.reserve(source, accountId)
    source = sourceKey(source)
    accountId = tonumber(accountId)
    if not accountId then return false, 'Invalid account session.' end

    local existing = HimoSessions.byAccount[accountId]
    if existing and existing.source ~= source then
        if stale(existing) then
            HimoSessions.bySource[sourceKey(existing.source)] = nil
            HimoSessions.byAccount[accountId] = nil
        else
            return false, 'This HimotheeCore account is already connected to this server.'
        end
    end

    local session = existing or {
        accountId = accountId,
        source = source,
        token = token(),
        dbId = nil,
        active = false
    }

    session.source = source
    HimoSessions.byAccount[accountId] = session
    HimoSessions.bySource[source] = session
    return true, session
end

function HimoSessions.migrate(oldSource, newSource)
    oldSource = sourceKey(oldSource)
    newSource = sourceKey(newSource)
    local session = HimoSessions.bySource[oldSource]
    if not session then return false end

    HimoSessions.bySource[oldSource] = nil
    session.source = newSource
    HimoSessions.bySource[newSource] = session
    HimoSessions.byAccount[session.accountId] = session
    return true
end

function HimoSessions.activate(source)
    source = sourceKey(source)
    local session = HimoSessions.bySource[source]
    if not session then return false, 'Session reservation was not found.' end
    if session.active and session.dbId then return true end

    if not HimoSessions.initialize() then
        return false, 'Session database is unavailable.'
    end

    local id = MySQL.insert.await([[
        INSERT INTO `himo_player_sessions`
            (`account_id`, `server_instance`, `server_id`, `session_token`)
        VALUES (?, ?, ?, ?)
    ]], { session.accountId, instanceName(), tonumber(source), session.token })

    if not id then return false, 'Could not create player session.' end
    session.dbId = tonumber(id)
    session.active = true
    return true
end

function HimoSessions.attachCharacter(source, characterId)
    source = sourceKey(source)
    local session = HimoSessions.bySource[source]
    if not session then return false end

    session.characterId = tonumber(characterId)
    if session.dbId then
        MySQL.update.await([[
            UPDATE `himo_player_sessions`
            SET `character_id` = ?, `last_seen_at` = CURRENT_TIMESTAMP
            WHERE `id` = ? AND `ended_at` IS NULL
        ]], { session.characterId, session.dbId })
    end
    return true
end

function HimoSessions.endSession(source, reason)
    source = sourceKey(source)
    local session = HimoSessions.bySource[source]
    if not session then return false end

    if session.dbId then
        pcall(function()
            MySQL.update.await([[
                UPDATE `himo_player_sessions`
                SET `ended_at` = CURRENT_TIMESTAMP,
                    `last_seen_at` = CURRENT_TIMESTAMP,
                    `end_reason` = ?
                WHERE `id` = ? AND `ended_at` IS NULL
            ]], { tostring(reason or 'disconnected'):sub(1, 120), session.dbId })
        end)
    end

    HimoSessions.bySource[source] = nil
    if HimoSessions.byAccount[session.accountId] == session then
        HimoSessions.byAccount[session.accountId] = nil
    end
    return true
end

function HimoSessions.get(source)
    return HimoSessions.bySource[sourceKey(source)]
end

exports('GetSession', HimoSessions.get)

CreateThread(function()
    while not HimoDatabase.awaitReady(15000) do Wait(1000) end
    HimoSessions.initialize()

    while true do
        Wait(60000)
        for _, session in pairs(HimoSessions.byAccount) do
            if session.dbId and not stale(session) then
                MySQL.update.await([[
                    UPDATE `himo_player_sessions`
                    SET `last_seen_at` = CURRENT_TIMESTAMP,
                        `character_id` = ?
                    WHERE `id` = ? AND `ended_at` IS NULL
                ]], { session.characterId, session.dbId })
            end
        end
    end
end)
