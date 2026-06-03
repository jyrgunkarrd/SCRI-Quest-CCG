local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local CardView = require("src.cards.card_view")
local HandLayout = require("src.battle.hand_layout")
local Animation = require("src.ui.animation")
local MethodColors = require("src.battle.method_colors")
local PlayLayout = require("src.battle.play_layout")
local Pixel = require("src.pixel")
local TagLayout = require("src.battle.tag_layout")
local TagView = require("src.battle.tag_view")
local Zones = require("src.battle.zones")

local BattleView = {}

local function setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

local function drawPreviewShadow(x, y, width, progress)
    local shadowPad = BattleStyle.hand.previewShadowPad
    local previewHeight = width * BattleStyle.hand.previewShadowHeightRatio

    love.graphics.setColor(0, 0, 0, BattleStyle.hand.previewShadowAlpha * progress)
    love.graphics.rectangle(
        "fill",
        Pixel.snap(x - shadowPad),
        Pixel.snap(y + shadowPad),
        Pixel.snap(width + shadowPad * 2),
        Pixel.snap(previewHeight),
        8,
        8
    )
end

local function drawWipedPreview(card, assets, x, y, scale, progress)
    local previewWidth = CardStyle.width * scale
    local wipeWidth = math.max(1, Pixel.snap(previewWidth * progress))
    local wipeX = Pixel.snap(x + previewWidth - wipeWidth)
    local wipeHeight = Pixel.snap(CardStyle.height * scale)

    love.graphics.setScissor(wipeX, y, wipeWidth, wipeHeight)
    CardView.draw(card, x, y, {
        assets = assets,
        scale = scale,
    })
    love.graphics.setScissor()

    if progress < 1 then
        local edgeWidth = BattleStyle.hand.previewWipeEdgeWidth

        love.graphics.setColor(0.55, 0.86, 1, BattleStyle.hand.previewWipeEdgeAlpha * (1 - progress))
        love.graphics.rectangle("fill", wipeX, y, edgeWidth, wipeHeight)
    end
end

local function getPreviewX(screenWidth, previewWidth, side)
    if side == "left" then
        return Pixel.snap(BattleStyle.hand.previewTopPadding)
    end

    if side == "right" then
        return Pixel.snap(screenWidth - previewWidth - BattleStyle.hand.previewTopPadding)
    end

    return Pixel.snap((screenWidth - previewWidth) / 2)
end

local function drawActiveAgentCard(state, assets, handZone, screenHeight)
    local activeAgentCard = state:getActiveAgentCard()

    if not activeAgentCard then
        return
    end

    local centerX, centerY = TagLayout.getWheelCenter(handZone, screenHeight)
    local scale = BattleStyle.agentCard.scale
    local cardWidth = CardStyle.width * scale
    local compactCardHeight = CardView.getCompactStatsHeight(scale, assets)
    local tagTop = centerY - BattleStyle.tag.radiusY - BattleStyle.tag.activeSize / 2 - BattleStyle.tag.framePad
    local cardX = Pixel.snap(centerX - cardWidth / 2)
    local cardY = Pixel.snap(tagTop - BattleStyle.agentCard.gapAboveTag - compactCardHeight)

    CardView.drawCompactStats(activeAgentCard, cardX, cardY, {
        assets = assets,
        scale = scale,
    })
end

local function drawTroopZone(zone, card, assets, isDragActive)
    if card then
        CardView.drawCompactStats(card, zone.x, zone.y, {
            assets = assets,
            scale = zone.scale,
        })
        return
    end

    local fill = BattleStyle.playZones.emptyFill
    local stroke = isDragActive and BattleStyle.playZones.validStroke or BattleStyle.playZones.emptyStroke

    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height, 6, 6)

    love.graphics.setColor(stroke)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", zone.x, zone.y, zone.width, zone.height, 6, 6)
end

