local cachedPlayerData
local clientCallbacks = {}

local QBCore = {
    Functions = {},
    Shared = {
        Items = {}, Vehicles = {}, Weapons = {}, Locations = {}, StarterItems = {},
        Jobs = {
            unemployed = {
                label = 'Unemployed', type = 'none', defaultDuty = false,
                grades = { [0] = { name = 'Unemployed', payment = 0, isboss = false } }
            }
        },
        Gangs = {
            none = { label = 'No Gang', grades = { [0] = { name = 'none', isboss = false } } }
        }
    }
}

local function isTrue(value) return value == true or value == 1 or value == '1' end
local function genderNumber(value)
    value = tostring(value or ''):lower()
    return (value == 'female' or value == 'f' or value == 'woman' or value == '1') and 1 or 0
end
local function getBalance(character, accountType)
    for _, entry in ipairs(character and character.balances or {}) do
        if entry.account_type == accountType then return tonumber(entry.balance) or 0 end
    end
    return 0
end
local function primaryJob(character)
    local exported = exports.himo_core:GetPrimaryJob()
    if exported then return exported end
    for _, job in ipairs(character and character.jobs or {}) do
        if isTrue(job.is_primary) then return job end
    end
end
local function buildJob(character)
    local row = primaryJob(character)
    if not row then
        return { name = 'unemployed', label = 'Unemployed', type = 'none', onduty = false,
            payment = 0, isboss = false, grade = { name = 'Unemployed', level = 0 } }
    end
    return {
        name = row.job_name or 'unemployed', label = row.job_label or row.job_name or 'Unemployed',
        type = row.job_type or 'none', onduty = isTrue(row.on_duty), payment = tonumber(row.salary) or 0,
        isboss = isTrue(row.is_boss),
        grade = { name = row.grade_name or row.grade_label or tostring(row.grade or 0), level = tonumber(row.grade) or 0 }
    }
end
local function buildGang()
    local row = exports.himo_core:GetPrimaryGroup()
    if not row or row.group_name == 'none' then
        return { name = 'none', label = 'No Gang', isboss = false, grade = { name = 'none', level = 0 } }
    end
    return {
        name = row.group_name, label = row.group_label or row.group_name, isboss = isTrue(row.is_boss),
        grade = { name = row.grade_name or row.grade_label or tostring(row.grade or 0), level = tonumber(row.grade) or 0 }
    }
end
local function buildGroups(character)
    local result = {}
    for _, row in ipairs(exports.himo_core:GetJobs() or character.jobs or {}) do
        result[row.job_name] = tonumber(row.grade) or 0
    end
    for _, row in ipairs(exports.himo_core:GetGroups() or character.groups or {}) do
        result[row.group_name] = tonumber(row.grade) or 0
    end
    return result
end
local function registerSharedJob(job)
    if not job or not job.name then return end
    local grade = tonumber(job.grade and job.grade.level) or 0
    QBCore.Shared.Jobs[job.name] = QBCore.Shared.Jobs[job.name] or {
        label = job.label or job.name, type = job.type, defaultDuty = job.onduty, grades = {}
    }
    QBCore.Shared.Jobs[job.name].grades[grade] = {
        name = job.grade and job.grade.name or tostring(grade), payment = job.payment or 0, isboss = job.isboss == true
    }
end
local function registerSharedGang(gang)
    if not gang or not gang.name then return end
    local grade = tonumber(gang.grade and gang.grade.level) or 0
    QBCore.Shared.Gangs[gang.name] = QBCore.Shared.Gangs[gang.name] or { label = gang.label or gang.name, grades = {} }
    QBCore.Shared.Gangs[gang.name].grades[grade] = {
        name = gang.grade and gang.grade.name or tostring(grade), isboss = gang.isboss == true
    }
end

