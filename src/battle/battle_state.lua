local mockCards = require("data.mockcard")

local BattleState = {}
BattleState.__index = BattleState

local function copyCard(card, instanceId)
    local instance = {}

    for key, value in pairs(card) do
        instance[key] = value
    end

    instance.instanceId = instanceId
    return instance
end

function BattleState.new(options)
    options = options or {}

    local self = setmetatable({}, BattleState)
    self.cardPool = options.cardPool or mockCards
    self.hand = {}
    self.handScrollX = 0
    self.hoveredHandIndex = nil

    local handSize = options.handSize or 10

    for i = 1, handSize do
        local source = self.cardPool[love.math.random(#self.cardPool)]
        self.hand[i] = copyCard(source, "hand-" .. i)
    end

    return self
end

function BattleState:getHandOverflow(viewWidth, cardDisplayWidth, spacing)
    local count = #self.hand

    if count == 0 then
        return 0
    end

    local totalWidth = cardDisplayWidth + (count - 1) * spacing
    return math.max(0, totalWidth - viewWidth)
end

function BattleState:clampHandScroll(viewWidth, cardDisplayWidth, spacing)
    local overflow = self:getHandOverflow(viewWidth, cardDisplayWidth, spacing)
    local halfOverflow = overflow / 2

    self.handScrollX = math.max(-halfOverflow, math.min(halfOverflow, self.handScrollX))
end

function BattleState:scrollHand(delta, viewWidth, cardDisplayWidth, spacing)
    self.handScrollX = self.handScrollX + delta
    self:clampHandScroll(viewWidth, cardDisplayWidth, spacing)
end

function BattleState:setHoveredHandIndex(index)
    self.hoveredHandIndex = index
end

function BattleState:getHoveredHandCard()
    if not self.hoveredHandIndex then
        return nil
    end

    return self.hand[self.hoveredHandIndex]
end

return BattleState
