local cards = require("data.cards.index")
local championCards = require("data.cards.champions")
local landmarkCards = require("data.cards.landmarks")
local objectiveCards = require("data.cards.objectives")
local Animation = require("src.ui.animation")
local BattleAnimations = require("src.battle.battle_animations")
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
local CHAMPION_OBJECTIVE_ZONE_ID = "upper_right_4"
local LANDMARK_ZONE_ID = "upper_left_4"

for _, zoneId in ipairs(PlayLayout.getOrderedTroopZoneIds()) do
    validPlayZoneIds[zoneId] = true
end

local PHASE = {
    start = 1,
    defiance = 2,
    sermon = 3,
    ["end"] = 4,
}

local SERMON_SUB_PHASES = {
    {
        id = "hostileMission",
        label = "Hostile Mission",
    },
    {
        id = "hostileSortie",
        label = "Hostile Sortie",
    },
    {
        id = "hostileOccupation",
        label = "Hostile Occupation",
    },
}

local sigRowById = {}

for _, sigRow in ipairs(sigRows) do
    sigRowById[string.lower(sigRow.id)] = sigRow
end

local jaclById = {}

for _, jaclCard in ipairs(jaclCards) do
    jaclById[normalizedValue(jaclCard.id)] = jaclCard
end

local objectiveById = {}

for _, objectiveCard in ipairs(objectiveCards) do
    objectiveById[normalizedValue(objectiveCard.id)] = objectiveCard
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
        cardsByForce = {},
    }
end

local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, childValue in pairs(value) do
        copy[key] = copyValue(childValue)
    end

    return copy
end

local function copyCard(card, instanceId)
    local instance = copyValue(card)

    instance.instanceId = instanceId
    return instance
end

local function getStatValue(card, statType)
    statType = normalizedValue(statType)

    for _, stat in ipairs(card and card.statblock or {}) do
        if normalizedValue(stat.type) == statType then
            return stat.value or 0
        end
    end

    return 0
end

local function incrementProgressTrack(card, amount)
    local progress = card and card.progress

    if type(progress) ~= "table" then
        return false
    end

    amount = amount or 0

    if progress.track ~= nil then
        progress.track = (progress.track or 0) + amount
        return true
    end

    for _, entry in ipairs(progress) do
        if type(entry) == "table" and entry.track ~= nil then
            entry.track = (entry.track or 0) + amount
            return true
        end
    end

    progress.track = amount
    return true
end

local function incrementControlTrack(card, amount)
    local control = card and card.control

    if type(control) ~= "table" then
        return false
    end

    amount = amount or 0

    if control.track ~= nil then
        control.track = (control.track or 0) + amount
        return true
    end

    for _, entry in ipairs(control) do
        if type(entry) == "table" and entry.track ~= nil then
            entry.track = (entry.track or 0) + amount
            return true
        end
    end

    control.track = amount
    return true
end

local function decrementHealth(card, amount)
    if not card or card.health == nil then
        return false
    end

    card.health = math.max(0, (card.health or 0) - (amount or 0))
    return true
end

local function getChampionObjectiveId(championCard)
    local objective = championCard and championCard.objective

    if type(objective) == "table" then
        return normalizedValue(objective.id or objective.objective or objective.card)
    end

    return normalizedValue(objective)
end

