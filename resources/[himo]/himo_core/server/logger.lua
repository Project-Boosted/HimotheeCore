HimoLogger = HimoLogger or {}

local function formatMessage(level, message)
    return ('[%s] [%s] %s'):format(HimoConfig.FrameworkName, level, tostring(message))
end

function HimoLogger.info(message)
    print(formatMessage('INFO', message))
end

function HimoLogger.warn(message)
    print(('^3%s^7'):format(formatMessage('WARN', message)))
end

function HimoLogger.error(message)
    print(('^1%s^7'):format(formatMessage('ERROR', message)))
end

function HimoLogger.debug(message)
    if HimoConfig.Debug then
        print(('^5%s^7'):format(formatMessage('DEBUG', message)))
    end
end
