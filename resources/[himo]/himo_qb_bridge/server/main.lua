local QBCore = {
    Functions = {},
    Shared = {
        Jobs = {},
        Gangs = {
            none = {
                label = 'No Gang',
                grades = { [0] = { name = 'none', isboss = false } }
            }
        }
    }
}

local function isTrue(value)
    return value == true or value == 1 or value == '1'
end

local function genderNumber(value)
    value = tostring(value or ''):lower()
    return (value == 'female' or value == 'f' or value == 'woman' or value == '1') and 1 or 0
end

local function getBalance(character, accountType)
    for _, entry in ipairs(character and character.balances or {}) do
        if entry.account_type == accountType then
            return tonumber(entry.balance) or 0
        end
    end
    return 0
end

local function primaryJob(character)
    for _, job in ipairs(character and character.jobs or {}) do
        if isTrue(job.is_primary) then return job end
    end
    return nil
end

local function buildJob(character)
    local row = primaryJob(character)
    if not row then
        return {
            name = 'unemployed', label = 'Unemployed', type = 'none', onduty = false,
            payment = 0, isboss = false, grade = { name = 'Unemployed', level = 0 }
        }
    end

    return {
        name = row.job_name or 'unemployed',
        label = row.job_label or row.job_name or 'Unemployed',
        type = row.job_type or 'none',
        onduty = isTrue(row.on_duty),
        payment = tonumber(row.salary) or 0,
        isboss = isTrue(row.is_boss),
        grade = {
            name = row.grade_label or tostring(row.grade or 0),
            level = tonumber(row.grade) or 0
        }
    }
end

local function registerSharedJob(job)
    if not job or not job.name then return end
    local grade = tonumber(job.grade and job.grade.level) or 0
    QBCore.Shared.Jobs[job.name] = QBCore.Shared.Jobs[job.name] or {
        label = job.label or job.name,
        type = job.type,
        defaultDuty = job.onduty,
        grades = {}
    }
    QBCore.Shared.Jobs[job.name].grades[grade] = {
        name = job.grade and job.grade.name or tostring(grade),
        payment = job.payment or 0,
        isboss = job.isboss == true
    }
end

local function buildPlayerData(source, character)
    local metadata = type(character.metadata) == 'table' and character.metadata or {}
    local job = buildJob(character)
    registerSharedJob(job)

    return {
        source = source,
        citizenid = character.citizen_id,
        charinfo = {
            firstname = character.first_name or '',
            lastname = character.last_name or '',
            birthdate = tostring(character.date_of_birth or ''):sub(1, 10),
            nationality = character.nationality or '',
            gender = genderNumber(character.gender)
        },
        money = {
            cash = getBalance(character, 'cash'),
            bank = getBalance(character, 'bank')
        },
        metadata = {
            tracker = metadata.tracker == true,
            isdead = metadata.isdead == true,
            inlaststand = metadata.inlaststand == true,
            ishandcuffed = metadata.ishandcuffed == true,
            armor = tonumber(character.armour or metadata.armor) or 0
        },
        job = job,
        gang = {
            name = 'none', label = 'No Gang', isboss = false,
            grade = { name = 'none', level = 0 }
        }
    }
end

local function wrapPlayer(source)
    source = tonumber(source) or source
    local character = exports['himo_core']:GetCharacter(source)
    local himoPlayer = exports['himo_core']:GetPlayer(source)
    if not character or not himoPlayer then return nil end

    local wrapper = {
        PlayerData = buildPlayerData(source, character),
        Functions = {}
    }

    wrapper.Functions.GetMoney = function(accountType)
        return himoPlayer.Functions.GetMoney(accountType)
    end

    wrapper.Functions.AddMoney = function(accountType, amount, reason)
        local success = himoPlayer.Functions.AddMoney(accountType, tonumber(amount) or 0, reason or 'qb-bridge')
        if success then
            wrapper.PlayerData.money[accountType] = himoPlayer.Functions.GetMoney(accountType) or 0
        end
        return success == true
    end

    wrapper.Functions.RemoveMoney = function(accountType, amount, reason)
        local success = himoPlayer.Functions.RemoveMoney(accountType, tonumber(amount) or 0, reason or 'qb-bridge')
        if success then
            wrapper.PlayerData.money[accountType] = himoPlayer.Functions.GetMoney(accountType) or 0
        end
        return success == true
    end

    wrapper.Functions.GetIdentifier = function()
        return character.citizen_id
    end

    return wrapper
end

QBCore.Functions.GetPlayer = wrapPlayer

QBCore.Functions.GetQBPlayers = function()
    local players = {}
    for _, source in ipairs(GetPlayers()) do
        local numericSource = tonumber(source)
        local player = wrapPlayer(numericSource)
        if player then players[numericSource] = player end
    end
    return players
end

local function qbExport(name, cb)
    AddEventHandler(('__cfx_export_qb-core_%s'):format(name), function(setCB)
        setCB(cb)
    end)
end

qbExport('GetCoreObject', function()
    return QBCore
end)

exports('GetCoreObject', function()
    return QBCore
end)

AddEventHandler('himo_core:server:playerLoaded', function(source)
    TriggerEvent('QBCore:Server:OnPlayerLoaded', source)
end)

AddEventHandler('himo_core:server:characterUnloaded', function(source)
    TriggerEvent('QBCore:Server:OnPlayerUnload', source)
end)
