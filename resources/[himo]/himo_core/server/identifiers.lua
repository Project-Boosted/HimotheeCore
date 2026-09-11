HimoIdentifiers = HimoIdentifiers or {}

local preferredOrder = {
    license = 1,
    license2 = 2,
    fivem = 3,
    discord = 4,
    steam = 5,
    xbox = 6,
    live = 7
}

function HimoIdentifiers.collect(source)
    local output = {}
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        local provider = identifier:match('^([^:]+):')
        if provider then
            output[#output + 1] = { provider = provider, identifier = identifier }
        end
    end

    table.sort(output, function(a, b)
        return (preferredOrder[a.provider] or 99) < (preferredOrder[b.provider] or 99)
    end)
    return output
end

function HimoIdentifiers.ensureAccount(source)
    local identifiers = HimoIdentifiers.collect(source)
    if #identifiers == 0 then return nil, 'No usable FiveM identifier was found.' end

    local identifiersByProvider = {}
    for _, item in ipairs(identifiers) do
        identifiersByProvider[item.provider] = identifiersByProvider[item.provider] or item.identifier
    end

    -- ps-adminmenu writes standard QBCore bans. When that compatibility table is
    -- available, enforce active records during HimotheeCore's connection gate too.
    -- pcall keeps upgrades safe during the very first startup before the QB bridge
    -- has provisioned its vendor compatibility schema.
    local banQueryOk, activeBan = pcall(MySQL.single.await, [[
        SELECT `reason`, `expire`, `bannedby`
        FROM `bans`
        WHERE (
            (`license` IS NOT NULL AND `license` = ?)
            OR (`discord` IS NOT NULL AND `discord` = ?)
            OR (`ip` IS NOT NULL AND `ip` = ?)
        )
          AND (`expire` IS NULL OR `expire` >= 2147483647 OR `expire` > UNIX_TIMESTAMP())
        ORDER BY `id` DESC
        LIMIT 1
    ]], {
        identifiersByProvider.license,
        identifiersByProvider.discord,
        identifiersByProvider.ip,
    })

    if banQueryOk and activeBan then
        local reason = tostring(activeBan.reason or 'No reason supplied.')
        return nil, ('You are banned from this server. Reason: %s'):format(reason)
    end

    local resolvedAccountId = nil
    for _, item in ipairs(identifiers) do
        local existing = MySQL.scalar.await([[
            SELECT `account_id`
            FROM `himo_identifiers`
            WHERE `provider` = ? AND `identifier` = ?
            LIMIT 1
        ]], { item.provider, item.identifier })

        if existing then
            existing = tonumber(existing)
            if resolvedAccountId and resolvedAccountId ~= existing then
                HimoLogger.error(('Identifier collision for source %d (%d vs %d).'):format(source, resolvedAccountId, existing))
                return nil, 'Your account identifiers are linked to conflicting accounts. Contact server staff.'
            end
            resolvedAccountId = existing
        end
    end

    local playerName = GetPlayerName(source)
    local created = false

    if not resolvedAccountId then
        resolvedAccountId = MySQL.insert.await([[
            INSERT INTO `himo_accounts` (`display_name`, `last_seen_name`, `last_seen_at`)
            VALUES (?, ?, CURRENT_TIMESTAMP)
        ]], { playerName, playerName })
        created = true
    else
        MySQL.update.await([[
            UPDATE `himo_accounts`
            SET `last_seen_name` = ?, `last_seen_at` = CURRENT_TIMESTAMP
            WHERE `id` = ?
        ]], { playerName, resolvedAccountId })
    end

    resolvedAccountId = tonumber(resolvedAccountId)

    for _, item in ipairs(identifiers) do
        MySQL.query.await([[
            INSERT INTO `himo_identifiers` (`account_id`, `provider`, `identifier`, `last_seen_at`)
            VALUES (?, ?, ?, CURRENT_TIMESTAMP)
            ON DUPLICATE KEY UPDATE `last_seen_at` = CURRENT_TIMESTAMP
        ]], { resolvedAccountId, item.provider, item.identifier })
    end

    if created and HimoPermissions and HimoPermissions.bootstrapOwner then
        HimoPermissions.bootstrapOwner(resolvedAccountId)
    end

    local account = MySQL.single.await([[
        SELECT `is_banned`, `ban_reason`
        FROM `himo_accounts`
        WHERE `id` = ?
        LIMIT 1
    ]], { resolvedAccountId })

    if account and tonumber(account.is_banned) == 1 then
        return nil, account.ban_reason or 'This account is banned from the server.'
    end

    return resolvedAccountId
end
