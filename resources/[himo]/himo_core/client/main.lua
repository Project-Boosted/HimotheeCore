local currentCharacter = nil

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
    LocalPlayer.state:set('himoCharacterLoaded', false, false)
end)

RegisterNetEvent('himo_core:client:moneyChanged', function(accountType, balance, transactionType, amount, reason)
    updateCachedBalance(accountType, balance)
    TriggerEvent('himo_core:client:onMoneyChanged', accountType, balance, transactionType, amount, reason)
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
