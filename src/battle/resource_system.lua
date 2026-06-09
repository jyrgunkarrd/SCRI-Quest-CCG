local BattleStyle = require("src.battle.battle_style")
local Pixel = require("src.pixel")

local ResourceSystem = {}
ResourceSystem.__index = ResourceSystem

local METHOD_NAMES = {
    "beast",
    "blade",
    "crusade",
    "gate",
    "inferno",
    "nightmare",
    "rampage",
    "shadow",
    "stitch",
    "trigger",
}

local function normalizedName(name)
    return name and string.lower(tostring(name)) or nil
end

local function addMethodEntry(entries, name, count)
    name = normalizedName(name)
    count = count or 1

    if name and count > 0 then
        entries[#entries + 1] = {
            name = name,
            count = count,
        }
    end
end

function ResourceSystem.getMethodEntries(card)
    local entries = {}
    local method = card and card.method

    if type(method) == "string" then
        addMethodEntry(entries, method, card.methodValue or card.methodCount or 1)
    elseif type(method) == "table" then
        for key, value in pairs(method) do
            if type(key) == "string" and type(value) == "number" then
                addMethodEntry(entries, key, value)
            elseif type(value) == "string" then
                addMethodEntry(entries, value, 1)
            elseif type(value) == "table" then
                addMethodEntry(entries, value.name or value.id or value.method or value.type, value.value or value.count or 1)
            end
        end
    end

    return entries
end

function ResourceSystem.getMethodPipCount(card)
    local total = 0

    for _, entry in ipairs(ResourceSystem.getMethodEntries(card)) do
        total = total + entry.count
    end

    return total
end

function ResourceSystem.getCardCost(card)
    return math.max(0, tonumber(card and card.cost) or 0)
end

function ResourceSystem.hasWildMethod(card)
    for _, entry in ipairs(ResourceSystem.getMethodEntries(card)) do
        if entry.name == "wild" then
            return true
        end
    end

    return false
end

local function getSelectionKey(card)
    return card and (card.instanceId or tostring(card)) or nil
end

function ResourceSystem.new()
    return setmetatable({
        selectedCards = {},
        pips = 0,
        highlightedMethods = {},
        conversionEffects = {},
    }, ResourceSystem)
end

function ResourceSystem:update(dt)
    for index = #self.conversionEffects, 1, -1 do
        local effect = self.conversionEffects[index]

        effect.elapsed = effect.elapsed + dt

        if effect.elapsed >= effect.duration then
            table.remove(self.conversionEffects, index)
        end
    end
end

function ResourceSystem:showDiscardButton(card)
    local key = getSelectionKey(card)

    if not key then
        return false
    end

    self.selectedCards[key] = card
    return true
end

function ResourceSystem:clearSelections()
    self.selectedCards = {}
end

function ResourceSystem:reset()
    self.selectedCards = {}
    self.pips = 0
    self.highlightedMethods = {}
    self.conversionEffects = {}
end

function ResourceSystem:isCardSelected(card)
    local key = getSelectionKey(card)

    return key and self.selectedCards[key] ~= nil or false
end

function ResourceSystem:hasSelections()
    return next(self.selectedCards) ~= nil
end

function ResourceSystem:getButtonRect(layout)
    local style = BattleStyle.resourceDiscardButton
    local size = style.size

    return {
        x = Pixel.snap(layout.x + layout.width / 2 - size / 2),
        y = Pixel.snap(layout.y + style.yOffset),
        width = size,
        height = size,
    }
end

function ResourceSystem:hitTestButtons(layoutCards, x, y)
    for i = #layoutCards, 1, -1 do
        local layout = layoutCards[i]

        if self:isCardSelected(layout.card) then
            local rect = self:getButtonRect(layout)

            if x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height then
                return layout.index, layout.card, rect
            end
        end
    end

    return nil, nil, nil
end

function ResourceSystem:addCardResources(card)
    self.pips = self.pips + ResourceSystem.getMethodPipCount(card)

    if ResourceSystem.hasWildMethod(card) then
        for _, methodName in ipairs(METHOD_NAMES) do
            self.highlightedMethods[methodName] = true
        end

        return
    end

    for _, entry in ipairs(ResourceSystem.getMethodEntries(card)) do
        self.highlightedMethods[entry.name] = true
    end
end

function ResourceSystem:hasActiveCardMethod(card)
    for _, entry in ipairs(ResourceSystem.getMethodEntries(card)) do
        if self:isMethodHighlighted(entry.name) then
            return true
        end
    end

    return false
end

function ResourceSystem:canPayCard(card)
    if not card then
        return false
    end

    if self.pips < ResourceSystem.getCardCost(card) then
        return false
    end

    if ResourceSystem.hasWildMethod(card) then
        return true
    end

    return self:hasActiveCardMethod(card)
end

function ResourceSystem:deactivateCardMethods(card)
    if ResourceSystem.hasWildMethod(card) then
        return
    end

    for _, entry in ipairs(ResourceSystem.getMethodEntries(card)) do
        self.highlightedMethods[entry.name] = nil
    end
end

function ResourceSystem:payCard(card)
    if not self:canPayCard(card) then
        return false
    end

    self.pips = self.pips - ResourceSystem.getCardCost(card)
    self:deactivateCardMethods(card)
    return true
end

function ResourceSystem:startConversionEffect(card, options)
    options = options or {}

    if not options.fromX or not options.fromY or not options.toX or not options.toY then
        return
    end

    local pipCount = ResourceSystem.getMethodPipCount(card)

    if pipCount <= 0 then
        return
    end

    local style = BattleStyle.resourceConversion

    self.conversionEffects[#self.conversionEffects + 1] = {
        elapsed = 0,
        duration = math.max(style.pulseDuration, style.pipDuration + math.max(0, pipCount - 1) * style.pipStagger),
        pulseDuration = style.pulseDuration,
        pulseScale = style.pulseScale,
        pipDuration = style.pipDuration,
        pipStagger = style.pipStagger,
        pipArcHeight = style.pipArcHeight,
        fromX = options.fromX,
        fromY = options.fromY,
        toX = options.toX,
        toY = options.toY,
        pipCount = pipCount,
        methodEntries = ResourceSystem.getMethodEntries(card),
    }
end

function ResourceSystem:discardCard(card, options)
    local key = getSelectionKey(card)

    if not key or not self.selectedCards[key] then
        return false
    end

    self:addCardResources(card)
    self:startConversionEffect(card, options)
    self.selectedCards[key] = nil
    return true
end

function ResourceSystem:isMethodHighlighted(methodName)
    return self.highlightedMethods[normalizedName(methodName)] == true
end

return ResourceSystem
