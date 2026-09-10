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
        return character.citizen_id
    end

    function player.Functions.GetMoney(accountType)
        return HimoMoney.getBalance(character.id, accountType)
    end

    function player.Functions.AddMoney(accountType, amount, reason, reference)
        local success = HimoMoney.add(character.id, accountType, amount, reason, reference)
        if not success then return false end

        local balance = HimoMoney.getBalance(character.id, accountType)
        updateCachedBalance(character, accountType, balance)
        TriggerClientEvent('himo_core:client:moneyChanged', source, accountType, balance, 'credit', amount, reason)
        return true, balance
    end

    function player.Functions.RemoveMoney(accountType, amount, reason, reference)
        local success = HimoMoney.remove(character.id, accountType, amount, reason, reference)
        if not success then return false end

        local balance = HimoMoney.getBalance(character.id, accountType)
        updateCachedBalance(character, accountType, balance)
        TriggerClientEvent('himo_core:client:moneyChanged', source, accountType, balance, 'debit', amount, reason)
        return true, balance
    end

    function player.Functions.SavePosition(position)
        return HimoCharacters.savePosition(source, position)
    end

    function player.Functions.GetPrimaryJob()
        for _, job in ipairs(character.jobs or {}) do
            if tonumber(job.is_primary) == 1 then
                return job
            end
        end
        return nil
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