function BattleState.new(options)
    options = options or {}

    local self = setmetatable({}, BattleState)
    self.cardPool = options.cardPool or cards
    self.championCards = options.championCards or championCards
    self.landmarkCards = options.landmarkCards or landmarkCards
    self.activeChampionIndex = options.activeChampionIndex or 1
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
    self.round = options.round or 1
    self.phaseIndex = options.phaseIndex or 1
    self.phaseElapsed = 0
    self.subPhaseIndex = nil
    self.subPhaseElapsed = 0
    self.hostileMissionAnimation = nil
    self.hostileSortieAttackAnimation = nil
    self.progressSfxRequested = false
    self.damageSfxRequested = false
    self.occupySfxRequested = false
    self.tagActionMode = nil
    self.activeJaclCard = nil
    self.jaclAppearedRound = nil
    self.jaclDeployActionVisible = false
    self.jaclSpawnAnimation = nil
    self.jaclDismissAnimation = nil
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

    self:seedChampionObjective()
    self:seedLandmark()

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
    self:updateHostileMissionAnimation(dt)
    self:updateHostileSortieAttackAnimation(dt)
    self:updatePhase(dt)

    if not self.hoverPreviewAnimation then
        self.previousHoverPreviewCard = nil
        self.hoverPreviewTransition = nil
    end

    self.tagSwapAnimation = Animation.update(self.tagSwapAnimation, dt)
    self.jaclSpawnAnimation = Animation.update(self.jaclSpawnAnimation, dt)

    local wasDismissingJacl = self.jaclDismissAnimation ~= nil

    self.jaclDismissAnimation = Animation.update(self.jaclDismissAnimation, dt)

    if wasDismissingJacl and not self.jaclDismissAnimation then
        self.activeJaclCard = nil
        self.jaclAppearedRound = nil
        self.jaclDeployActionVisible = false
    end
end

function BattleState:updateHostileMissionAnimation(dt)
    if not self.hostileMissionAnimation then
        return
    end

    local animation, didComplete = BattleAnimations.updateHostileMission(self.hostileMissionAnimation, dt, function(animation)
        local trackType = animation.trackType or "progress"

        if trackType == "control" then
            incrementControlTrack(animation.targetCard or animation.objectiveCard, animation.value)
            self.occupySfxRequested = true
        else
            incrementProgressTrack(animation.targetCard or animation.objectiveCard, animation.value)
            self.progressSfxRequested = true
        end
    end)

    self.hostileMissionAnimation = animation

    if didComplete then
        self:finishCurrentSubPhase()
    end
end

function BattleState:updateHostileSortieAttackAnimation(dt)
    if not self.hostileSortieAttackAnimation then
        return
    end

    local animation, didComplete = BattleAnimations.updateHostileSortieAttack(self.hostileSortieAttackAnimation, dt, function(animation)
        decrementHealth(animation.agentCard, animation.value)
        self.damageSfxRequested = true
    end)

    self.hostileSortieAttackAnimation = animation

    if didComplete then
        self:finishCurrentSubPhase()
    end
end

function BattleState:consumeProgressSfxRequest()
    if not self.progressSfxRequested then
        return false
    end

    self.progressSfxRequested = false
    return true
end

function BattleState:consumeDamageSfxRequest()
    if not self.damageSfxRequested then
        return false
    end

    self.damageSfxRequested = false
    return true
end

function BattleState:consumeOccupySfxRequest()
    if not self.occupySfxRequested then
        return false
    end

    self.occupySfxRequested = false
    return true
end

function BattleState:updatePhase(dt)
    if self.hostileMissionAnimation or self.hostileSortieAttackAnimation then
        self.phaseElapsed = 0
        return
    end

    if self.phaseIndex == PHASE.defiance then
        self.phaseElapsed = 0
        return
    end

    self.phaseElapsed = self.phaseElapsed + dt

    if self.phaseElapsed >= BattleStyle.phaseTracker.autoAdvanceDelay then
        if self.phaseIndex == PHASE.sermon then
            self:completeCurrentSubPhase()
        else
            self:advancePhase()
        end
    end
end

function BattleState:enterPhase(phaseIndex)
    self.phaseIndex = phaseIndex
    self.phaseElapsed = 0
    self.subPhaseElapsed = 0
    self.hostileMissionAnimation = nil
    self.hostileSortieAttackAnimation = nil

    if phaseIndex == PHASE.sermon then
        self.subPhaseIndex = 1
    else
        self.subPhaseIndex = nil
    end
end

function BattleState:advancePhase()
    if self.phaseIndex == PHASE["end"] then
        self.round = self.round + 1
        self.resources:reset()
        self:enterPhase(PHASE.start)
        return
    end

    self:enterPhase((self.phaseIndex or PHASE.start) + 1)
end

function BattleState:getCurrentSubPhase()
    if self.phaseIndex ~= PHASE.sermon then
        return nil
    end

    return SERMON_SUB_PHASES[self.subPhaseIndex or 1]
end

