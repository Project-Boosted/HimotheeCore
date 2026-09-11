-- HimotheeCore Stage 1E - Qbox exports required by current Project Sloth MDT.
-- These remain thin compatibility surfaces over the authoritative HimotheeCore
-- / QB bridge rather than creating a second framework state.

local function qb()
    return exports['qb-core']:GetCoreObject()
end

local function decode(value)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return {} end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or {}
end

exports('GetCoreObject', function()
    return qb()
end)

exports('GetOfflinePlayer', function(citizenId)
    return exports.himo_qb_bridge:GetOfflinePlayerByCitizenId(citizenId)
end)

exports('GetGroupMembers', function(groupName, groupType)
    groupName = tostring(groupName or '')
    groupType = tostring(groupType or 'job'):lower()
    if groupName == '' then return {} end

    local members = {}
    local column = groupType == 'gang' and 'gang' or 'job'
    local rows = MySQL.query.await(('SELECT citizenid, `%s` AS group_data FROM players'):format(column)) or {}

    for _, row in ipairs(rows) do
        local data = decode(row.group_data)
        if tostring(data.name or '') == groupName then
            members[#members + 1] = {
                citizenid = row.citizenid,
                grade = tonumber(data.grade and data.grade.level) or 0,
                isboss = data.isboss == true,
            }
        end
    end

    return members
end)
