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

function Battle.load(loadedAssets)
    assets = loadedAssets
    love.math.setRandomSeed(os.time())
    state = BattleState.new({
        handSize = 20,
    })
end

function Battle.update(dt)
    state:update(dt)
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

local function updateHoveredCard(x, y)
    if state:getDraggedHandCard() then
        state:setHoverPreview(nil, nil, nil)
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local agentRect = PlayLayout.getAgentCardRect(handZone, height, assets)
    local activeAgentCard = state:getActiveAgentCard()

    if activeAgentCard and PlayLayout.hitTestRect(agentRect, x, y) then
        local changed = state:setHoverPreview(activeAgentCard, "agent:" .. tostring(state.activeTagIndex), "left")

        if changed then
            Sfx.play(assets.audio.sfx.cardHover)
        end

        return
    end

    local troopZones = PlayLayout.getTroopZones(handZone, height, assets)

    for zoneId, zone in pairs(troopZones) do
        local zoneState = state.playZones[zoneId]

        for tabIndex, rect in ipairs(PlayLayout.getTabRects(zone)) do
            local card = zoneState and zoneState.cards[tabIndex]

            if card and PlayLayout.hitTestRect(rect, x, y) then
                local previewSide = (zone.x + zone.width / 2) < width / 2 and "right" or "left"
                local key = "play-tab:" .. zoneId .. ":" .. tostring(tabIndex)
                local changed = state:setHoverPreview(card, key, previewSide)

                if changed then
                    Sfx.play(assets.audio.sfx.cardHover)
                end

                return
            end
        end
    end

    for zoneId, zone in pairs(troopZones) do
        local card = state:getPlayZoneCard(zoneId)

        if card and PlayLayout.hitTestRect(zone, x, y) then
            local previewSide = (zone.x + zone.width / 2) < width / 2 and "right" or "left"
            local zoneState = state.playZones[zoneId]
            local key = "play:" .. zoneId .. ":" .. tostring(zoneState.activeTab or 1)
            local changed = state:setHoverPreview(card, key, previewSide)

            if changed then
                Sfx.play(assets.audio.sfx.cardHover)
            end

            return
        end
    end

    local layoutCards = HandLayout.getCards(state, handZone, height)
    local previousKey = state.hoverPreviewKey
    local nextIndex = HandLayout.hitTest(layoutCards, x, y)

    state:setHoveredHandIndex(nextIndex)

    if nextIndex and state.hoverPreviewKey ~= previousKey then
        Sfx.play(assets.audio.sfx.cardHover)
    end
end

function Battle.keypressed(key)
    if key == "left" then
        scrollHand(BattleStyle.hand.scrollSpeed)
        updateHoveredCard(love.mouse.getPosition())
    elseif key == "right" then
        scrollHand(-BattleStyle.hand.scrollSpeed)
        updateHoveredCard(love.mouse.getPosition())
    elseif key == "q" then
        state:rotateTags(-1)
    elseif key == "e" then
        state:rotateTags(1)
    end
end

function Battle.wheelmoved(x, y)
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
    state:updateDraggedHandCard(x, y)
    updateHoveredCard(x, y)
end

function Battle.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local troopZones = PlayLayout.getTroopZones(handZone, height, assets)
    local zoneId, tabIndex = PlayLayout.hitTestZoneTabs(troopZones, x, y)

    if zoneId then
        state:setPlayZoneTab(zoneId, tabIndex)
        return
    end

    local layoutCards = HandLayout.getCards(state, handZone, height)
    local handIndex = HandLayout.hitTest(layoutCards, x, y)

    if handIndex then
        if not state:startDraggingHandCard(handIndex, x, y) then
            playReject()
        end
    end
end

function Battle.mousereleased(x, y, button)
    if button ~= 1 then
        return
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local troopZones = PlayLayout.getTroopZones(handZone, height, assets)
    local zoneId = PlayLayout.hitTestTroopZones(troopZones, x, y)

    if state:getDraggedHandCard() and not state:dropDraggedHandCard(zoneId) then
        playReject()
        state:cancelDraggingHandCard()
    end

    updateHoveredCard(x, y)
end

return Battle
