HimoMoney = HimoMoney or {}

local validAccountTypes = {
    cash = true,
    bank = true
}

function HimoMoney.getBalance(characterId, accountType)
    if not validAccountTypes[accountType] then return nil end
    local balance = MySQL.scalar.await([[
        SELECT `balance` FROM `himo_account_balances`
        WHERE `character_id` = ? AND `account_type` = ?
    ]], { characterId, accountType })
    return tonumber(balance)
end

local function transact(characterId, accountType, amount, transactionType, reason, reference)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not validAccountTypes[accountType] then return false end

    return MySQL.startTransaction(function(query)
        local row = query([[
            SELECT `balance`
            FROM `himo_account_balances`
            WHERE `character_id` = ? AND `account_type` = ?
            FOR UPDATE
        ]], { characterId, accountType })

        if not row or not row[1] then return false end
        local current = tonumber(row[1].balance) or 0
        local balanceAfter

        if transactionType == 'credit' then
            balanceAfter = current + amount
        else
            if current < amount then return false end
            balanceAfter = current - amount
        end

        local updated = query([[
            UPDATE `himo_account_balances`
            SET `balance` = ?
            WHERE `character_id` = ? AND `account_type` = ?
        ]], { balanceAfter, characterId, accountType })
        if not updated or tonumber(updated.affectedRows) ~= 1 then return false end

        local signedAmount = transactionType == 'credit' and amount or -amount
        local logged = query([[
            INSERT INTO `himo_transactions`
                (`character_id`, `account_type`, `amount`, `balance_after`, `transaction_type`, `reference`, `description`)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { characterId, accountType, signedAmount, balanceAfter, transactionType, reference, reason })

        return logged ~= nil
    end) == true
end

function HimoMoney.add(characterId, accountType, amount, reason, reference)
    return transact(characterId, accountType, amount, 'credit', reason, reference)
end

function HimoMoney.remove(characterId, accountType, amount, reason, reference)
    return transact(characterId, accountType, amount, 'debit', reason, reference)
end

function HimoMoney.set(characterId, accountType, amount, reason, reference)
    amount = math.floor(tonumber(amount) or -1)
    if amount < 0 or not validAccountTypes[accountType] then return false end

    local success = MySQL.startTransaction(function(query)
        local row = query([[
            SELECT `balance`
            FROM `himo_account_balances`
            WHERE `character_id` = ? AND `account_type` = ?
            FOR UPDATE
        ]], { characterId, accountType })
        if not row or not row[1] then return false end

        local previous = tonumber(row[1].balance) or 0
        local updated = query([[
            UPDATE `himo_account_balances`
            SET `balance` = ?
            WHERE `character_id` = ? AND `account_type` = ?
        ]], { amount, characterId, accountType })
        if not updated or tonumber(updated.affectedRows) ~= 1 then return false end

        local delta = amount - previous
        if delta ~= 0 then
            local logged = query([[
                INSERT INTO `himo_transactions`
                    (`character_id`, `account_type`, `amount`, `balance_after`, `transaction_type`, `reference`, `description`)
                VALUES (?, ?, ?, ?, 'set', ?, ?)
            ]], { characterId, accountType, delta, amount, reference, reason })
            if not logged then return false end
        end

        return true
    end)

    return success == true
end

exports('GetBalance', HimoMoney.getBalance)
exports('AddMoney', HimoMoney.add)
exports('RemoveMoney', HimoMoney.remove)
exports('SetMoney', HimoMoney.set)
