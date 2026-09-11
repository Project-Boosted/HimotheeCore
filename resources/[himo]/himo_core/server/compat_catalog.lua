local function isTrue(value)
    return value == true or value == 1 or value == '1'
end

local function decode(value)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return {} end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or {}
end

local function getJobDefinitions()
    local rows = MySQL.query.await([[
        SELECT j.`name`, j.`label`, j.`type`, j.`default_duty`, j.`off_duty_pay`,
               g.`grade`, g.`name` AS grade_name, g.`label` AS grade_label,
               g.`salary`, g.`is_boss`, g.`permissions`
        FROM `himo_jobs` j
        LEFT JOIN `himo_job_grades` g ON g.`job_name` = j.`name`
        WHERE j.`is_active` = 1
        ORDER BY j.`name`, g.`grade`
    ]]) or {}

    local jobs = {}
    for _, row in ipairs(rows) do
        local job = jobs[row.name]
        if not job then
            job = {
                label = row.label or row.name,
                type = row.type or 'none',
                defaultDuty = isTrue(row.default_duty),
                offDutyPay = isTrue(row.off_duty_pay),
                grades = {}
            }
            jobs[row.name] = job
        end
        if row.grade ~= nil then
            local grade = tonumber(row.grade) or 0
            job.grades[grade] = {
                name = row.grade_name or tostring(grade),
                label = row.grade_label or row.grade_name or tostring(grade),
                payment = tonumber(row.salary) or 0,
                isboss = isTrue(row.is_boss),
                permissions = decode(row.permissions)
            }
        end
    end
    return jobs
end

local function getGroupDefinitions(groupType)
    local params = {}
    local where = 'WHERE g.`is_active` = 1'
    if groupType and groupType ~= '' then
        where = where .. ' AND g.`type` = ?'
        params[1] = groupType
    end

    local rows = MySQL.query.await(([=[
        SELECT g.`name`, g.`label`, g.`type`, gg.`grade`,
               gg.`name` AS grade_name, gg.`label` AS grade_label,
               gg.`is_boss`, gg.`permissions`
        FROM `himo_groups` g
        LEFT JOIN `himo_group_grades` gg ON gg.`group_name` = g.`name`
        %s
        ORDER BY g.`name`, gg.`grade`
    ]=]):format(where), params) or {}

    local groups = {}
    for _, row in ipairs(rows) do
        local group = groups[row.name]
        if not group then
            group = { label = row.label or row.name, type = row.type or 'group', grades = {} }
            groups[row.name] = group
        end
        if row.grade ~= nil then
            local grade = tonumber(row.grade) or 0
            group.grades[grade] = {
                name = row.grade_name or tostring(grade),
                label = row.grade_label or row.grade_name or tostring(grade),
                isboss = isTrue(row.is_boss),
                permissions = decode(row.permissions)
            }
        end
    end
    return groups
end

exports('GetJobDefinitions', getJobDefinitions)
exports('GetGroupDefinitions', getGroupDefinitions)