local function buildPlayerData()
    local character = exports.himo_core:GetCharacter()
    local base = {
        citizenid = '', source = GetPlayerServerId(PlayerId()),
        charinfo = { firstname = '', lastname = '', birthdate = '', nationality = '', gender = 0, phone = '' },
        money = { cash = 0, bank = 0 },
        metadata = { tracker = false, isdead = false, inlaststand = false, ishandcuffed = false, armor = 0, licences = {} },
        job = { name = 'unemployed', label = 'Unemployed', type = 'none', onduty = false,
            payment = 0, isboss = false, grade = { name = 'Unemployed', level = 0 } },
        gang = { name = 'none', label = 'No Gang', isboss = false, grade = { name = 'none', level = 0 } },
        groups = {}, items = {}
    }

    if not character then
        registerSharedJob(base.job) registerSharedGang(base.gang) return base
    end

    local metadata = exports.himo_core:GetMetadata() or character.metadata or {}
    local job, gang = buildJob(character), buildGang()
    registerSharedJob(job) registerSharedGang(gang)

    base.citizenid = character.citizen_id or ''
    base.charinfo = {
        firstname = character.first_name or '', lastname = character.last_name or '',
        birthdate = tostring(character.date_of_birth or ''):sub(1, 10),
        nationality = character.nationality or '', gender = genderNumber(character.gender),
        phone = character.phone_number or ''
    }
    base.money = { cash = getBalance(character, 'cash'), bank = getBalance(character, 'bank') }
    base.metadata = {}
    for key, value in pairs(metadata) do base.metadata[key] = value end
    base.metadata.tracker = metadata.tracker == true
    base.metadata.isdead = metadata.isdead == true
    base.metadata.inlaststand = metadata.inlaststand == true
    base.metadata.ishandcuffed = metadata.ishandcuffed == true
    base.metadata.armor = tonumber(character.armour or metadata.armor) or 0
    base.metadata.licences = type(metadata.licences) == 'table' and metadata.licences or {}
    base.job, base.gang = job, gang
    base.groups = buildGroups(character)
    base.items = type(character.items) == 'table' and character.items or {}
    return base
end

local function refreshPlayerData() cachedPlayerData = buildPlayerData() return cachedPlayerData end
QBCore.Functions.GetPlayerData = function(cb)
    local data = refreshPlayerData()
    if type(cb) == 'function' then cb(data) end
    return data
end
QBCore.Functions.GetPlayer = function() return QBCore.Functions.GetPlayerData() end
QBCore.Functions.Notify = function(text, notifyType, duration)
    local description = type(text) == 'table' and (text.text or text.caption) or tostring(text)
    lib.notify({ description = description, type = notifyType or 'inform', duration = duration })
end
QBCore.Functions.TriggerCallback = function(name, cb, ...)
    if type(name) ~= 'string' or type(cb) ~= 'function' then return end
    clientCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
end
RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    local cb = clientCallbacks[name]
    if not cb then return end
    clientCallbacks[name] = nil
    cb(...)
end)

exports('GetCoreObject', function() return QBCore end)

local function pushPlayerData()
    local data = refreshPlayerData()
    TriggerEvent('QBCore:Player:SetPlayerData', data)
    return data
end

RegisterNetEvent('himo_core:client:characterLoaded', pushPlayerData)
RegisterNetEvent('himo_core:client:moneyChanged', pushPlayerData)
RegisterNetEvent('himo_core:client:metadataSnapshot', pushPlayerData)
RegisterNetEvent('himo_core:client:metadataChanged', pushPlayerData)
RegisterNetEvent('himo_core:client:playerDataFieldChanged', function(key, value)
    if cachedPlayerData then cachedPlayerData[key] = value end
    pushPlayerData()
end)
RegisterNetEvent('himo_core:client:jobsChanged', function()
    local oldJob = cachedPlayerData and cachedPlayerData.job or nil
    local data = pushPlayerData()
    if not oldJob or oldJob.name ~= data.job.name or oldJob.grade.level ~= data.job.grade.level then
        TriggerEvent('QBCore:Client:OnJobUpdate', data.job)
    else
        TriggerEvent('QBCore:Client:SetDuty', data.job.onduty)
    end
end)
RegisterNetEvent('himo_core:client:groupsChanged', function()
    local oldGang = cachedPlayerData and cachedPlayerData.gang or nil
    local data = pushPlayerData()
    if not oldGang or oldGang.name ~= data.gang.name or oldGang.grade.level ~= data.gang.grade.level then
        TriggerEvent('QBCore:Client:OnGangUpdate', data.gang)
    end
end)
RegisterNetEvent('himo_core:client:playerLoaded', function()
    pushPlayerData()
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)
RegisterNetEvent('himo_core:client:characterUnloaded', function()
    cachedPlayerData = nil
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)
