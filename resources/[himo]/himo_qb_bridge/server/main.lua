local QBCore = {
    Functions = {},
    Shared = {
        Items = {},
        Vehicles = {},
        Weapons = {},
        Locations = {},
        StarterItems = {},
        Jobs = {
            unemployed = {
                label = 'Unemployed', type = 'none', defaultDuty = false,
                grades = { [0] = { name = 'Unemployed', payment = 0, isboss = false } }
            }
        },
        Gangs = {
            none = { label = 'No Gang', grades = { [0] = { name = 'none', isboss = false } } }
        }
    },
    ServerCallbacks = {}
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
local function buildGang(source)
    local row = exports.himo_core:GetPrimaryGroup(source, 'gang')
    if not row or row.group_name == 'none' then
        return { name = 'none', label = 'No Gang', isboss = false, grade = { name = 'none', level = 0 } }
    end
    return {
        name = row.group_name, label = row.group_label or row.group_name, isboss = isTrue(row.is_boss),
        grade = { name = row.grade_name or row.grade_label or tostring(row.grade or 0), level = tonumber(row.grade) or 0 }
    }
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

local function buildPlayerData(source, character)
    local metadata = type(character.metadata) == 'table' and character.metadata or {}
    local job, gang = buildJob(character), buildGang(source)
    registerSharedJob(job) registerSharedGang(gang)

    local qbMetadata = {}
    for key, value in pairs(metadata) do qbMetadata[key] = value end
    qbMetadata.tracker = metadata.tracker == true
    qbMetadata.isdead = metadata.isdead == true
    qbMetadata.inlaststand = metadata.inlaststand == true
    qbMetadata.ishandcuffed = metadata.ishandcuffed == true
    qbMetadata.armor = tonumber(character.armour or metadata.armor) or 0
    qbMetadata.licences = type(metadata.licences) == 'table' and metadata.licences or {}

    return {
        source = source, citizenid = character.citizen_id,
        charinfo = {
            firstname = character.first_name or '', lastname = character.last_name or '',
            birthdate = tostring(character.date_of_birth or ''):sub(1, 10),
            nationality = character.nationality or '', gender = genderNumber(character.gender),
            account = character.citizen_id
        },
        money = { cash = getBalance(character, 'cash'), bank = getBalance(character, 'bank') },
        metadata = qbMetadata, job = job, gang = gang
    }
end

local function wrapPlayer(source)
    source = tonumber(source) or source
    local character = exports.himo_core:GetCharacter(source)
    local himoPlayer = exports.himo_core:GetPlayer(source)
    if not character or not himoPlayer then return nil end

    local wrapper = { PlayerData = buildPlayerData(source, character), Functions = {} }
    local function refresh()
        local latest = exports.himo_core:GetCharacter(source)
        if latest then wrapper.PlayerData = buildPlayerData(source, latest) end
    end

    wrapper.Functions.GetMoney = function(accountType) return himoPlayer.Functions.GetMoney(accountType) end
    wrapper.Functions.AddMoney = function(accountType, amount, reason)
        local success = himoPlayer.Functions.AddMoney(accountType, tonumber(amount) or 0, reason or 'qb-bridge')
        refresh() return success == true
    end
    wrapper.Functions.RemoveMoney = function(accountType, amount, reason)
        local success = himoPlayer.Functions.RemoveMoney(accountType, tonumber(amount) or 0, reason or 'qb-bridge')
        refresh() return success == true
    end
    wrapper.Functions.GetIdentifier = function() return himoPlayer.Functions.GetIdentifier() end
    wrapper.Functions.GetMetaData = function(key) return himoPlayer.Functions.GetMetadata(key) end
    wrapper.Functions.SetMetaData = function(key, value)
        local success = himoPlayer.Functions.SetMetadata(key, value) refresh() return success == true
    end
    wrapper.Functions.SetJob = function(jobName, grade)
        local success = himoPlayer.Functions.SetJob(jobName, tonumber(grade) or 0) refresh() return success == true
    end
    wrapper.Functions.SetJobDuty = function(onDuty)
        local success = himoPlayer.Functions.SetDuty(onDuty == true) refresh() return success == true
    end
    wrapper.Functions.SetGang = function(groupName, grade)
        local success = himoPlayer.Functions.SetGroup(groupName, tonumber(grade) or 0) refresh() return success == true
    end
    wrapper.Functions.Save = function() return himoPlayer.Functions.Save() end
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
QBCore.Functions.GetPlayers = function()
    local players = {}
    for _, source in ipairs(GetPlayers()) do players[#players + 1] = tonumber(source) end
    return players
end
QBCore.Functions.GetPlayerByCitizenId = function(citizenId)
    citizenId = tostring(citizenId or '')
    for _, source in ipairs(GetPlayers()) do
        local numericSource = tonumber(source)
        local character = exports.himo_core:GetCharacter(numericSource)
        if character and character.citizen_id == citizenId then return wrapPlayer(numericSource) end
    end
end
QBCore.Functions.GetIdentifier = function(source)
    local player = wrapPlayer(source)
    return player and player.PlayerData.citizenid or nil
end
QBCore.Functions.HasPermission = function(source, permission)
    permission = tostring(permission or ''):lower()
    if permission == 'god' then permission = 'admin' end
    return exports.himo_core:HasPermission(source, permission)
end
QBCore.Functions.CreateCallback = function(name, cb)
    if type(name) == 'string' and type(cb) == 'function' then QBCore.ServerCallbacks[name] = cb end
end

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, ...)
    local src = source
    local callback = QBCore.ServerCallbacks[name]
    if not callback then return end
    callback(src, function(...) TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...) end, ...)
end)

RegisterNetEvent('QBCore:ToggleDuty', function()
    local src = source
    local player = exports.himo_core:GetPlayer(src)
    if not player then return end
    local job = player.Functions.GetPrimaryJob()
    if not job then return end
    local current = isTrue(job.on_duty)
    local ok = player.Functions.SetDuty(not current)
    if ok then
        TriggerClientEvent('QBCore:Client:SetDuty', src, not current)
    end
end)

exports('GetCoreObject', function() return QBCore end)

AddEventHandler('himo_core:server:playerLoaded', function(source) TriggerEvent('QBCore:Server:OnPlayerLoaded', source) end)
AddEventHandler('himo_core:server:characterUnloaded', function(source) TriggerEvent('QBCore:Server:OnPlayerUnload', source) end)
