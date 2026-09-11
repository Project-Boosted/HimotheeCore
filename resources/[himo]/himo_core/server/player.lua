HimoPlayerObjects = HimoPlayerObjects or {}

local immutablePlayerFields = {
    id = true,
    account_id = true,
    citizen_id = true,
    metadata = true,
    balances = true,
    jobs = true,
    groups = true
}

local function updateCachedBalance(character, accountType, balance)
    character.balances = character.balances or {}
    for _, entry in ipairs(character.balances) do
        if entry.account_type == accountType then entry.balance = balance return end
    end
    character.balances[#character.balances + 1] = { account_type = accountType, balance = balance }
end

local function notifyMoney(source, accountType, balance, transactionType, amount, reason)
    TriggerClientEvent('himo_core:client:moneyChanged', source, accountType, balance, transactionType, amount, reason)
    TriggerEvent('himo_core:server:moneyChanged', source, accountType, balance, transactionType, amount, reason)
end

local function buildPlayerObject(source, character)
    local player = { source = source, PlayerData = character, Functions = {} }

    function player.Functions.GetData() return HimoPlayers[source] end
    function player.Functions.GetIdentifier()
        local data = HimoPlayers[source]
        return data and data.citizen_id or nil
    end
    function player.Functions.GetCharacterId()
        local data = HimoPlayers[source]
        return data and data.id or nil
    end
    function player.Functions.IsLoaded() return HimoReadyPlayers and HimoReadyPlayers[source] == true end

    function player.Functions.GetMoney(accountType)
        local data = HimoPlayers[source]
        return data and HimoMoney.getBalance(data.id, accountType) or nil
    end

    function player.Functions.AddMoney(accountType, amount, reason, reference)
        local data = HimoPlayers[source]
        if not data then return false end
        amount = math.floor(tonumber(amount) or 0)
        local success = HimoMoney.add(data.id, accountType, amount, reason, reference)
        if not success then return false end
        local balance = HimoMoney.getBalance(data.id, accountType)
        updateCachedBalance(data, accountType, balance)
        notifyMoney(source, accountType, balance, 'credit', amount, reason)
        return true, balance
    end

    function player.Functions.RemoveMoney(accountType, amount, reason, reference)
        local data = HimoPlayers[source]
        if not data then return false end
        amount = math.floor(tonumber(amount) or 0)
        local success = HimoMoney.remove(data.id, accountType, amount, reason, reference)
        if not success then return false end
        local balance = HimoMoney.getBalance(data.id, accountType)
        updateCachedBalance(data, accountType, balance)
        notifyMoney(source, accountType, balance, 'debit', amount, reason)
        return true, balance
    end

    function player.Functions.SetMoney(accountType, amount, reason, reference)
        local data = HimoPlayers[source]
        if not data then return false end
        amount = math.floor(tonumber(amount) or -1)
        if amount < 0 then return false end

        local previous = HimoMoney.getBalance(data.id, accountType)
        if previous == nil then return false end
        local success = HimoMoney.set(data.id, accountType, amount, reason, reference)
        if not success then return false end

        updateCachedBalance(data, accountType, amount)
        notifyMoney(source, accountType, amount, 'set', amount - previous, reason)
        return true, amount
    end

    -- Compatibility-only volatile PlayerData fields (for example ox_inventory's
    -- `items`). Authoritative identity/jobs/groups/money/metadata cannot be
    -- overwritten through this generic setter.
    function player.Functions.SetPlayerData(key, value)
        local data = HimoPlayers[source]
        key = tostring(key or '')
        if not data or key == '' or immutablePlayerFields[key] then return false end
        data[key] = value
        TriggerClientEvent('himo_core:client:playerDataFieldChanged', source, key, value)
        TriggerEvent('himo_core:server:playerDataFieldChanged', source, key, value)
        return true
    end

    function player.Functions.GetMetadata(key, default) return HimoMetadata.get(source, key, default) end
    function player.Functions.SetMetadata(key, value) return HimoMetadata.set(source, key, value) end
    function player.Functions.AddMetadata(key, amount, minimum, maximum)
        return HimoMetadata.add(source, key, amount, minimum, maximum)
    end

    function player.Functions.GetJobs() return HimoJobs.get(source) end
    function player.Functions.GetPrimaryJob() return HimoJobs.getPrimary(source) end
    function player.Functions.SetJob(jobName, grade) return HimoJobs.add(source, jobName, grade or 0, true) end
    function player.Functions.AddJob(jobName, grade, makePrimary)
        return HimoJobs.add(source, jobName, grade or 0, makePrimary == true)
    end
    function player.Functions.RemoveJob(jobName) return HimoJobs.remove(source, jobName) end
    function player.Functions.SetPrimaryJob(jobName) return HimoJobs.setPrimary(source, jobName) end
    function player.Functions.SetJobGrade(jobName, grade) return HimoJobs.setGrade(source, jobName, grade) end
    function player.Functions.SetDuty(onDuty, jobName) return HimoJobs.setDuty(source, jobName, onDuty == true) end

    function player.Functions.GetGroups() return HimoGroups.get(source) end
    function player.Functions.GetPrimaryGroup(groupType) return HimoGroups.getPrimary(source, groupType) end
    function player.Functions.SetGroup(groupName, grade) return HimoGroups.add(source, groupName, grade or 0, true) end
    function player.Functions.AddGroup(groupName, grade, makePrimary)
        return HimoGroups.add(source, groupName, grade or 0, makePrimary == true)
    end
    function player.Functions.RemoveGroup(groupName) return HimoGroups.remove(source, groupName) end
    function player.Functions.SetPrimaryGroup(groupName) return HimoGroups.setPrimary(source, groupName) end
    function player.Functions.SetGroupGrade(groupName, grade) return HimoGroups.setGrade(source, groupName, grade) end

    function player.Functions.SavePosition(position) return HimoCharacters.savePosition(source, position) end
    function player.Functions.Save()
        if type(HimoSavePlayer) == 'function' then return HimoSavePlayer(source) end
        return false
    end

    return player
end

AddEventHandler('himo_core:server:characterLoaded', function(source, character)
    HimoPlayerObjects[source] = buildPlayerObject(source, character)
end)
AddEventHandler('himo_core:server:characterUnloaded', function(source) HimoPlayerObjects[source] = nil end)
AddEventHandler('playerDropped', function() HimoPlayerObjects[source] = nil end)

exports('GetPlayer', function(source)
    return HimoPlayerObjects[tonumber(source) or source]
end)
