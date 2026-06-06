local cards = require("data.cards.index")
local Animation = require("src.ui.animation")
local BattleStyle = require("src.battle.battle_style")
local PlayLayout = require("src.battle.play_layout")
local ResourceSystem = require("src.battle.resource_system")
local jaclCards = require("data.jacl")
local jaclProto = require("data.jaclproto")
local sigRows = require("data.sigrows")

local BattleState = {}
BattleState.__index = BattleState

local function normalizedValue(value)
    return value and string.lower(tostring(value)) or nil
end

local validPlayZoneIds = {}

for _, zoneId in ipairs(PlayLayout.getOrderedTroopZoneIds()) do
    validPlayZoneIds[zoneId] = true
end

local sigRowById = {}

for _, sigRow in ipairs(sigRows) do
    sigRowById[string.lower(sigRow.id)] = sigRow
end

local jaclById = {}

for _, jaclCard in ipairs(jaclCards) do
    jaclById[normalizedValue(jaclCard.id)] = jaclCard
end

local jaclIdByAgentId = {}

for _, proto in ipairs(jaclProto) do
    local agentId = normalizedValue(proto.agent)
    local jaclId = normalizedValue(proto.jacl or proto.id)

    if agentId and jaclId then
        jaclIdByAgentId[agentId] = jaclId
    end
end

local lowerRowSlotMap = {
    left_4 = { row = "lrow", slot = "slot1" },
    left_3 = { row = "lrow", slot = "slot2" },
    left_2 = { row = "lrow", slot = "slot3" },
    left_1 = { row = "lrow", slot = "slot4" },
    right_1 = { row = "rrow", slot = "slot1" },
    right_2 = { row = "rrow", slot = "slot2" },
    right_3 = { row = "rrow", slot = "slot3" },
    right_4 = { row = "rrow", slot = "slot4" },
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
    self.resources = ResourceSystem.new()
    self.tagActionMode = nil
    self.activeJaclCard = nil
    self.jaclSpawnAnimation = nil
    self.tags = options.tags or getAgentTags(self.agentCards)

    if #self.tags == 0 then
        self.tags = mockTags
    end

    self.activeTagIndex = options.activeTagIndex or 1
    self.tagSwapAnimation = nil
    self.playZones = {}

    for _, zoneId in ipairs(PlayLayout.getOrderedTroopZoneIds()) do
        self.playZones[zoneId] = newPlayZone()
    end

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
    self.resources:update(dt)

    if not self.hoverPreviewAnimation then
        self.previousHoverPreviewCard = nil
        self.hoverPreviewTransition = nil
    end

    self.tagSwapAnimation = Animation.update(self.tagSwapAnimation, dt)
    self.jaclSpawnAnimation = Animation.update(self.jaclSpawnAnimation, dt)
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

function BattleState:setActiveTagIndex(index)
    local count = #self.tags

    if count == 0 or not index or index < 1 or index > count then
        return false
    end

    local previousIndex = self.activeTagIndex

    if previousIndex == index then
        return true
    end

    self.activeTagIndex = index
    self.tagSwapAnimation = Animation.new(BattleStyle.tag.swapDuration, {
        fromIndex = previousIndex,
        toIndex = self.activeTagIndex,
        direction = index > previousIndex and 1 or -1,
    })

    return true
end

function BattleState:showGoSilentPrompt()
    self.tagActionMode = "goSilent"
end

function BattleState:showGoLoudSelection()
    self.tagActionMode = "goLoud"
end

function BattleState:clearTagAction()
    self.tagActionMode = nil
end

function BattleState:getJaclCardForAgent(agentCard)
    local agentId = normalizedValue(agentCard and agentCard.id)
    local jaclId = agentId and jaclIdByAgentId[agentId]

    return jaclId and jaclById[jaclId] or nil
end

function BattleState:goLoud(tagIndex)
    local tag = self.tags[tagIndex]

    if not tag or tagIndex == self.activeTagIndex then
        return false
    end

    local jaclCard = self:getJaclCardForAgent(tag.card)

    if not jaclCard then
        return false
    end

    self.activeJaclCard = jaclCard
    self.jaclSpawnAnimation = Animation.new(BattleStyle.jaclFootprint.spawnDelay + BattleStyle.jaclFootprint.spawnDuration)
    self:setActiveTagIndex(tagIndex)
    self:clearTagAction()

    return true
end

function BattleState:getJaclSpawnProgress()
    if not self.activeJaclCard then
        return 0
    end

    local animation = self.jaclSpawnAnimation

    if not animation then
        return 1
    end

    local style = BattleStyle.jaclFootprint
    local elapsed = math.max(0, animation.elapsed - style.spawnDelay)

    return Animation.easeOutCubic(math.min(1, elapsed / style.spawnDuration))
end

function BattleState:getActiveAgentCard()
    local activeTag = self.tags[self.activeTagIndex]

    if not activeTag then
        return nil
    end

    return activeTag.card
end

function BattleState:getSlotSignatureSourceCard()
    return self.activeJaclCard or self:getActiveAgentCard()
end

function BattleState:getActiveSlotSig()
    local sourceCard = self:getSlotSignatureSourceCard()

    return sourceCard and sourceCard.sig or nil
end

function BattleState:getActiveSigRow()
    local sig = self:getActiveSlotSig()

    if not sig then
        return nil
    end

    return sigRowById[string.lower(sig)]
end

function BattleState:getPlayZoneAcceptedType(zoneId)
    local lowerSlot = lowerRowSlotMap[zoneId]

    if not lowerSlot then
        return "Troop"
    end

    local sigRow = self:getActiveSigRow()
    local row = sigRow and sigRow[lowerSlot.row]

    return row and row[lowerSlot.slot] or "Troop"
end

function BattleState:getPlayZoneAcceptedSig(zoneId)
    if not lowerRowSlotMap[zoneId] then
        return nil
    end

    return self:getActiveSlotSig()
end

function BattleState:isPlayZoneVisible(zoneId)
    return not (self.activeJaclCard and PlayLayout.isInnerPlayerZone(zoneId))
end

function BattleState:canCardPlayInZone(card, zoneId)
    local acceptedType = self:getPlayZoneAcceptedType(zoneId)
    local acceptedSig = self:getPlayZoneAcceptedSig(zoneId)
    local isSlotCompatible = false

    if not card or not self:isPlayZoneVisible(zoneId) then
        return false
    end

    if acceptedSig and normalizedValue(card.sig) == normalizedValue(acceptedSig) then
        isSlotCompatible = true
    elseif normalizedValue(acceptedType) == "wild" then
        isSlotCompatible = true
    elseif acceptedType and card.type == acceptedType then
        isSlotCompatible = true
    end

    if not isSlotCompatible then
        return false
    end

    return self.resources:canPayCard(card)
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

    if not card or card.type == "Agent" then
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

function BattleState:discardHandCard(card, conversionOptions)
    for index, handCard in ipairs(self.hand) do
        if handCard == card then
            if not self.resources:discardCard(card, conversionOptions) then
                return false
            end

            table.remove(self.hand, index)
            self:setHoverPreview(nil, nil, nil)
            return true
        end
    end

    return false
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

    if card ~= drag.card or not self:canCardPlayInZone(card, zoneId) then
        self.draggedHandCard = nil
        return false
    end

    local zone = self.playZones[zoneId]
    local activeTab = zone.activeTab or 1

    if zone.cards[activeTab] then
        self.draggedHandCard = nil
        return false
    end

    if not self.resources:payCard(card) then
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
