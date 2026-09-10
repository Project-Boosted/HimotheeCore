HimoJobs = HimoJobs or {}

local function sourceKey(source)
    return tonumber(source) or source
end

local function isTrue(value)
    return value == true or value == 1 or value == '1'
end

local function loadRows(characterId)
    return MySQL.query.await([[
        SELECT cj.`job_name`, cj.`grade`, cj.`is_primary`, cj.`on_duty`,
               j.`label` AS job_label, j.`type` AS job_type,
               j.`default_duty`, j.`off_duty_pay`,
               g.`name` AS grade_name, g.`label` AS grade_label,
               g.`salary`, g.`is_boss`, g.`permissions`
        FROM `himo_character_jobs` cj
        JOIN `himo_jobs` j ON j.`name` = cj.`job_name` AND j.`is_active` = 1
        JOIN `himo_job_grades` g ON g.`job_name` = cj.`job_name` AND g.`grade` = cj.`grade`
        WHERE cj.`character_id` = ?
        ORDER BY cj.`is_primary` DESC, cj.`job_name` ASC
    ]], { characterId }) or {}
end

local function primary(rows)
    for _, job in ipairs(rows or {}) do
        if isTrue(job.is_primary) then return job end
    end
    return nil
end

local function stateJob(row)
    if not row then return nil end
    return {
        name = row.job_name,
        label = row.job_label or row.job_name,
        type = row.job_type,
        grade = tonumber(row.grade) or 0,
        gradeName = row.grade_name,
        gradeLabel = row.grade_label,
        salary = tonumber(row.salary) or 0,
        isBoss = isTrue(row.is_boss),
        onDuty = isTrue(row.on_duty)
    }
end

function HimoJobs.getDefinition(jobName, grade)
    jobName = tostring(jobName or '')
    grade = tonumber(grade) or 0
    if jobName == '' or grade < 0 then return nil end

    return MySQL.single.await([[
        SELECT j.`name`, j.`label`, j.`type`, j.`default_duty`, j.`off_duty_pay`,
               g.`grade`, g.`name` AS grade_name, g.`label` AS grade_label,
               g.`salary`, g.`is_boss`, g.`permissions`
        FROM `himo_jobs` j
        JOIN `himo_job_grades` g ON g.`job_name` = j.`name`
        WHERE j.`name` = ? AND g.`grade` = ? AND j.`is_active` = 1
        LIMIT 1
    ]], { jobName, grade })
end

function HimoJobs.sync(source)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    character.jobs = loadRows(character.id)
    local current = primary(character.jobs)
    HimoState.setPlayer(source, 'himo:job', stateJob(current))
    HimoState.setPlayer(source, 'himo:onDuty', current and isTrue(current.on_duty) or false)

    TriggerClientEvent('himo_core:client:jobsChanged', source, character.jobs, current)
    TriggerEvent('himo_core:server:jobsChanged', source, character.jobs, current)
    return true, character.jobs
end

function HimoJobs.get(source)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    return character and character.jobs or {}
end

function HimoJobs.getPrimary(source)
    return primary(HimoJobs.get(source))
end

function HimoJobs.add(source, jobName, grade, makePrimary)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local definition = HimoJobs.getDefinition(jobName, grade)
    if not definition then return false, 'Unknown job or grade.' end

    local existingPrimary = HimoJobs.getPrimary(source)
    local shouldPrimary = makePrimary == true or existingPrimary == nil
    local defaultDuty = isTrue(definition.default_duty) and 1 or 0

    local ok = MySQL.startTransaction(function(query)
        if shouldPrimary then
            query('UPDATE `himo_character_jobs` SET `is_primary` = 0 WHERE `character_id` = ?', { character.id })
        end

        local result = query([[
            INSERT INTO `himo_character_jobs`
                (`character_id`, `job_name`, `grade`, `is_primary`, `on_duty`)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                `grade` = VALUES(`grade`),
                `is_primary` = IF(VALUES(`is_primary`) = 1, 1, `is_primary`),
                `on_duty` = IF(VALUES(`is_primary`) = 1, VALUES(`on_duty`), `on_duty`),
                `updated_at` = CURRENT_TIMESTAMP
        ]], { character.id, definition.name, definition.grade, shouldPrimary and 1 or 0, defaultDuty })

        return result ~= nil
    end)

    if not ok then return false, 'Could not assign job.' end
    HimoJobs.sync(source)

    HimoDatabase.audit({
        accountId = HimoAccounts[source], characterId = character.id, source = source,
        action = 'job.assigned', targetType = 'job', targetId = definition.name,
        data = { grade = definition.grade, primary = shouldPrimary }
    })
    return true
