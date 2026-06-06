local BattleStyle = require("src.battle.battle_style")
local borderColors = require("data.bordercolors")

local MethodColors = {}

local function hexToColor(hex)
    hex = tostring(hex or ""):gsub("#", "")

    if #hex ~= 6 then
        return nil
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    if not r or not g or not b then
        return nil
    end

    return { r / 255, g / 255, b / 255, 1 }
end

local function getMethodColorMap()
    local map = {}

    for _, definition in ipairs(borderColors) do
        for _, methodColor in ipairs(definition.methodcolors or {}) do
            if methodColor.type and methodColor.color then
                map[string.lower(methodColor.type)] = hexToColor(methodColor.color)
            end
        end
    end

    return map
end

local methodColorMap = getMethodColorMap()

function MethodColors.getPrimaryMethodName(card)
    local method = card and card.method

    if type(method) == "string" then
        return string.lower(method)
    end

    if type(method) == "table" then
        for key, value in pairs(method) do
            if type(value) == "table" then
                local name = value.type or value.name or value.id or value.method

                if name then
                    return string.lower(name)
                end
            elseif type(value) == "string" then
                return string.lower(value)
            elseif type(key) == "string" then
                return string.lower(key)
            end
        end
    end

    return nil
end

function MethodColors.getColorByName(methodName, fallback)
    methodName = methodName and string.lower(tostring(methodName)) or nil

    return methodName and methodColorMap[methodName] or fallback or BattleStyle.tag.colors.active
end

function MethodColors.getCardColor(card, fallback)
    local methodName = MethodColors.getPrimaryMethodName(card)

    return MethodColors.getColorByName(methodName, fallback)
end

return MethodColors
