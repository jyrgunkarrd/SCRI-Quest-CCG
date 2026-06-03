local cards = require("data.cards.index")
local Animation = require("src.ui.animation")
local BattleStyle = require("src.battle.battle_style")

local BattleState = {}
BattleState.__index = BattleState

local validPlayZoneIds = {
    left_1 = true,
    left_2 = true,
    left_3 = true,
    left_4 = true,
    right_1 = true,
    right_2 = true,
    right_3 = true,
    right_4 = true,
}

local mockTags = {
    {
        id = "b6",
        name = "B6",
        portrait = "B6",
    },
    {
        id = "mam",
        name = "MAM",
        portrait = "mam",
    },
    {
        id = "bmnch",
        name = "BMNCH",
        portrait = "BMNCH",
    },
}

local function getAgentCards(cardPool)
    local agents = {}

    for _, card in ipairs(cardPool) do
        if card.type == "Agent" then
            agents[#agents + 1] = card
        end
    end

    return agents
end

local function getAgentTags(agentCards)
    local tags = {}

    for _, card in ipairs(agentCards) do
        tags[#tags + 1] = {
            id = string.lower(card.id),
            name = card.name,
            portrait = card.id,
            card = card,
        }
    end

    return tags
end

local function newPlayZone()
    return {
        activeTab = 1,
        cards = {},
    }
end

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
    self.cardPool = options.cardPool or cards
    self.agentCards = options.agentCards or getAgentCards(self.cardPool)
    self.hand = {}
    self.handScrollX = 0
    self.hoveredHandIndex = nil
    self.hoverPreviewCard = nil
    self.hoverPreviewKey = nil
    self.hoverPreviewSide = nil
    self.hoverPreviewAnimation = nil
    self.previousHoverPreviewCard = nil
    self.hoverPreviewTransition = nil
    self.tags = options.tags or getAgentTags(self.agentCards)

    if #self.tags == 0 then
        self.tags = mockTags
    end

    self.activeTagIndex = options.activeTagIndex or 1
    self.tagSwapAnimation = nil
    self.playZones = {
        left_1 = newPlayZone(),
        left_2 = newPlayZone(),
        left_3 = newPlayZone(),
        left_4 = newPlayZone(),
        right_1 = newPlayZone(),
        right_2 = newPlayZone(),
        right_3 = newPlayZone(),
        right_4 = newPlayZone(),
    }
    self.draggedHandCard = nil

    local handSize = options.handSize or 10

    for i = 1, handSize do
        local source = self.cardPool[love.math.random(#self.cardPool)]
        self.hand[i] = copyCard(source, "hand-" .. i)
    end

    return self
end

function BattleState:update(dt)
    self.hoverPreviewAnimation = Animation.update(self.hoverPreviewAnimation, dt)

    if not self.hoverPreviewAnimation then
        self.previousHoverPreviewCard = nil
        self.hoverPreviewTransition = nil
    end

    self.tagSwapAnimation = Animation.update(self.tagSwapAnimation, dt)
end

function BattleState:rotateTags(direction)
    local count = #self.tags

    if count == 0 then
        return
    end

    local previousIndex = self.activeTagIndex

    self.activeTagIndex = ((self.activeTagIndex - 1 + direction) % count) + 1
    self.tagSwapAnimation = Animation.new(BattleStyle.tag.swapDuration, {
        fromIndex = previousIndex,
        toIndex = self.activeTagIndex,
        direction = direction,
    })
end

function BattleState:getActiveAgentCard()
    local activeTag = self.tags[self.activeTagIndex]

    if not activeTag then
        return nil
    end

    return activeTag.card
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

function BattleState:startDraggingHandCard(index, x, y)
    local card = self.hand[index]

    if not card or card.type ~= "Troop" then
        return false
    end

    self.draggedHandCard = {
        index = index,
        card = card,
        x = x,
        y = y,
    }
    self:setHoveredHandIndex(nil)

    return true
end

function BattleState:updateDraggedHandCard(x, y)
    if not self.draggedHandCard then
        return
    end

    self.draggedHandCard.x = x
    self.draggedHandCard.y = y
end

function BattleState:getDraggedHandCard()
    return self.draggedHandCard
end

function BattleState:cancelDraggingHandCard()
    self.draggedHandCard = nil
end

function BattleState:dropDraggedHandCard(zoneId)
    local drag = self.draggedHandCard

    if not drag or not validPlayZoneIds[zoneId] then
        self.draggedHandCard = nil
        return false
    end

    local card = self.hand[drag.index]

    if card ~= drag.card then
        for i, handCard in ipairs(self.hand) do
            if handCard == drag.card then
                drag.index = i
                card = handCard
                break
            end
        end
    end

    if card ~= drag.card or card.type ~= "Troop" then
        self.draggedHandCard = nil
        return false
    end

    local zone = self.playZones[zoneId]
    local activeTab = zone.activeTab or 1

    if zone.cards[activeTab] then
        self.draggedHandCard = nil
        return false
    end

    zone.cards[activeTab] = card
    table.remove(self.hand, drag.index)

    self.draggedHandCard = nil
    return true
end

function BattleState:setPlayZoneTab(zoneId, tabIndex)
    local zone = self.playZones[zoneId]

    if not zone or tabIndex < 1 or tabIndex > BattleStyle.playZones.tabCount then
        return false
    end

    zone.activeTab = tabIndex
    return true
end

function BattleState:getPlayZoneCard(zoneId)
    local zone = self.playZones[zoneId]

    if not zone then
        return nil
    end

    return zone.cards[zone.activeTab or 1]
end

function BattleState:setHoveredHandIndex(index)
    self.hoveredHandIndex = index
    self:setHoverPreview(index and self.hand[index] or nil, index and ("hand:" .. index) or nil, nil)
end

function BattleState:setHoverPreview(card, key, side)
    if self.hoverPreviewKey == key then
        self.hoverPreviewSide = side
        return false
    end

    if card then
        self.previousHoverPreviewCard = self.hoverPreviewCard
        self.hoverPreviewTransition = self.previousHoverPreviewCard and "replace" or "open"
        self.hoverPreviewAnimation = Animation.new(BattleStyle.hand.previewAnimDuration)
    else
        self.hoverPreviewAnimation = nil
        self.previousHoverPreviewCard = nil
        self.hoverPreviewTransition = nil
    end

    self.hoverPreviewCard = card
    self.hoverPreviewKey = key
    self.hoverPreviewSide = side

    if not key or not key:match("^hand:") then
        self.hoveredHandIndex = nil
    end

    return card ~= nil
end

function BattleState:getPreviousHoverPreviewCard()
    return self.previousHoverPreviewCard
end

function BattleState:getHoveredHandCard()
    return self.hoverPreviewCard
end

return BattleState