function BattleState:getCurrentSubPhaseLabel()
    local subPhase = self:getCurrentSubPhase()

    return subPhase and subPhase.label or nil
end

function BattleState:startObjectiveProgressAnimation()
    local championCard = self:getActiveChampionCard()
    local objectiveCard = self:getPlayZoneCard(CHAMPION_OBJECTIVE_ZONE_ID, 1)
    local opsValue = getStatValue(championCard, "OPS")

    if not objectiveCard then
        return false
    end

    self.hostileMissionAnimation = BattleAnimations.newHostileMission(objectiveCard, opsValue, CHAMPION_OBJECTIVE_ZONE_ID, "progress")
    self.phaseElapsed = 0

    return true
end

function BattleState:startLandmarkControlAnimation()
    local championCard = self:getActiveChampionCard()
    local landmarkCard = self:getPlayZoneCard(LANDMARK_ZONE_ID, 1)
    local secValue = getStatValue(championCard, "SEC")

    if not landmarkCard then
        return false
    end

    self.hostileMissionAnimation = BattleAnimations.newHostileMission(landmarkCard, secValue, LANDMARK_ZONE_ID, "control")
    self.phaseElapsed = 0

    return true
end

function BattleState:runHostileMissionSubPhase()
    return self:startObjectiveProgressAnimation()
end

function BattleState:runHostileSortieSubPhase()
    if self.activeJaclCard then
        return self:startObjectiveProgressAnimation()
    end

    local championCard = self:getActiveChampionCard()
    local activeAgentCard = self:getActiveAgentCard()
    local atkValue = getStatValue(championCard, "ATK")

    if not activeAgentCard then
        return false
    end

    self.hostileSortieAttackAnimation = BattleAnimations.newHostileSortieAttack(activeAgentCard, atkValue)
    self.phaseElapsed = 0

    return true
end

function BattleState:runHostileOccupationSubPhase()
    return self:startLandmarkControlAnimation()
end

function BattleState:finishCurrentSubPhase()
    if (self.subPhaseIndex or 1) >= #SERMON_SUB_PHASES then
        self:advancePhase()
    else
        self.subPhaseIndex = (self.subPhaseIndex or 1) + 1
        self.phaseElapsed = 0
        self.subPhaseElapsed = 0
    end

    return true
end

function BattleState:completeCurrentSubPhase()
    local subPhase = self:getCurrentSubPhase()

    if not subPhase then
        self:advancePhase()
        return false
    end

    if subPhase.id == "hostileMission" and self:runHostileMissionSubPhase() then
        return true
    end

    if subPhase.id == "hostileSortie" and self:runHostileSortieSubPhase() then
        return true
    end

    if subPhase.id == "hostileOccupation" and self:runHostileOccupationSubPhase() then
        return true
    end

    return self:finishCurrentSubPhase()
end

function BattleState:advanceDefiancePhase()
    if self.phaseIndex ~= PHASE.defiance then
        return false
    end

    self.draggedHandCard = nil
    self:clearTagAction()
    self:clearJaclDeployAction()
    self:setHoverPreview(nil, nil, nil)
    self.resources:clearSelections()
    self:advancePhase()
    return true
end

function BattleState:isDefiancePhase()
    return self.phaseIndex == PHASE.defiance
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
    self.jaclAppearedRound = self.round
    self.jaclDeployActionVisible = false
    self.jaclSpawnAnimation = Animation.new(BattleStyle.jaclFootprint.spawnDelay + BattleStyle.jaclFootprint.spawnDuration)
    self.jaclDismissAnimation = nil
    self:setActiveTagIndex(tagIndex)
    self:clearTagAction()

    return true
end

function BattleState:getJaclSpawnProgress()
    if not self.activeJaclCard then
        return 0
    end

    if self.jaclDismissAnimation then
        return 1 - Animation.easeOutCubic(Animation.progress(self.jaclDismissAnimation))
    end

    local animation = self.jaclSpawnAnimation

    if not animation then
        return 1
    end

    local style = BattleStyle.jaclFootprint
    local elapsed = math.max(0, animation.elapsed - style.spawnDelay)

    return Animation.easeOutCubic(math.min(1, elapsed / style.spawnDuration))
