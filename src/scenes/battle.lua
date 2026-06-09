local BattleState = require("src.battle.battle_state")
local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local BattleView = require("src.battle.battle_view")
local HandLayout = require("src.battle.hand_layout")
local PlayLayout = require("src.battle.play_layout")
local Sfx = require("src.audio.sfx")
local Zones = require("src.battle.zones")

local Battle = {}

local assets
local state

local function playReject()
    Sfx.play(assets.audio.sfx.reject)
end

local function playResource()
    Sfx.play(assets.audio.sfx.resource)
end

local function playCardPlay()
    Sfx.play(assets.audio.sfx.cardPlay)
end

local function playCardConv()
    Sfx.play(assets.audio.sfx.cardConv)
end

local function playSwap()
    Sfx.play(assets.audio.sfx.swap)
end

local function playClick()
    Sfx.play(assets.audio.sfx.click)
end

local function playPhaseEnd()
    Sfx.play(assets.audio.sfx.phaseEnd)
end

local function playProgress()
    Sfx.play(assets.audio.sfx.progress)
end

local function playDamage()
    Sfx.play(assets.audio.sfx.damage)
end

local function playOccupy()
    Sfx.play(assets.audio.sfx.occupy)
end

local function playCardHover(suppressSound)
    if suppressSound then
        return
    end

    Sfx.play(assets.audio.sfx.cardHover)
end

function Battle.load(loadedAssets)
    assets = loadedAssets
    love.math.setRandomSeed(os.time())
    state = BattleState.new({
        handSize = 20,
    })
end

function Battle.update(dt)
    state:update(dt)

    if state:consumeProgressSfxRequest() then
        playProgress()
    end

    if state:consumeDamageSfxRequest() then
        playDamage()
    end

    if state:consumeOccupySfxRequest() then
        playOccupy()
    end
end

function Battle.draw()
    BattleView.draw(state, assets)
end

local function scrollHand(delta)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local displayWidth = CardStyle.width * BattleStyle.hand.cardScale

    state:scrollHand(delta, handZone.width, displayWidth, BattleStyle.hand.spacing)
end

local function updateHoveredCard(x, y, suppressHoverSound)
    if state:getDraggedHandCard() then
        state:setHoverPreview(nil, nil, nil)
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local agentRect = PlayLayout.getAgentCardRect(handZone, height, assets)
    local activeAgentCard = state:getActiveAgentCard()
    local activeChampionCard = state:getActiveChampionCard()

    if BattleView.hitTestActiveJacl(state, handZone, height, assets, x, y) then
        local changed = state:setHoverPreview(state.activeJaclCard, "jacl", "left")

        if changed then
            playCardHover(suppressHoverSound)
        end

        return
    end

    if activeChampionCard and BattleView.hitTestActiveChampion(state, handZone, height, assets, x, y) then
        local changed = state:setHoverPreview(activeChampionCard, "champion:" .. tostring(state.activeChampionIndex), "left")

        if changed then
            playCardHover(suppressHoverSound)
        end

        return
    end

    if activeAgentCard and PlayLayout.hitTestRect(agentRect, x, y) then
        local changed = state:setHoverPreview(activeAgentCard, "agent:" .. tostring(state.activeTagIndex), "left")

        if changed then
            playCardHover(suppressHoverSound)
        end

        return
    end

    local troopZones = PlayLayout.getTroopZones(handZone, height, assets)

    for zoneId, zone in pairs(troopZones) do
        if state:isPlayZoneVisible(zoneId) then
            local forceKey = state:getPlayZoneForceKey(zoneId)

            for tabIndex, rect in ipairs(PlayLayout.getTabRects(zone, assets)) do
                local card = state:getPlayZoneCard(zoneId, tabIndex)

                if card and PlayLayout.hitTestRect(rect, x, y) then
                    local previewSide = (zone.x + zone.width / 2) < width / 2 and "right" or "left"
                    local key = "play-tab:" .. forceKey .. ":" .. zoneId .. ":" .. tostring(tabIndex)
                    local changed = state:setHoverPreview(card, key, previewSide)

                    if changed then
                        playCardHover(suppressHoverSound)
                    end

                    return
                end
            end
        end
    end

    for zoneId, zone in pairs(troopZones) do
        if state:isPlayZoneVisible(zoneId) then
            local forceKey = state:getPlayZoneForceKey(zoneId)
            local card = state:getPlayZoneCard(zoneId)

            if card and PlayLayout.hitTestRect(zone, x, y) then
                local previewSide = (zone.x + zone.width / 2) < width / 2 and "right" or "left"
                local zoneState = state.playZones[zoneId]
                local key = "play:" .. forceKey .. ":" .. zoneId .. ":" .. tostring(zoneState.activeTab or 1)
                local changed = state:setHoverPreview(card, key, previewSide)

                if changed then
                    playCardHover(suppressHoverSound)
                end

                return
            end
        end
    end

    local layoutCards = HandLayout.getCards(state, handZone, height)
    local previousKey = state.hoverPreviewKey
    local nextIndex = HandLayout.hitTest(layoutCards, x, y)

    state:setHoveredHandIndex(nextIndex)

    if nextIndex and state.hoverPreviewKey ~= previousKey then
        playCardHover(suppressHoverSound)
    end
