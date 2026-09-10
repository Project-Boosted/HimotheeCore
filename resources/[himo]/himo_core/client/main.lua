local currentCharacter = nil
local metadata = {}
local jobs = {}
local primaryJob = nil

local function updateCachedBalance(accountType, balance)
    if not currentCharacter then return end
    currentCharacter.balances = currentCharacter.balances or {}

    for _, entry in ipairs(currentCharacter.balances) do
        if entry.account_type == accountType then
            entry.balance = balance
            return
        end
    end

    currentCharacter.balances[#currentCharacter.balances + 1] = {
        account_type = accountType,
        balance = balance
    }
end

RegisterNetEvent('himo_core:client:characterLoaded', function(character)
    currentCharacter = character
    metadata = type(character.metadata) == 'table' and character.metadata or {}
    jobs = type(character.jobs) == 'table' and character.jobs or {}
    LocalPlayer.state:set('himoCharacterLoaded', true, false)

    if HimoConfig.Debug then
        print(('[HimotheeCore] Character loaded: %s %s (%s)'):format(
            character.first_name,
            character.last_name,
            character.citizen_id
        ))
    end
end)

RegisterNetEvent('himo_core:client:characterUnloaded', function()
    currentCharacter = nil
    metadata = {}
    jobs = {}
    primaryJob = nil
    LocalPlayer.state:set('himoCharacterLoaded', false, false)
end)

RegisterNetEvent('himo_core:client:moneyChanged', function(accountType, balance, transactionType, amount, reason)
    updateCachedBalance(accountType, balance)
    TriggerEvent('himo_core:client:onMoneyChanged', accountType, balance, transactionType, amount, reason)
end)

RegisterNetEvent('himo_core:client:metadataSnapshot', function(snapshot)
    metadata = type(snapshot) == 'table' and snapshot or {}
    if currentCharacter then currentCharacter.metadata = metadata end
    TriggerEvent('himo_core:client:onMetadataSnapshot', metadata)
end)

RegisterNetEvent('himo_core:client:metadataChanged', function(key, value)
    metadata[key] = value
    if currentCharacter then
        currentCharacter.metadata = currentCharacter.metadata or {}
        currentCharacter.metadata[key] = value
    end
    TriggerEvent('himo_core:client:onMetadataChanged', key, value)
end)

RegisterNetEvent('himo_core:client:jobsChanged', function(newJobs, newPrimary)
    jobs = type(newJobs) == 'table' and newJobs or {}
    primaryJob = newPrimary
    if currentCharacter then currentCharacter.jobs = jobs end
    TriggerEvent('himo_core:client:onJobsChanged', jobs, primaryJob)
end)

exports('GetCharacter', function()
    return currentCharacter
end)

exports('GetCharacterId', function()
    return currentCharacter and currentCharacter.id or nil
end)

exports('IsCharacterLoaded', function()
    return currentCharacter ~= nil
end)

exports('GetMetadata', function(key, default)
    if key == nil then return metadata end
    local value = metadata[key]
    if value == nil then return default end
    return value
end)

exports('GetJobs', function()
    return jobs
end)

exports('GetPrimaryJob', function()
    return primaryJob
end)
