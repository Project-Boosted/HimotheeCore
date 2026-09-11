local function mapOptions(options)
    local result = {}
    for _, option in ipairs(type(options) == 'table' and options or {}) do
        result[#result + 1] = {
            value = option.value ~= nil and option.value or option.text,
            label = tostring(option.text or option.label or option.value or 'Option')
        }
    end
    return result
end

local function mapField(input)
    local inputType = tostring(input.type or 'text'):lower()
    local field = {
        label = tostring(input.text or input.label or input.name or 'Input'),
        description = input.description,
        required = input.isRequired == true,
        default = input.default
    }

    if inputType == 'number' then
        field.type = 'number'
        field.min = tonumber(input.min)
        field.max = tonumber(input.max)
    elseif inputType == 'password' then
        field.type = 'input'
        field.password = true
    elseif inputType == 'checkbox' then
        field.type = 'checkbox'
    elseif inputType == 'radio' or inputType == 'select' then
        field.type = 'select'
        field.options = mapOptions(input.options)
        field.clearable = input.isRequired ~= true
    else
        field.type = 'input'
        field.placeholder = input.placeholder
    end

    return field
end

local function showInput(data)
    data = type(data) == 'table' and data or {}
    local inputs = type(data.inputs) == 'table' and data.inputs or {}
    if #inputs == 0 then return nil end

    local fields = {}
    for _, input in ipairs(inputs) do fields[#fields + 1] = mapField(input) end

    local values = lib.inputDialog(tostring(data.header or 'Input'), fields, {
        allowCancel = data.submitText ~= false
    })
    if not values then return nil end

    local result = {}
    for index, input in ipairs(inputs) do
        result[input.name or tostring(index)] = values[index]
    end
    return result
end

exports('ShowInput', showInput)
exports('showInput', showInput)