end

function Battle.keypressed(key)
    if not state:isDefiancePhase() then
        return
    end

    if key == "left" then
        scrollHand(BattleStyle.hand.scrollSpeed)
        updateHoveredCard(love.mouse.getPosition())
    elseif key == "right" then
        scrollHand(-BattleStyle.hand.scrollSpeed)
        updateHoveredCard(love.mouse.getPosition())
    elseif key == "space" then
        if state:advanceDefiancePhase() then
            playPhaseEnd()
        else
            playReject()
        end
    end
end

function Battle.wheelmoved(x, y)
    if not state:isDefiancePhase() then
        return
    end

    local delta = 0

    if math.abs(x) > math.abs(y) then
        delta = x * BattleStyle.hand.scrollSpeed
    else
        delta = y * BattleStyle.hand.scrollSpeed
    end

    scrollHand(delta)
    updateHoveredCard(love.mouse.getPosition())
end

function Battle.mousemoved(x, y)
    if not state:isDefiancePhase() then
        state:setHoverPreview(nil, nil, nil)
        return
    end

    state:updateDraggedHandCard(x, y)
    updateHoveredCard(x, y)
end

function Battle.mousepressed(x, y, button)
    if not state:isDefiancePhase() then
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local layoutCards = HandLayout.getCards(state, handZone, height)
    local tagAction, tagIndex = BattleView.hitTestTagAction(state, handZone, height, assets, x, y)
    local deployButtonHit, deployButtonEnabled = BattleView.hitTestJaclDeployAction(state, handZone, height, assets, x, y)

    if state.jaclDeployActionVisible and (button == 1 or button == 2) then
        if deployButtonHit then
            if button == 1 and deployButtonEnabled and state:deployAgentFromJacl() then
                playSwap()
            elseif button == 1 then
                playReject()
            end
        else
            state:clearJaclDeployAction()
        end

        return
    end

    if button == 1 and BattleView.hitTestPhaseTracker(state, handZone, height, assets, x, y) then
        state:advanceDefiancePhase()
        playPhaseEnd()

        return
    end

    if state.tagActionMode then
        if button == 1 and tagAction == "goSilent" then
            state:showGoLoudSelection()
            playClick()
        elseif button == 1 and tagAction == "goLoud" then
            if state:goLoud(tagIndex) then
                playSwap()
            else
                playReject()
            end
        elseif not tagAction and (button == 1 or button == 2) then
            state:clearTagAction()
        end

        return
    end

    if BattleView.hitTestActiveJacl(state, handZone, height, assets, x, y) then
        if button == 2 then
            state:showJaclDeployAction()
            playClick()
        end

        return
    end

    if button == 2 then
        local agentRect = PlayLayout.getAgentCardRect(handZone, height, assets)

        if PlayLayout.hitTestRect(agentRect, x, y) then
            state:showGoSilentPrompt()
            playClick()
            return
        end

        local handIndex = HandLayout.hitTest(layoutCards, x, y)

        if handIndex then
            if state.resources:showDiscardButton(state.hand[handIndex]) then
                playCardConv()
            end
        else
            state.resources:clearSelections()
        end

        return
    end

    if button ~= 1 then
        return
    end

    local _, discardCard, discardRect = state.resources:hitTestButtons(layoutCards, x, y)

    if discardCard then
        local targetX, targetY = BattleView.getResourcePipTarget(state, handZone, height, assets)

        if state:discardHandCard(discardCard, {
            fromX = discardRect.x + discardRect.width / 2,
            fromY = discardRect.y + discardRect.height / 2,
            toX = targetX,
            toY = targetY,
        }) then
            playResource()
            updateHoveredCard(x, y, true)
        else
            playReject()
            updateHoveredCard(x, y)
        end

        return
    end

    local troopZones = PlayLayout.getTroopZones(handZone, height, assets)
    local zoneId, tabIndex = PlayLayout.hitTestZoneTabs(troopZones, x, y, assets)

    if zoneId and state:isPlayZoneVisible(zoneId) then
        state:setPlayZoneTab(zoneId, tabIndex)
        return
    end

    local handIndex = HandLayout.hitTest(layoutCards, x, y)

    if handIndex then
        if not state:startDraggingHandCard(handIndex, x, y) then
            playReject()
        end
    end
end

function Battle.mousereleased(x, y, button)
    if not state:isDefiancePhase() then
        return
    end

    if button ~= 1 then
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local troopZones = PlayLayout.getTroopZones(handZone, height, assets)
    local zoneId = PlayLayout.hitTestTroopZones(troopZones, x, y)

    if BattleView.hitTestActiveJacl(state, handZone, height, assets, x, y) then
        zoneId = nil
    end

    if zoneId and not state:isPlayZoneVisible(zoneId) then
        zoneId = nil
    end

    if state:getDraggedHandCard() then
        if state:dropDraggedHandCard(zoneId) then
            playCardPlay()
        else
            playReject()
            state:cancelDraggingHandCard()
        end
    end

    updateHoveredCard(x, y)
end

return Battle
