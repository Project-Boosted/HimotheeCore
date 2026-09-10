HimoPlayerObjects = HimoPlayerObjects or {}

local function updateCachedBalance(character, accountType, balance)
    character.balances = character.balances or {}

    for _, entry in ipairs(character.balances) do
        if entry.account_type == accountType then
            entry.balance = balance
            return
        end
    end

    character.balances[#character.balances + 1] = {
        account_type = accountType,
        balance = balance
    }
end

local function buildPlayerObject(source, character)
    local player = {
        source = source,
        PlayerData = character,
        Functions = {}
    }

    function player.Functions.GetData()
        return HimoPlayers[source]
    end

    function player.Functions.GetIdentifier()
        local data = HimoPlayers[source]
        return data and data.citizen_id or nil
    end

    function player.Functions.GetCharacterId()
        local data = HimoPlayers[source]
        return data and data.id or nil
    end

    function player.Functions.IsLoaded()
        return HimoReadyPlayers and HimoReadyPlayers[source] == true
    end

    function player.Functions.GetMoney(accountType)
        local data = HimoPlayers[source]
        if not data then return nil end
        return HimoMoney.getBalance(data.id, accountType)
    end

    function player.Functions.AddMoney(accountType, amount, reason, reference)
        local data = HimoPlayers[source]
        if not data then return false end

        local success = HimoMoney.add(data.id, accountType, amount, reason, reference)
        if not success then return false end

        local balance = HimoMoney.getBalance(data.id, accountType)
        updateCachedBalance(data, accountType, balance)
        TriggerClientEvent('himo_core:client:moneyChanged', source, accountType, balance, 'credit', amount, reason)
        TriggerEvent('himo_core:server:moneyChanged', source, accountType, balance, 'credit', amount, reason)
        return true, balance
    end

    function player.Functions.RemoveMoney(accountType, amount, reason, reference)
        local data = HimoPlayers[source]
        if not data then return false end

        local success = HimoMoney.remove(data.id, accountType, amount, reason, reference)
        if not success then return false end

        local balance = HimoMoney.getBalance(data.id, accountType)
        updateCachedBalance(data, accountType, balance)
        TriggerClientEvent('himo_core:client:moneyChanged', source, accountType, balance, 'debit', amount, reason)
        TriggerEvent('himo_core:server:moneyChanged', source, accountType, balance, 'debit', amount, reason)
        return true, balance
    end

    function player.Functions.GetMetadata(key, default)
        return HimoMetadata.get(source, key, default)
    end

    function player.Functions.SetMetadata(key, value)
        return HimoMetadata.set(source, key, value)
    end

    function player.Functions.AddMetadata(key, amount, minimum, maximum)
        return HimoMetadata.add(source, key, amount, minimum, maximum)
    end

    function player.Functions.GetJobs()
        return HimoJobs.get(source)
    end

    function player.Functions.GetPrimaryJob()
        return HimoJobs.getPrimary(source)
    end

    -- QB-style SetJob semantics: assign the requested job and make it primary.
    function player.Functions.SetJob(jobName, grade)
        return HimoJobs.add(source, jobName, grade or 0, true)
    end

    function player.Functions.AddJob(jobName, grade, makePrimary)
        return HimoJobs.add(source, jobName, grade or 0, makePrimary == true)
    end

    function player.Functions.RemoveJob(jobName)
        return HimoJobs.remove(source, jobName)
    end

    function player.Functions.SetPrimaryJob(jobName)
        return HimoJobs.setPrimary(source, jobName)
    end

    function player.Functions.SetJobGrade(jobName, grade)
        return HimoJobs.setGrade(source, jobName, grade)
    end

    function player.Functions.SetDuty(onDuty, jobName)
        return HimoJobs.setDuty(source, jobName, onDuty == true)
    end

    function player.Functions.SavePosition(position)
        return HimoCharacters.savePosition(source, position)
    end

    function player.Functions.Save()
        local savedPosition = false
        if type(HimoSavePlayer) == 'function' then
            savedPosition = HimoSavePlayer(source)
        end
        return savedPosition
    end

    return player
end

AddEventHandler('himo_core:server:characterLoaded', function(source, character)
    HimoPlayerObjects[source] = buildPlayerObject(source, character)
end)

AddEventHandler('himo_core:server:characterUnloaded', function(source)
    HimoPlayerObjects[source] = nil
end)

AddEventHandler('playerDropped', function()
    HimoPlayerObjects[source] = nil
end)

exports('GetPlayer', function(source)
    return HimoPlayerObjects[tonumber(source) or source]
end)
