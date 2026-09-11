Locale = Locale or {}
Locale.__index = Locale

local function resolvePath(tbl, key)
    local value = tbl
    for part in tostring(key):gmatch('[^.]+') do
        if type(value) ~= 'table' then return nil end
        value = value[part]
    end
    return value
end

local function substitute(text, values)
    if type(text) ~= 'string' or type(values) ~= 'table' then return text end
    return (text:gsub('%%{([%w_]+)}', function(key)
        local value = values[key]
        return value == nil and ('%%{' .. key .. '}') or tostring(value)
    end))
end

function Locale:new(data)
    data = type(data) == 'table' and data or {}
    return setmetatable({
        phrases = type(data.phrases) == 'table' and data.phrases or {},
        warnOnMissing = data.warnOnMissing == true,
        fallbackLang = data.fallbackLang
    }, self)
end

function Locale:t(key, values)
    local phrase = resolvePath(self.phrases, key)
    if phrase == nil then
        if self.warnOnMissing then
            print(('[qb-core compatibility] missing locale phrase: %s'):format(tostring(key)))
        end
        return tostring(key)
    end
    return substitute(phrase, values)
end

function Locale:exists(key)
    return resolvePath(self.phrases, key) ~= nil
end

function Locale:add(phrases)
    if type(phrases) ~= 'table' then return end
    local function merge(target, source)
        for key, value in pairs(source) do
            if type(value) == 'table' then
                target[key] = type(target[key]) == 'table' and target[key] or {}
                merge(target[key], value)
            else
                target[key] = value
            end
        end
    end
    merge(self.phrases, phrases)
end

function Locale:setFallbackLang(locale)
    self.fallbackLang = locale
end
