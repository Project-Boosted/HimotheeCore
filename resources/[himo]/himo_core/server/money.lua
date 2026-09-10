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

function HimoMoney.add(characterId, accountType, amount, reason, reference)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not validAccountTypes[accountType] then return false end

    local success = MySQL.startTransaction(function(query)
        local row = query([[
            SELECT `balance`
            FROM `himo_account_balances`
            WHERE `character_id` = ? AND `account_type` = ?
            FOR UPDATE
        ]], { characterId, accountType })

        if not row or not row[1] then return false end
        local balanceAfter = tonumber(row[1].balance) + amount

        local updated = query([[
            UPDATE `himo_account_balances`
            SET `balance` = ?
            WHERE `character_id` = ? AND `account_type` = ?
        ]], { balanceAfter, characterId, accountType })
        if not updated or tonumber(updated.affectedRows) ~= 1 then return false end

        local logged = query([[
            INSERT INTO `himo_transactions`
                (`character_id`, `account_type`, `amount`, `balance_after`, `transaction_type`, `reference`, `description`)
            VALUES (?, ?, ?, ?, 'credit', ?, ?)
        ]], { characterId, accountType, amount, balanceAfter, reference, reason })

        return logged ~= nil
    end)

    return success == true
end

function HimoMoney.remove(characterId, accountType, amount, reason, reference)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not validAccountTypes[accountType] then return false end

    local success = MySQL.startTransaction(function(query)
        local row = query([[
            SELECT `balance`
            FROM `himo_account_balances`
            WHERE `character_id` = ? AND `account_type` = ?
            FOR UPDATE
        ]], { characterId, accountType })

        if not row or not row[1] then return false end
        local current = tonumber(row[1].balance) or 0
        if current < amount then return false end

        local balanceAfter = current - amount
        local updated = query([[
            UPDATE `himo_account_balances`
            SET `balance` = ?
            WHERE `character_id` = ? AND `account_type` = ?
        ]], { balanceAfter, characterId, accountType })
        if not updated or tonumber(updated.affectedRows) ~= 1 then return false end

        local logged = query([[
            INSERT INTO `himo_transactions`
                (`character_id`, `account_type`, `amount`, `balance_after`, `transaction_type`, `reference`, `description`)
            VALUES (?, ?, ?, ?, 'debit', ?, ?)
        ]], { characterId, accountType, -amount, balanceAfter, reference, reason })

        return logged ~= nil
    end)

    return success == true
end