end

function HimoJobs.setPrimary(source, jobName)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local assigned = MySQL.scalar.await([[
        SELECT 1 FROM `himo_character_jobs`
        WHERE `character_id` = ? AND `job_name` = ? LIMIT 1
    ]], { character.id, jobName })
    if not assigned then return false, 'Character does not have that job.' end

    local ok = MySQL.startTransaction(function(query)
        query('UPDATE `himo_character_jobs` SET `is_primary` = 0 WHERE `character_id` = ?', { character.id })
        local result = query([[
            UPDATE `himo_character_jobs`
            SET `is_primary` = 1, `updated_at` = CURRENT_TIMESTAMP
            WHERE `character_id` = ? AND `job_name` = ?
        ]], { character.id, jobName })
        return result ~= nil
    end)

    if not ok then return false, 'Could not set primary job.' end
    HimoJobs.sync(source)
    return true
end

function HimoJobs.setGrade(source, jobName, grade)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    local definition = HimoJobs.getDefinition(jobName, grade)
    if not definition then return false, 'Unknown job or grade.' end

    local changed = MySQL.update.await([[
        UPDATE `himo_character_jobs`
        SET `grade` = ?, `updated_at` = CURRENT_TIMESTAMP
        WHERE `character_id` = ? AND `job_name` = ?
    ]], { definition.grade, character.id, definition.name })
    if not changed or changed < 1 then return false, 'Character does not have that job.' end

    HimoJobs.sync(source)
    return true
end

function HimoJobs.setDuty(source, jobName, onDuty)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end

    jobName = tostring(jobName or '')
    if jobName == '' then
        local current = HimoJobs.getPrimary(source)
        jobName = current and current.job_name or ''
    end
    if jobName == '' then return false, 'No job was selected.' end

    local changed = MySQL.update.await([[
        UPDATE `himo_character_jobs`
        SET `on_duty` = ?, `updated_at` = CURRENT_TIMESTAMP
        WHERE `character_id` = ? AND `job_name` = ?
    ]], { onDuty == true and 1 or 0, character.id, jobName })
    if not changed or changed < 1 then return false, 'Character does not have that job.' end

    HimoJobs.sync(source)
    return true
end

function HimoJobs.remove(source, jobName)
    source = sourceKey(source)
    local character = HimoPlayers[source]
    if not character then return false, 'No character is loaded.' end
    jobName = tostring(jobName or '')
    if jobName == '' then return false, 'Job name is required.' end

    local current = HimoJobs.getPrimary(source)
    local wasPrimary = current and current.job_name == jobName

    local changed = MySQL.update.await([[
        DELETE FROM `himo_character_jobs`
        WHERE `character_id` = ? AND `job_name` = ?
    ]], { character.id, jobName })
    if not changed or changed < 1 then return false, 'Character does not have that job.' end

    local rows = loadRows(character.id)
    if #rows == 0 then
        MySQL.insert.await([[
            INSERT INTO `himo_character_jobs`
                (`character_id`, `job_name`, `grade`, `is_primary`, `on_duty`)
            VALUES (?, 'unemployed', 0, 1, 0)
        ]], { character.id })
    elseif wasPrimary then
        MySQL.update.await([[
            UPDATE `himo_character_jobs`
            SET `is_primary` = 1
            WHERE `character_id` = ? AND `job_name` = ?
        ]], { character.id, rows[1].job_name })
    end

    HimoJobs.sync(source)
    return true
end

AddEventHandler('himo_core:server:characterLoaded', function(source)
    HimoJobs.sync(source)
end)

exports('GetJobs', HimoJobs.get)
exports('GetPrimaryJob', HimoJobs.getPrimary)
exports('AddJob', HimoJobs.add)
exports('RemoveJob', HimoJobs.remove)
exports('SetPrimaryJob', HimoJobs.setPrimary)
exports('SetJobGrade', HimoJobs.setGrade)
exports('SetJobDuty', HimoJobs.setDuty)
