local function vectorTable(value)
    if type(value) == 'vector3' then return { x = value.x, y = value.y, z = value.z } end
    if type(value) ~= 'table' then return nil end
    return { x = tonumber(value.x or value[1]) or 0.0, y = tonumber(value.y or value[2]) or 0.0, z = tonumber(value.z or value[3]) or 0.0 }
end

local function mapProp(prop)
    if type(prop) ~= 'table' or not prop.model then return nil end
    return { model = prop.model, bone = tonumber(prop.bone) or 60309, pos = vectorTable(prop.coords) or vectorTable(prop.pos) or { x = 0.0, y = 0.0, z = 0.0 }, rot = vectorTable(prop.rotation) or vectorTable(prop.rot) or { x = 0.0, y = 0.0, z = 0.0 } }
end

local function mapData(data)
    data = type(data) == 'table' and data or {}
    local controls = type(data.controlDisables) == 'table' and data.controlDisables or {}
    local animation = type(data.animation) == 'table' and data.animation or {}
    local anim
    if animation.task then anim = { scenario = animation.task }
    elseif animation.animDict or animation.dict then anim = { dict = animation.animDict or animation.dict, clip = animation.anim or animation.clip, flag = tonumber(animation.flags or animation.flag) } end
    local props = {}
    local first, second = mapProp(data.prop), mapProp(data.propTwo)
    if first then props[#props + 1] = first end
    if second then props[#props + 1] = second end
    return {
        duration = math.max(1, tonumber(data.duration) or 1000), label = tostring(data.label or ''), useWhileDead = data.useWhileDead == true,
        canCancel = data.canCancel ~= false,
        disable = { move = controls.disableMovement == true, car = controls.disableCarMovement == true, combat = controls.disableCombat == true, mouse = controls.disableMouse == true, sprint = controls.disableMovement == true },
        anim = anim, prop = #props == 0 and nil or (#props == 1 and props[1] or props)
    }
end

local function run(data, finish, onStart, onTick)
    if type(onStart) == 'function' then pcall(onStart) end
    local ticking = true
    if type(onTick) == 'function' then
        CreateThread(function()
            while ticking and lib.progressActive() do pcall(onTick); Wait(100) end
        end)
    end
    local completed = lib.progressBar(mapData(data)) == true
    ticking = false
    if type(finish) == 'function' then finish(not completed) end
    return completed
end

exports('Progress', function(data, finish) return run(data, finish) end)
exports('ProgressWithStartEvent', function(data, start, finish) return run(data, finish, start) end)
exports('ProgressWithTickEvent', function(data, tick, finish) return run(data, finish, nil, tick) end)
exports('ProgressWithStartAndTick', function(data, start, tick, finish) return run(data, finish, start, tick) end)
exports('isDoingSomething', function() return lib.progressActive() == true end)
exports('Health', function() return type(lib.progressActive) == 'function', 'progressbar->ox_lib' end)
