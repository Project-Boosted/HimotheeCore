HimoDatabase = HimoDatabase or {
    ready = false,
    schemaVersion = 0
}

function HimoDatabase.awaitReady(timeoutMs)
    local timeout = GetGameTimer() + (timeoutMs or 15000)
    while not HimoDatabase.ready and GetGameTimer() < timeout do
        Wait(50)
    end
    return HimoDatabase.ready
end

function HimoDatabase.validateSchema()
    local exists = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_name = 'himo_schema_migrations'
    ]])

    if tonumber(exists) ~= 1 then
        return false, 'himo_schema_migrations is missing. Run the Stage 1 SQL installer.'
    end

    local version = MySQL.scalar.await('SELECT COALESCE(MAX(`version`), 0) FROM `himo_schema_migrations`')
    HimoDatabase.schemaVersion = tonumber(version) or 0

    if HimoDatabase.schemaVersion < HimoConfig.RequiredSchemaVersion then
        return false, ('database schema %d is below required version %d'):format(
            HimoDatabase.schemaVersion,
            HimoConfig.RequiredSchemaVersion
        )
    end

    return true
end

function HimoDatabase.audit(data)
    if not HimoDatabase.ready then return false end

    MySQL.insert.await([[
        INSERT INTO `himo_audit_log`
            (`account_id`, `character_id`, `source`, `action`, `target_type`, `target_id`, `data`)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.accountId,
        data.characterId,
        data.source,
        data.action,
        data.targetType,
        data.targetId and tostring(data.targetId) or nil,
        data.data and json.encode(data.data) or nil
    })

    return true
end

MySQL.ready(function()
    local ok, err = pcall(function()
        local valid, reason = HimoDatabase.validateSchema()
        if not valid then
            error(reason)
        end
    end)

    if not ok then
        HimoLogger.error(('Database validation failed: %s'):format(err))
        HimoLogger.error('HimotheeCore will remain unavailable until the database is corrected.')
        return
    end

    HimoDatabase.ready = true
    HimoLogger.info(('Database ready. Schema version %d.'):format(HimoDatabase.schemaVersion))
end)