end

function BattleState:showJaclDeployAction()
    if not self.activeJaclCard or self.jaclDismissAnimation then
        return false
    end

    self.jaclDeployActionVisible = true
    return true
end

function BattleState:clearJaclDeployAction()
    self.jaclDeployActionVisible = false
end

function BattleState:isJaclDeployAvailable()
    return self.activeJaclCard
        and not self.jaclDismissAnimation
        and self.jaclAppearedRound
        and self.round > self.jaclAppearedRound
end

function BattleState:deployAgentFromJacl()
    if not self:isJaclDeployAvailable() then
        return false
    end

    self.jaclDeployActionVisible = false
    self.jaclDismissAnimation = Animation.new(BattleStyle.jaclFootprint.spawnDuration)
    self:setHoverPreview(nil, nil, nil)
    return true
end

function BattleState:getActiveAgentCard()
    local activeTag = self.tags[self.activeTagIndex]

    if not activeTag then
        return nil
    end

    return activeTag.card
end

function BattleState:getActiveChampionCard()
    return self.championCards[self.activeChampionIndex]
end

function BattleState:getActiveChampionForceKey()
    local card = self:getActiveChampionCard()
    local id = normalizedValue(card and (card.id or card.instanceId or card.name)) or "unknown"

    return "champion:" .. id
end

function BattleState:getSlotSignatureSourceCard()
    return self.activeJaclCard or self:getActiveAgentCard()
end

function BattleState:getActiveForceKey()
    local card = self:getSlotSignatureSourceCard()
    local prefix = self.activeJaclCard and "jacl" or "agent"
    local id = normalizedValue(card and (card.id or card.instanceId or card.name)) or "unknown"

    return prefix .. ":" .. id
end

function BattleState:getPlayZoneForceKey(zoneId)
    if zoneId == CHAMPION_OBJECTIVE_ZONE_ID then
        return self:getActiveChampionForceKey()
    end

    if zoneId == LANDMARK_ZONE_ID then
        return "landmark"
    end

    return self:getActiveForceKey()
end

function BattleState:getPlayZoneCards(zoneId, forceKey)
    local zone = self.playZones[zoneId]

    if not zone then
        return {}
    end

    return zone.cardsByForce[forceKey or self:getPlayZoneForceKey(zoneId)] or {}
end

function BattleState:getWritablePlayZoneCards(zoneId)
    local zone = self.playZones[zoneId]

    if not zone then
        return nil
    end

    local forceKey = self:getPlayZoneForceKey(zoneId)

    zone.cardsByForce[forceKey] = zone.cardsByForce[forceKey] or {}
    return zone.cardsByForce[forceKey]
end

function BattleState:seedChampionObjective()
    local championCard = self:getActiveChampionCard()
    local objectiveId = getChampionObjectiveId(championCard)
    local objectiveCard = objectiveId and objectiveById[objectiveId]
    local zoneCards = objectiveCard and self:getWritablePlayZoneCards(CHAMPION_OBJECTIVE_ZONE_ID)

    if not zoneCards then
        return false
    end

    zoneCards[1] = copyCard(objectiveCard, "champion-objective-" .. tostring(objectiveCard.id))
    return true
end

function BattleState:seedLandmark()
    local landmarkCard = self.landmarkCards and self.landmarkCards[1]
    local zoneCards = landmarkCard and self:getWritablePlayZoneCards(LANDMARK_ZONE_ID)

    if not zoneCards then
        return false
    end

    zoneCards[1] = copyCard(landmarkCard, "landmark-" .. tostring(landmarkCard.id))
    return true
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
    local zoneCards = self:getWritablePlayZoneCards(zoneId)

    if not zoneCards or zoneCards[activeTab] then
        self.draggedHandCard = nil
        return false
    end

    if not self.resources:payCard(card) then
        self.draggedHandCard = nil
        return false
    end

    zoneCards[activeTab] = card
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

function BattleState:getPlayZoneCard(zoneId, tabIndex)
    local zone = self.playZones[zoneId]

    if not zone then
        return nil
    end

    return self:getPlayZoneCards(zoneId)[tabIndex or zone.activeTab or 1]
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
