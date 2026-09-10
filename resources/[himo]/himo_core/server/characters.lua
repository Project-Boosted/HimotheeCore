HimoCharacters = HimoCharacters or {}
HimoPlayers = HimoPlayers or {}

local function cleanName(value)
    if type(value) ~= 'string' then return nil end
    value = value:gsub("[^%a%-%s']", ''):gsub('^%s+', ''):gsub('%s+$', '')
    if #value < 2 or #value > 50 then return nil end
    return value
end

local function validDate(value)
    if value == nil or value == '' then return nil end
    if type(value) ~= 'string' or not value:match('^%d%d%d%d%-%d%d%-%d%d$') then
        return false
    end
    local year, month, day = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if year < 1900 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31 then
        return false
    end
    return value
end

local function generateCitizenId()
    local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    for _ = 1, 25 do
        local id = 'HIM'
        for _ = 1, 9 do
            local index = math.random(1, #chars)
            id = id .. chars:sub(index, index)
        end
        local exists = MySQL.scalar.await('SELECT 1 FROM `himo_characters` WHERE `citizen_id` = ? LIMIT 1', { id })
        if not exists then return id end
    end
    return nil
end

function HimoCharacters.list(accountId)
    return MySQL.query.await([[
        SELECT `id`, `citizen_id`, `slot`, `first_name`, `last_name`, `date_of_birth`,
               `gender`, `nationality`, `phone_number`, `last_played_at`, `created_at`
        FROM `himo_characters`
        WHERE `account_id` = ? AND `is_deleted` = 0
        ORDER BY `slot` ASC
    ]], { accountId }) or {}
end

function HimoCharacters.getById(characterId, accountId)
    return MySQL.single.await([[
        SELECT c.*, m.metadata, m.position_x, m.position_y, m.position_z, m.heading,
               m.health, m.armour
        FROM `himo_characters` c
        LEFT JOIN `himo_character_metadata` m ON m.character_id = c.id
        WHERE c.id = ? AND c.account_id = ? AND c.is_deleted = 0
        LIMIT 1
    ]], { characterId, accountId })
end

function HimoCharacters.create(source, data)
    local accountId = HimoAccounts[source]
    if not accountId then return nil, 'Account is not loaded.' end
    if type(data) ~= 'table' then return nil, 'Character data is required.' end

    local firstName = cleanName(data.firstName)
    local lastName = cleanName(data.lastName)
    if not firstName or not lastName then
        return nil, 'First and last names must be 2-50 valid characters.'
    end

    local dateOfBirth = validDate(data.dateOfBirth)
    if dateOfBirth == false then
        return nil, 'Date of birth must use YYYY-MM-DD.'
    end

    local count = tonumber(MySQL.scalar.await([[
        SELECT COUNT(*) FROM `himo_characters`
        WHERE `account_id` = ? AND `is_deleted` = 0
    ]], { accountId })) or 0

    if count >= HimoConfig.MaxCharacters then
        return nil, ('Character limit reached (%d).'):format(HimoConfig.MaxCharacters)
    end

    local occupiedRows = MySQL.query.await([[
        SELECT `slot` FROM `himo_characters`
        WHERE `account_id` = ? AND `is_deleted` = 0
    ]], { accountId }) or {}

    local occupied = {}
    for _, row in ipairs(occupiedRows) do occupied[tonumber(row.slot)] = true end

    local slot
    for candidate = 1, HimoConfig.MaxCharacters do
        if not occupied[candidate] then slot = candidate break end
    end
    if not slot then return nil, 'No character slot is available.' end

    local citizenId = generateCitizenId()
    if not citizenId then return nil, 'Could not generate a unique citizen ID.' end

    local characterId
    local success = MySQL.startTransaction(function(query)
        local inserted = query([[
            INSERT INTO `himo_characters`
                (`account_id`, `citizen_id`, `slot`, `first_name`, `last_name`, `date_of_birth`, `gender`, `nationality`)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            accountId, citizenId, slot, firstName, lastName,
            dateOfBirth, data.gender, data.nationality
        })

        if not inserted or not inserted.insertId then return false end
        characterId = tonumber(inserted.insertId)

        local metadata = query([[
            INSERT INTO `himo_character_metadata` (`character_id`, `metadata`)
            VALUES (?, JSON_OBJECT())
        ]], { characterId })
        if not metadata then return false end

        local cash = query([[
            INSERT INTO `himo_account_balances` (`character_id`, `account_type`, `balance`)
            VALUES (?, 'cash', ?)
        ]], { characterId, HimoConfig.StartingCash })
        if not cash then return false end

        local bank = query([[
            INSERT INTO `himo_account_balances` (`character_id`, `account_type`, `balance`)
            VALUES (?, 'bank', ?)
        ]], { characterId, HimoConfig.StartingBank })
        if not bank then return false end

        local job = query([[
            INSERT INTO `himo_character_jobs`
                (`character_id`, `job_name`, `grade`, `is_primary`, `on_duty`)
            VALUES (?, 'unemployed', 0, 1, 0)
        ]], { characterId })
        if not job then return false end

        return true
    end)

    if not success or not characterId then
        return nil, 'Character setup transaction failed.'
    end

    HimoDatabase.audit({
        accountId = accountId,
        characterId = characterId,
        source = source,
        action = 'character.created',
        targetType = 'character',
        targetId = characterId,
        data = { citizenId = citizenId, slot = slot }
    })

    return HimoCharacters.getById(characterId, accountId)
end

function HimoCharacters.load(source, characterId)
    local accountId = HimoAccounts[source]
    if not accountId then return nil, 'Account is not loaded.' end

    local character = HimoCharacters.getById(characterId, accountId)
    if not character then return nil, 'Character not found for this account.' end

    if HimoPlayers[source] then
        HimoCharacters.unload(source)
    end

    if type(character.metadata) == 'string' then
        character.metadata = json.decode(character.metadata) or {}
    elseif type(character.metadata) ~= 'table' then
        character.metadata = {}
    end

    character.balances = MySQL.query.await([[
        SELECT `account_type`, `balance`
        FROM `himo_account_balances`
        WHERE `character_id` = ?
    ]], { character.id }) or {}

    character.jobs = MySQL.query.await([[
        SELECT cj.`job_name`, cj.`grade`, cj.`is_primary`, cj.`on_duty`,
               j.`label` AS job_label, g.`label` AS grade_label, g.`salary`, g.`is_boss`
        FROM `himo_character_jobs` cj
        JOIN `himo_jobs` j ON j.`name` = cj.`job_name`
        JOIN `himo_job_grades` g ON g.`job_name` = cj.`job_name` AND g.`grade` = cj.`grade`
        WHERE cj.`character_id` = ?
        ORDER BY cj.`is_primary` DESC, cj.`job_name` ASC
    ]], { character.id }) or {}

    HimoPlayers[source] = character
    MySQL.update.await('UPDATE `himo_characters` SET `last_played_at` = CURRENT_TIMESTAMP WHERE `id` = ?', { character.id })

    local player = Player(source)
    if player and player.state then
        player.state:set('himoCharacterId', character.id, true)
        player.state:set('himoCitizenId', character.citizen_id, true)
        player.state:set('himoCharacterLoaded', true, true)
    end

    TriggerClientEvent('himo_core:client:characterLoaded', source, character)
    TriggerEvent('himo_core:server:characterLoaded', source, character)

    HimoDatabase.audit({
        accountId = accountId,
        characterId = character.id,
        source = source,
        action = 'character.loaded',
        targetType = 'character',
        targetId = character.id
    })

    return character
end

function HimoCharacters.unload(source)
    local character = HimoPlayers[source]
    if not character then return end

    TriggerEvent('himo_core:server:characterUnloaded', source, character)
    TriggerClientEvent('himo_core:client:characterUnloaded', source)
    HimoPlayers[source] = nil

    local player = Player(source)
    if player and player.state then
        player.state:set('himoCharacterId', nil, true)
        player.state:set('himoCitizenId', nil, true)
        player.state:set('himoCharacterLoaded', false, true)
    end
end

function HimoCharacters.savePosition(source, position)
    local character = HimoPlayers[source]
    if not character then return false end
    if type(position) ~= 'table' then return false end

    MySQL.update.await([[
        UPDATE `himo_character_metadata`
        SET `position_x` = ?, `position_y` = ?, `position_z` = ?, `heading` = ?,
            `health` = COALESCE(?, `health`), `armour` = COALESCE(?, `armour`)
        WHERE `character_id` = ?
    ]], {
        position.x, position.y, position.z, position.heading,
        position.health, position.armour, character.id
    })

    return true
end
