local function hasEntries(value)
    return type(value) == 'table' and next(value) ~= nil
end

local function fallbackJobs()
    return {
        unemployed = {
            label = 'Unemployed',
            type = 'none',
            defaultDuty = false,
            offDutyPay = false,
            grades = {
                [0] = { name = 'Unemployed', label = 'Unemployed', payment = 0, isboss = false }
            }
        }
    }
end

local function fallbackGangs()
    return {
        none = {
            label = 'No Gang',
            type = 'gang',
            grades = {
                [0] = { name = 'none', label = 'none', isboss = false }
            }
        }
    }
end

local function loadCatalogs()
    local jobs = exports.himo_core:GetJobDefinitions() or {}
    local gangs = exports.himo_core:GetGroupDefinitions('gang') or {}

    if not hasEntries(jobs) then jobs = fallbackJobs() end
    if not hasEntries(gangs) then gangs = fallbackGangs() end

    exports.himo_qb_bridge:SetSharedCatalog('Jobs', jobs)
    exports.himo_qb_bridge:SetSharedCatalog('Gangs', gangs)

    print(('[HimotheeCompat] Primed QBX shared groups: jobs=%d gangs=%d.'):format(
        (function() local n = 0 for _ in pairs(jobs) do n = n + 1 end return n end)(),
        (function() local n = 0 for _ in pairs(gangs) do n = n + 1 end return n end)()
    ))
end

loadCatalogs()

exports('ReloadGroupCatalogs', loadCatalogs)
