HimoGroups = HimoGroups or {}

local function sourceKey(source)
    return tonumber(source) or source
end

local function isTrue(value)
    return value == true or value == 1 or value == '1'
end

local function loadRows(characterId)
    return MySQL.query.await([[
        SELECT cg.`group_name`, cg.`grade`, cg.`is_primary`,
               g.`label` AS group_label, g.`type` AS group_type,
               gg.`name` AS grade_name, gg.`label` AS grade_label,
               gg.`is_boss`, gg.`permissions`
        FROM `himo_character_groups` cg
        JOIN `himo_groups` g ON g.`name` = cg.`group_name` AND g.`is_active` = 1
        JOIN `himo_group_grades` gg ON gg.`group_name` = cg.`group_name` AND gg.`grade` = cg.`grade`
        WHERE cg.`character_id` = ?
        ORDER BY cg.`is_primary` DESC, cg.`group_name` ASC
    ]], { characterId }) or {}
end

local function primary(rows, groupType)
    for _, group in ipairs(rows or {}) do
        if isTrue(group.is_primary) and (not groupType or group.group_type == groupType) then
            return group
        end
    end
    return nil
end

local function stateGroup(row)
    if not row then return nil end
    return {
        name = row.group_name,
        label = row.group_label or row.group_name,
        type = row.group_type,
        grade = tonumber(row.grade) or 0,
        gradeName = row.grade_name,
        gradeLabel = row.grade_label,
        isBoss = isTrue(row.is_boss)
    }
end

function HimoGroups.getDefinition(groupName, grade)
    groupName = tostring(groupName or '')
    grade = tonumber(grade) or 0
    if groupName == '' or grade < 0 then return nil end

    return MySQL.single.await([[
        SELECT g.`name`, g.`label`, g.`type`, gg.`grade`,
               gg.`name` AS grade_name, gg.`label` AS grade_label,
               gg.`is_boss`, gg.`permissions`
        FROM `himo_groups` g
        JOIN `himo_group_grades` gg ON gg.`group_name` = g.`name`
        WHERE g.`name` = ? AND gg.`grade` = ? AND g.`is_active` = 1
        LIMIT 1
    ]], { groupName, grade })
end

function HimoGroups.sync(source)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    character.groups = loadRows(character.id)
    local gang = primary(character.groups, 'gang')
    HimoState.setPlayer(source, 'himo:group', stateGroup(gang))

    TriggerClientEvent('himo_core:client:groupsChanged', source, character.groups, gang)
    TriggerEvent('himo_core:server:groupsChanged', source, character.groups, gang)
    return true, character.groups
end

function HimoGroups.get(source)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    return character and character.groups or {}
end

function HimoGroups.getPrimary(source, groupType)
    return primary(HimoGroups.get(source), groupType)
end

function HimoGroups.add(source, groupName, grade, makePrimary)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local definition = HimoGroups.getDefinition(groupName, grade)
    if not definition then return false, 'Unknown group or grade.' end

    local currentPrimary = HimoGroups.getPrimary(source, definition.type)
    local shouldPrimary = makePrimary == true or currentPrimary == nil

    local ok = MySQL.startTransaction(function(query)
        if shouldPrimary then
            query([[
                UPDATE `himo_character_groups` cg
                JOIN `himo_groups` g ON g.`name` = cg.`group_name`
                SET cg.`is_primary` = 0
                WHERE cg.`character_id` = ? AND g.`type` = ?
            ]], { character.id, definition.type })
        end

        local result = query([[
            INSERT INTO `himo_character_groups`
                (`character_id`, `group_name`, `grade`, `is_primary`)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                `grade` = VALUES(`grade`),
                `is_primary` = IF(VALUES(`is_primary`) = 1, 1, `is_primary`),
                `updated_at` = CURRENT_TIMESTAMP
        ]], { character.id, definition.name, definition.grade, shouldPrimary and 1 or 0 })
        return result ~= nil
    end)

    if not ok then return false, 'Could not assign group.' end
    HimoGroups.sync(source)
    return true
end

function HimoGroups.setPrimary(source, groupName)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local row = MySQL.single.await([[
        SELECT cg.`group_name`, g.`type`
        FROM `himo_character_groups` cg
        JOIN `himo_groups` g ON g.`name` = cg.`group_name`
        WHERE cg.`character_id` = ? AND cg.`group_name` = ?
        LIMIT 1
    ]], { character.id, groupName })
    if not row then return false, 'Character does not have that group.' end

    local ok = MySQL.startTransaction(function(query)
        query([[
            UPDATE `himo_character_groups` cg
            JOIN `himo_groups` g ON g.`name` = cg.`group_name`
            SET cg.`is_primary` = 0
            WHERE cg.`character_id` = ? AND g.`type` = ?
        ]], { character.id, row.type })
        local result = query([[
            UPDATE `himo_character_groups`
            SET `is_primary` = 1, `updated_at` = CURRENT_TIMESTAMP
            WHERE `character_id` = ? AND `group_name` = ?
        ]], { character.id, groupName })
        return result ~= nil
    end)

    if not ok then return false, 'Could not set primary group.' end
    HimoGroups.sync(source)
    return true
end

function HimoGroups.setGrade(source, groupName, grade)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local definition = HimoGroups.getDefinition(groupName, grade)
    if not definition then return false, 'Unknown group or grade.' end

    local changed = MySQL.update.await([[
        UPDATE `himo_character_groups`
        SET `grade` = ?, `updated_at` = CURRENT_TIMESTAMP
        WHERE `character_id` = ? AND `group_name` = ?
    ]], { definition.grade, character.id, definition.name })
    if not changed or changed < 1 then return false, 'Character does not have that group.' end

    HimoGroups.sync(source)
    return true
end

function HimoGroups.remove(source, groupName)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local current = nil
    for _, group in ipairs(character.groups or {}) do
        if group.group_name == groupName then current = group break end
    end
    if not current then return false, 'Character does not have that group.' end

    local changed = MySQL.update.await([[
        DELETE FROM `himo_character_groups`
        WHERE `character_id` = ? AND `group_name` = ?
    ]], { character.id, groupName })
    if not changed or changed < 1 then return false, 'Character does not have that group.' end

    local rows = loadRows(character.id)
    if isTrue(current.is_primary) then
        for _, row in ipairs(rows) do
            if row.group_type == current.group_type then
                MySQL.update.await([[
                    UPDATE `himo_character_groups`
                    SET `is_primary` = 1
                    WHERE `character_id` = ? AND `group_name` = ?
                ]], { character.id, row.group_name })
                break
            end
        end
    end

    HimoGroups.sync(source)
    return true
end

AddEventHandler('himo_core:server:characterLoaded', function(source)
    HimoGroups.sync(source)
end)

exports('GetGroups', HimoGroups.get)
exports('GetPrimaryGroup', HimoGroups.getPrimary)
exports('AddGroup', HimoGroups.add)
exports('RemoveGroup', HimoGroups.remove)
exports('SetPrimaryGroup', HimoGroups.setPrimary)
exports('SetGroupGrade', HimoGroups.setGrade)