local function drawZoneTabs(zone, zoneState, assets)
    local activeTab = zoneState.activeTab or 1
    local tabRects = PlayLayout.getTabRects(zone)
    local activeCard = zoneState.cards[activeTab]
    local activeColor = MethodColors.getCardColor(activeCard, BattleStyle.playZones.activeTabFill)

    love.graphics.setFont(assets.fonts.cardLabel)

    for index, rect in ipairs(tabRects) do
        local isActive = index == activeTab
        local hasCard = zoneState.cards[index] ~= nil
        local fill = hasCard and not isActive and BattleStyle.playZones.occupiedTabFill or BattleStyle.playZones.tabFill
        local stroke = isActive and activeColor or BattleStyle.playZones.emptyStroke
        local textColor = isActive and activeColor or BattleStyle.playZones.tabText

        love.graphics.setColor(fill)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 2, 2)

        love.graphics.setColor(stroke)
        love.graphics.setLineWidth(isActive and 2 or 1)
        love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 2, 2)

        love.graphics.setColor(textColor)
        love.graphics.printf(
            tostring(index),
            rect.x,
            Pixel.snap(rect.y + rect.height / 2 - assets.fonts.cardLabel:getHeight() / 2),
            rect.width,
            "center"
        )
    end
end

local function drawTroopZones(state, assets, handZone, screenHeight)
    local zones = PlayLayout.getTroopZones(handZone, screenHeight, assets)
    local isDragActive = state:getDraggedHandCard() ~= nil
    local orderedZoneIds = {
        "left_4",
        "left_3",
        "left_2",
        "left_1",
        "right_1",
        "right_2",
        "right_3",
        "right_4",
    }

    for _, zoneId in ipairs(orderedZoneIds) do
        local zoneState = state.playZones[zoneId]

        drawTroopZone(zones[zoneId], state:getPlayZoneCard(zoneId), assets, isDragActive)
        drawZoneTabs(zones[zoneId], zoneState, assets)
    end
end

local function drawDraggedHandCard(state, assets)
    local drag = state:getDraggedHandCard()

    if not drag then
        return
    end

    local scale = BattleStyle.hand.cardScale
    local cardWidth = CardStyle.width * scale
    local cardHeight = CardStyle.height * scale

    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.rectangle(
        "fill",
        Pixel.snap(drag.x - cardWidth / 2 + 8),
        Pixel.snap(drag.y - cardHeight / 2 + 10),
        Pixel.snap(cardWidth),
        Pixel.snap(cardHeight),
        8,
        8
    )

    CardView.draw(drag.card, Pixel.snap(drag.x - cardWidth / 2), Pixel.snap(drag.y - cardHeight / 2), {
        assets = assets,
        scale = scale,
    })
end

function BattleView.draw(state, assets)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)

    setColor(BattleStyle.colors.background)
    love.graphics.rectangle("fill", 0, 0, width, height)

    local layoutCards = HandLayout.getCards(state, handZone, height)

    drawTroopZones(state, assets, handZone, height)
    drawActiveAgentCard(state, assets, handZone, height)
    TagView.draw(state, assets, handZone, height)

    for _, layout in ipairs(layoutCards) do
        love.graphics.push()
        love.graphics.translate(Pixel.snap(layout.x + layout.width / 2), layout.y)
        love.graphics.rotate(layout.rotation)
        CardView.draw(layout.card, Pixel.snap(-layout.width / 2), 0, {
            assets = assets,
            scale = layout.scale,
        })
        love.graphics.pop()
    end

    local hoveredCard = state:getHoveredHandCard()

    if hoveredCard then
        local progress = Animation.easedProgress(state.hoverPreviewAnimation)
        local isReplacingPreview = state.hoverPreviewTransition == "replace"
        local scaleProgress = isReplacingPreview
            and 1
            or BattleStyle.hand.previewStartScale + (1 - BattleStyle.hand.previewStartScale) * progress
        local yOffset = isReplacingPreview and 0 or BattleStyle.hand.previewStartYOffset * (1 - progress)
        local previewScale = BattleStyle.hand.previewScale * scaleProgress
        local previewWidth = CardStyle.width * previewScale
        local previewX = getPreviewX(width, previewWidth, state.hoverPreviewSide)
        local previewY = Pixel.snap(BattleStyle.hand.previewTopPadding + yOffset)
        local previousCard = isReplacingPreview and state:getPreviousHoverPreviewCard() or nil

        drawPreviewShadow(previewX, previewY, previewWidth, isReplacingPreview and 1 or progress)

        if previousCard then
            CardView.draw(previousCard, previewX, previewY, {
                assets = assets,
                scale = previewScale,
            })
        end

        drawWipedPreview(hoveredCard, assets, previewX, previewY, previewScale, progress)
    end

    drawDraggedHandCard(state, assets)
end

return BattleView
