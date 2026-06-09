local BattleStyle = require("src.battle.battle_style")
local BattleAnimations = require("src.battle.battle_animations")
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

local METHOD_ICON_ORDER = {
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

local PHASES = {
    "Start",
    "Defiance",
    "Sermon",
    "End",
}

local UPPER_ZONE_LABELS = {
    upper_left_4 = "Landmark",
    upper_left_3 = "Warzone",
    upper_left_2 = "Shock Forces",
    upper_left_1 = "Line Forces",
    upper_right_1 = "Line Forces",
    upper_right_2 = "Shock Forces",
    upper_right_3 = "Intel",
    upper_right_4 = "Objective",
}

local UPPER_ZONE_COLORS = {
    upper_left_4 = { 0.757, 1.0, 0.58, 1 },
    upper_left_3 = { 0.757, 1.0, 0.58, 1 },
    upper_left_2 = { 1.0, 0.2, 0.2, 1 },
    upper_left_1 = { 1.0, 0.2, 0.2, 1 },
    upper_right_1 = { 1.0, 0.2, 0.2, 1 },
    upper_right_2 = { 1.0, 0.2, 0.2, 1 },
    upper_right_3 = { 1.0, 0.2, 0.2, 1 },
    upper_right_4 = { 1.0, 0.2, 0.2, 1 },
}

local function setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

local getJaclFootprintRect

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
    local rect = {
        x = cardX,
        y = cardY,
        width = cardWidth,
        height = compactCardHeight,
        scale = scale,
    }

    if BattleAnimations.drawHostileSortieAgentImpact(state.hostileSortieAttackAnimation, activeAgentCard, rect, assets) then
        return
    end

    CardView.drawCompactStats(activeAgentCard, cardX, cardY, {
        assets = assets,
        scale = scale,
    })
end

local function getChampionCardRect(state, handZone, screenHeight, assets)
    local activeChampionCard = state:getActiveChampionCard()

    if not activeChampionCard then
        return nil
    end

    local agentRect = PlayLayout.getAgentCardRect(handZone, screenHeight, assets)
    local zones = PlayLayout.getTroopZones(handZone, screenHeight, assets)
    local upperZone = zones.upper_left_1 or zones.upper_right_1
    local scale = BattleStyle.championCard.scale
    local cardWidth = CardStyle.width * scale
    local compactCardHeight = CardView.getCompactStatsHeight(scale, assets)

    return {
        x = Pixel.snap(agentRect.x + agentRect.width / 2 - cardWidth / 2),
        y = upperZone and upperZone.y or Pixel.snap(agentRect.y - compactCardHeight - BattleStyle.playZones.rowGap),
        width = cardWidth,
        height = compactCardHeight,
        scale = scale,
    }
end

local function drawActiveChampionCard(state, assets, handZone, screenHeight)
    local activeChampionCard = state:getActiveChampionCard()
    local rect = getChampionCardRect(state, handZone, screenHeight, assets)

    if not activeChampionCard or not rect then
        return
    end

    local agentRect = PlayLayout.getAgentCardRect(handZone, screenHeight, assets)

    if BattleAnimations.drawHostileSortieChampion(state.hostileSortieAttackAnimation, activeChampionCard, rect, agentRect, assets) then
        return
    end

    if BattleAnimations.drawHostileMissionChampion(state.hostileMissionAnimation, activeChampionCard, rect, assets, handZone, screenHeight) then
        return
    end

    CardView.drawCompactStats(activeChampionCard, rect.x, rect.y, {
        assets = assets,
        scale = rect.scale,
    })
end

local function drawTroopZoneBackplate(zone, isValidDropTarget, accentColor)
    local fill = BattleStyle.playZones.emptyFill
    local stroke = isValidDropTarget and BattleStyle.playZones.validStroke
        or accentColor
        or BattleStyle.playZones.emptyStroke

    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height, 6, 6)

    love.graphics.setColor(stroke)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", zone.x, zone.y, zone.width, zone.height, 6, 6)
end

local function drawTroopZoneCard(zone, card, assets)
    if not card then
        return
    end

    CardView.drawCompactStats(card, zone.x, zone.y, {
        assets = assets,
        scale = zone.scale,
    })
end

local function drawZoneLabel(zone, label, labelY, labelHeight, assets, textColor, outlineColor)
    love.graphics.setColor(BattleStyle.playZones.labelFill)
    love.graphics.rectangle("fill", zone.x, labelY, zone.width, labelHeight, 2, 2)

    love.graphics.setColor(outlineColor or BattleStyle.playZones.emptyStroke)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", zone.x, labelY, zone.width, labelHeight, 2, 2)

    love.graphics.setFont(assets.fonts.cardSmall)
    love.graphics.setColor(textColor or BattleStyle.playZones.tabText)
    love.graphics.printf(
        string.upper(label),
        zone.x,
        Pixel.snap(labelY + labelHeight / 2 - assets.fonts.cardSmall:getHeight() / 2),
        zone.width,
        "center"
    )
end

local function drawZoneAcceptedTypeLabel(state, zone, zoneId, assets)
    if zoneId:match("^upper_") then
        return
    end

    local acceptedType = state:getPlayZoneAcceptedType(zoneId)

    if not acceptedType then
        return
    end

    local labelHeight = PlayLayout.getAcceptedTypeLabelHeight(zone, assets)
    local labelY = Pixel.snap(zone.y + zone.height + BattleStyle.playZones.tabTopGap)

    drawZoneLabel(zone, acceptedType, labelY, labelHeight, assets)
end

local function drawUpperZoneLabel(zone, zoneId, assets)
    local label = UPPER_ZONE_LABELS[zoneId]

    if not label then
        return
    end

    local labelHeight = assets.fonts.cardSmall:getHeight() + 6
    local labelY = Pixel.snap(zone.y - labelHeight - BattleStyle.playZones.tabTopGap)

    drawZoneLabel(zone, label, labelY, labelHeight, assets, BattleStyle.playZones.tabText, UPPER_ZONE_COLORS[zoneId])
end

local function drawZoneSigBadge(state, zone, zoneId, assets)
    local acceptedSig = state:getPlayZoneAcceptedSig(zoneId)

    if not acceptedSig then
        return
    end

    local sig = string.lower(tostring(acceptedSig))
    local image = assets.images.signature[sig]
    local badgeSize = BattleStyle.playZones.sigBadgeSize
    local badgeOffset = BattleStyle.playZones.sigBadgeOffset
    local badgeX = Pixel.snap(zone.x + badgeOffset)
    local badgeY = Pixel.snap(zone.y + badgeOffset)
    local iconPad = 3
    local iconSize = badgeSize - iconPad * 2

    love.graphics.setColor(BattleStyle.playZones.sigBadgeFill)
    love.graphics.rectangle("fill", badgeX, badgeY, badgeSize, badgeSize)

    love.graphics.setColor(BattleStyle.playZones.emptyStroke)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", badgeX, badgeY, badgeSize, badgeSize)

    if image then
        local scale = math.min(iconSize / image:getWidth(), iconSize / image:getHeight())
        local imageWidth = image:getWidth() * scale
        local imageHeight = image:getHeight() * scale

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            image,
            Pixel.snap(badgeX + (badgeSize - imageWidth) / 2),
            Pixel.snap(badgeY + (badgeSize - imageHeight) / 2),
            0,
            scale,
            scale
        )
    else
        love.graphics.setFont(assets.fonts.cardSmall)
        love.graphics.setColor(BattleStyle.playZones.tabText)
        love.graphics.printf(
            string.upper(sig),
            badgeX,
            Pixel.snap(badgeY + badgeSize / 2 - assets.fonts.cardSmall:getHeight() / 2),
            badgeSize,
            "center"
        )
    end
end

local function drawZoneTabs(state, zone, zoneState, zoneId, assets)
    local activeTab = zoneState.activeTab or 1
    local tabRects = PlayLayout.getTabRects(zone, assets)
    local zoneCards = state:getPlayZoneCards(zoneId)
    local activeCard = zoneCards[activeTab]
    local activeColor = MethodColors.getCardColor(activeCard, BattleStyle.playZones.activeTabFill)

    love.graphics.setFont(assets.fonts.cardLabel)

    for index, rect in ipairs(tabRects) do
        local isActive = index == activeTab
        local hasCard = zoneCards[index] ~= nil
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
    local drag = state:getDraggedHandCard()

    for _, zoneId in ipairs(PlayLayout.getOrderedTroopZoneIds()) do
        if state:isPlayZoneVisible(zoneId) then
            local zoneState = state.playZones[zoneId]
            local activeCard = state:getPlayZoneCard(zoneId)
            local isValidDropTarget = drag
                and not activeCard
                and state:canCardPlayInZone(drag.card, zoneId)

            drawTroopZoneBackplate(zones[zoneId], isValidDropTarget, UPPER_ZONE_COLORS[zoneId])
            drawZoneSigBadge(state, zones[zoneId], zoneId, assets)
            drawTroopZoneCard(zones[zoneId], activeCard, assets)
            drawUpperZoneLabel(zones[zoneId], zoneId, assets)
            drawZoneAcceptedTypeLabel(state, zones[zoneId], zoneId, assets)
            drawZoneTabs(state, zones[zoneId], zoneState, zoneId, assets)

            if state.hostileMissionAnimation and zoneId == state.hostileMissionAnimation.targetZoneId then
                BattleAnimations.drawHostileMissionObjectiveFlash(state.hostileMissionAnimation, zones[zoneId], assets)
            end
        end
    end
end

local function drawDraggedHandCard(state, assets)
    local drag = state:getDraggedHandCard()

    if not drag then
        return
    end

    local scale = BattleStyle.agentCard.scale
    local cardWidth = CardStyle.width * scale
    local cardHeight = CardView.getCompactStatsHeight(scale, assets)
    local cardX = Pixel.snap(drag.x - cardWidth / 2)
    local cardY = Pixel.snap(drag.y - cardHeight / 2)

    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.rectangle(
        "fill",
        Pixel.snap(cardX + 8),
        Pixel.snap(cardY + 10),
        Pixel.snap(cardWidth),
        Pixel.snap(cardHeight),
        8,
        8
    )

    CardView.drawCompactStats(drag.card, cardX, cardY, {
        assets = assets,
        scale = scale,
    })
end

local function drawScaledImageCentered(image, x, y, width, height)
    local scale = math.min(width / image:getWidth(), height / image:getHeight())
    local imageWidth = image:getWidth() * scale
    local imageHeight = image:getHeight() * scale

    love.graphics.draw(
        image,
        Pixel.snap(x + (width - imageWidth) / 2),
        Pixel.snap(y + (height - imageHeight) / 2),
        0,
        scale,
        scale
    )
end

local function drawResourcePips(resourceSystem, boxX, boxY, boxWidth)
    local style = BattleStyle.resourceBox
    local count = resourceSystem and resourceSystem.pips or 0
    local maxPips = math.floor((boxWidth - style.pad * 2 + style.pipGap) / (style.pipWidth + style.pipGap))
    local visiblePips = math.min(count, maxPips)
    local totalWidth = visiblePips * style.pipWidth + math.max(0, visiblePips - 1) * style.pipGap
    local startX = Pixel.snap(boxX + (boxWidth - totalWidth) / 2)
    local pipY = Pixel.snap(boxY + style.topHeight / 2 - style.pipHeight / 2)

    love.graphics.setColor(style.pipFill)

    for index = 1, visiblePips do
        love.graphics.rectangle(
            "fill",
            Pixel.snap(startX + (index - 1) * (style.pipWidth + style.pipGap)),
            pipY,
            style.pipWidth,
            style.pipHeight,
            2,
            2
        )
    end
end

local function getResourceBoxRect(state, handZone, screenHeight, assets)
    local style = BattleStyle.resourceBox
    local footprintRect = getJaclFootprintRect(state, handZone, screenHeight, assets)
    local iconRowHeight = style.iconSize + style.pad * 2
    local boxWidth = style.width
    local boxHeight = style.topHeight + iconRowHeight
    local x = Pixel.snap(footprintRect.x + footprintRect.width + style.gapFromFootprint)
    local y = Pixel.snap(footprintRect.y + footprintRect.height - boxHeight)

    return {
        x = x,
        y = y,
        width = boxWidth,
        height = boxHeight,
        pipTargetX = Pixel.snap(x + boxWidth / 2),
        pipTargetY = Pixel.snap(y + style.topHeight / 2),
    }
end

local function getPhaseTrackerRect(state, handZone, screenHeight, assets)
    local style = BattleStyle.phaseTracker
    local footprintRect = getJaclFootprintRect(state, handZone, screenHeight, assets)
    local boxWidth = style.width
    local boxHeight = style.topHeight + style.phaseHeight + style.pad * 2
    local x = Pixel.snap(footprintRect.x - boxWidth - style.gapFromFootprint)
    local y = Pixel.snap(footprintRect.y + footprintRect.height - boxHeight)

    return {
        x = x,
        y = y,
        width = boxWidth,
        height = boxHeight,
    }
end

function BattleView.getResourcePipTarget(state, handZone, screenHeight, assets)
    local rect = getResourceBoxRect(state, handZone, screenHeight, assets)

    return rect.pipTargetX, rect.pipTargetY
end

local function drawPhaseTracker(state, assets, handZone, screenHeight)
    local style = BattleStyle.phaseTracker
    local rect = getPhaseTrackerRect(state, handZone, screenHeight, assets)
    local dividerY = Pixel.snap(rect.y + style.topHeight)
    local phaseCount = #PHASES
    local phaseY = Pixel.snap(dividerY + style.pad)
    local totalGap = style.phaseGap * math.max(0, phaseCount - 1)
    local phaseWidth = Pixel.snap((rect.width - style.pad * 2 - totalGap) / phaseCount)
    local phaseIndex = state.phaseIndex or 1

    love.graphics.setColor(style.fill)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)

    love.graphics.setColor(style.stroke)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height)

    love.graphics.setColor(style.divider)
    love.graphics.setLineWidth(1)
    love.graphics.line(rect.x, dividerY, rect.x + rect.width, dividerY)

    love.graphics.setFont(assets.fonts.cardLabel)
    love.graphics.setColor(style.text)
    love.graphics.printf(
        "ROUND " .. tostring(state.round or 1),
        rect.x,
        Pixel.snap(rect.y + style.topHeight / 2 - assets.fonts.cardLabel:getHeight() / 2),
        rect.width,
        "center"
    )

    for index, phaseName in ipairs(PHASES) do
        local phaseX = Pixel.snap(rect.x + style.pad + (index - 1) * (phaseWidth + style.phaseGap))
        local isActive = index == phaseIndex

        love.graphics.setColor(isActive and style.activeFill or style.inactiveFill)
        love.graphics.rectangle("fill", phaseX, phaseY, phaseWidth, style.phaseHeight, 2, 2)

        love.graphics.setColor(isActive and style.activeStroke or style.stroke)
        love.graphics.setLineWidth(isActive and 2 or 1)
        love.graphics.rectangle("line", phaseX, phaseY, phaseWidth, style.phaseHeight, 2, 2)

        love.graphics.setFont(assets.fonts.cardSmall)
        love.graphics.setColor(isActive and style.text or style.mutedText)
        love.graphics.printf(
            string.upper(phaseName),
            phaseX,
            Pixel.snap(phaseY + style.phaseHeight / 2 - assets.fonts.cardSmall:getHeight() / 2),
            phaseWidth,
            "center"
        )
    end

    local subPhaseLabel = state.getCurrentSubPhaseLabel and state:getCurrentSubPhaseLabel()

    if subPhaseLabel then
        love.graphics.setFont(assets.fonts.cardSmall)
        love.graphics.setColor(style.text)
        love.graphics.printf(
            string.upper(subPhaseLabel),
            rect.x,
            Pixel.snap(rect.y + rect.height + style.subPhaseGap),
            rect.width,
            "center"
        )
    end
end

local function drawResourceBox(state, assets, handZone, screenHeight)
    local style = BattleStyle.resourceBox
    local resourceSystem = state.resources
    local boxRect = getResourceBoxRect(state, handZone, screenHeight, assets)
    local boxX = boxRect.x
    local boxY = boxRect.y
    local boxWidth = boxRect.width
    local boxHeight = boxRect.height
    local dividerY = Pixel.snap(boxY + style.topHeight)

    love.graphics.setColor(style.fill)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    love.graphics.setColor(style.stroke)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)

    love.graphics.setColor(style.divider)
    love.graphics.setLineWidth(1)
    love.graphics.line(boxX, dividerY, boxX + boxWidth, dividerY)

    drawResourcePips(resourceSystem, boxX, boxY, boxWidth)

    for index, name in ipairs(METHOD_ICON_ORDER) do
        local column = index - 1
        local totalIconWidth = style.iconSize * #METHOD_ICON_ORDER + style.iconGap * (#METHOD_ICON_ORDER - 1)
        local startX = Pixel.snap(boxX + (boxWidth - totalIconWidth) / 2)
        local iconX = Pixel.snap(startX + column * (style.iconSize + style.iconGap))
        local iconY = Pixel.snap(dividerY + style.pad)
        local image = assets.images.methods[name]
        local isHighlighted = resourceSystem and resourceSystem:isMethodHighlighted(name)
        local highlightColor = MethodColors.getColorByName(name)
        local drawY = iconY

        if isHighlighted then
            drawY = Pixel.snap(iconY + math.sin(love.timer.getTime() * style.activeIconBobSpeed + index * 0.55) * style.activeIconBobAmount)
        end

        love.graphics.setColor(style.iconFill)
        love.graphics.rectangle("fill", iconX, drawY, style.iconSize, style.iconSize, 2, 2)

        if image then
            love.graphics.setColor(1, 1, 1, 1)
            drawScaledImageCentered(image, iconX, drawY, style.iconSize, style.iconSize)
        else
            love.graphics.setFont(assets.fonts.cardTiny)
            love.graphics.setColor(BattleStyle.playZones.tabText)
            love.graphics.printf(
                string.sub(name, 1, 1),
                iconX,
                Pixel.snap(drawY + style.iconSize / 2 - assets.fonts.cardTiny:getHeight() / 2),
                style.iconSize,
                "center"
            )
        end

        if isHighlighted then
            love.graphics.setColor(highlightColor)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", iconX, drawY, style.iconSize, style.iconSize, 2, 2)
        end
    end
end

local function drawResourceDiscardButtons(state, assets, layoutCards)
    local resourceSystem = state.resources

    if not resourceSystem or not resourceSystem:hasSelections() then
        return
    end

    local style = BattleStyle.resourceDiscardButton

    for _, layout in ipairs(layoutCards) do
        if resourceSystem:isCardSelected(layout.card) then
            local methodName = MethodColors.getPrimaryMethodName(layout.card)
            local image = methodName and assets.images.methods[methodName] or nil
            local color = MethodColors.getColorByName(methodName)
            local rect = resourceSystem:getButtonRect(layout)

            love.graphics.setColor(style.shadow)
            love.graphics.rectangle("fill", rect.x + 4, rect.y + 5, rect.width, rect.height, 4, 4)

            love.graphics.setColor(style.fill)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 4, 4)

            love.graphics.setColor(color)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 4, 4)

            if image then
                love.graphics.setColor(1, 1, 1, 1)
                drawScaledImageCentered(
                    image,
                    Pixel.snap(rect.x + rect.width / 2 - style.iconSize / 2),
                    Pixel.snap(rect.y + rect.height / 2 - style.iconSize / 2),
                    style.iconSize,
                    style.iconSize
                )
            elseif methodName then
                love.graphics.setFont(assets.fonts.cardTiny)
                love.graphics.setColor(BattleStyle.playZones.tabText)
                love.graphics.printf(
                    string.sub(methodName, 1, 1),
                    rect.x,
                    Pixel.snap(rect.y + rect.height / 2 - assets.fonts.cardTiny:getHeight() / 2),
                    rect.width,
                    "center"
                )
            end
        end
    end
end

local function drawResourceConversionEffects(state, assets)
    local resourceSystem = state.resources

    if not resourceSystem then
        return
    end

    local buttonStyle = BattleStyle.resourceDiscardButton
    local pipStyle = BattleStyle.resourceBox

    for _, effect in ipairs(resourceSystem.conversionEffects) do
        local pulseProgress = math.min(1, effect.elapsed / effect.pulseDuration)
        local pulseAlpha = 1 - pulseProgress
        local pulseScale = 1 + (effect.pulseScale - 1) * Animation.easeOutCubic(pulseProgress)
        local methodName = effect.methodEntries[1] and effect.methodEntries[1].name or nil
        local image = methodName and assets.images.methods[methodName] or nil
        local color = MethodColors.getColorByName(methodName)

        if pulseAlpha > 0 then
            local size = buttonStyle.iconSize * pulseScale
            local iconX = Pixel.snap(effect.fromX - size / 2)
            local iconY = Pixel.snap(effect.fromY - size / 2)

            if image then
                love.graphics.setColor(1, 1, 1, pulseAlpha)
                drawScaledImageCentered(image, iconX, iconY, size, size)
            end

            love.graphics.setColor(color[1], color[2], color[3], pulseAlpha)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", iconX, iconY, size, size, 3, 3)
        end

        love.graphics.setColor(pipStyle.pipFill)

        for pipIndex = 1, effect.pipCount do
            local pipElapsed = effect.elapsed - (pipIndex - 1) * effect.pipStagger

            if pipElapsed >= 0 and pipElapsed <= effect.pipDuration then
                local progress = Animation.easeOutCubic(math.min(1, pipElapsed / effect.pipDuration))
                local x = Animation.lerp(effect.fromX, effect.toX, progress)
                local y = Animation.lerp(effect.fromY, effect.toY, progress)
                    - math.sin(progress * math.pi) * effect.pipArcHeight

                love.graphics.setColor(pipStyle.pipFill[1], pipStyle.pipFill[2], pipStyle.pipFill[3], 1 - progress * 0.15)
                love.graphics.rectangle(
                    "fill",
                    Pixel.snap(x - pipStyle.pipWidth / 2),
                    Pixel.snap(y - pipStyle.pipHeight / 2),
                    pipStyle.pipWidth,
                    pipStyle.pipHeight,
                    2,
                    2
                )
            end
        end
    end
end

getJaclFootprintRect = function(state, handZone, screenHeight, assets)
    local style = BattleStyle.jaclFootprint
    local agentRect = PlayLayout.getAgentCardRect(handZone, screenHeight, assets)
    local centerX = agentRect.x + agentRect.width / 2
    local top = Pixel.snap(agentRect.y - style.pad)
    local bottom = nil

    for _, slot in ipairs(TagLayout.getSlots(state, handZone, screenHeight)) do
        local slotBottom = slot.y + slot.size + style.pad

        bottom = bottom and math.max(bottom, slotBottom) or slotBottom
    end

    if not bottom then
        local _, centerY = TagLayout.getWheelCenter(handZone, screenHeight)
        bottom = centerY + BattleStyle.tag.radiusY + BattleStyle.tag.activeSize / 2 + style.pad
    end

    bottom = Pixel.snap(bottom)

    local size = Pixel.snap(math.max(1, bottom - top))
    local x = Pixel.snap(centerX - size / 2)

    return {
        x = x,
        y = top,
        width = size,
        height = size,
    }
end

local function drawActiveJaclCard(state, assets, handZone, screenHeight)
    local card = state.activeJaclCard

    if not card then
        return
    end

    local progress = state:getJaclSpawnProgress()

    if progress <= 0 then
        return
    end

    local rect = getJaclFootprintRect(state, handZone, screenHeight, assets)
    local wipeWidth = math.max(1, Pixel.snap(rect.width * progress))
    local wipeX = Pixel.snap(rect.x + rect.width - wipeWidth)

    love.graphics.setScissor(wipeX, rect.y, wipeWidth, rect.height)
    CardView.drawJaclFrame(card, rect.x, rect.y, rect.width, {
        assets = assets,
    })
    love.graphics.setScissor()

    if progress < 1 then
        love.graphics.setColor(0.55, 0.86, 1, BattleStyle.hand.previewWipeEdgeAlpha * (1 - progress))
        love.graphics.rectangle("fill", wipeX, rect.y, BattleStyle.hand.previewWipeEdgeWidth, rect.height)
    end
end

local function drawJaclFootprint(state, handZone, screenHeight, assets)
    if not state.activeJaclCard or state:getJaclSpawnProgress() <= 0 then
        return
    end

    local style = BattleStyle.jaclFootprint
    local rect = getJaclFootprintRect(state, handZone, screenHeight, assets)
    local stroke = MethodColors.getCardColor(state.activeJaclCard, style.stroke)

    love.graphics.setColor(stroke)
    love.graphics.setLineWidth(style.lineWidth)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height)
end

local function getJaclDeployButtonRect(state, handZone, screenHeight, assets)
    local style = BattleStyle.jaclAction
    local rect = getJaclFootprintRect(state, handZone, screenHeight, assets)

    return {
        x = Pixel.snap(rect.x + rect.width / 2 - style.buttonWidth / 2),
        y = Pixel.snap(rect.y - style.buttonHeight - style.buttonGap),
        width = style.buttonWidth,
        height = style.buttonHeight,
    }
end

local function drawJaclDeployAction(state, assets, handZone, screenHeight)
    if not state.jaclDeployActionVisible or not state.activeJaclCard then
        return
    end

    local style = BattleStyle.jaclAction
    local rect = getJaclDeployButtonRect(state, handZone, screenHeight, assets)
    local isAvailable = state:isJaclDeployAvailable()

    love.graphics.setColor(isAvailable and style.fill or style.disabledFill)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 4, 4)

    love.graphics.setColor(isAvailable and style.stroke or style.disabledStroke)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 4, 4)

    love.graphics.setFont(assets.fonts.cardLabel)
    love.graphics.setColor(isAvailable and style.text or style.disabledText)
    love.graphics.printf(
        "Deploy Agent",
        rect.x,
        Pixel.snap(rect.y + rect.height / 2 - assets.fonts.cardLabel:getHeight() / 2),
        rect.width,
        "center"
    )
end

local function getGoSilentButtonRect(handZone, screenHeight, assets)
    local style = BattleStyle.tagAction
    local agentRect = PlayLayout.getAgentCardRect(handZone, screenHeight, assets)

    return {
        x = Pixel.snap(agentRect.x + agentRect.width / 2 - style.buttonWidth / 2),
        y = Pixel.snap(agentRect.y - style.buttonHeight - style.buttonGap),
        width = style.buttonWidth,
        height = style.buttonHeight,
    }
end

local function getGoLoudButtonRects(state, handZone, screenHeight)
    local style = BattleStyle.tagAction
    local rects = {}

    for _, slot in ipairs(TagLayout.getSlots(state, handZone, screenHeight)) do
        if not slot.isActive then
            local yOffset = TagLayout.getActionYOffset(state, slot)

            rects[#rects + 1] = {
                tagIndex = slot.index,
                x = Pixel.snap(slot.x + slot.size / 2 - style.buttonWidth / 2),
                y = Pixel.snap(slot.y + yOffset + slot.size + style.buttonGap),
                width = style.buttonWidth,
                height = style.buttonHeight,
            }
        end
    end

    return rects
end

local function hitTestRect(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height
end

function BattleView.hitTestTagAction(state, handZone, screenHeight, assets, x, y)
    if state.tagActionMode == "goSilent" then
        local rect = getGoSilentButtonRect(handZone, screenHeight, assets)

        if hitTestRect(rect, x, y) then
            return "goSilent", nil
        end
    elseif state.tagActionMode == "goLoud" then
        for _, rect in ipairs(getGoLoudButtonRects(state, handZone, screenHeight)) do
            if hitTestRect(rect, x, y) then
                return "goLoud", rect.tagIndex
            end
        end

        for _, slot in ipairs(TagLayout.getSlots(state, handZone, screenHeight)) do
            if not slot.isActive then
                local yOffset = TagLayout.getActionYOffset(state, slot)
                local rect = {
                    x = slot.x,
                    y = Pixel.snap(slot.y + yOffset),
                    width = slot.size,
                    height = slot.size,
                }

                if hitTestRect(rect, x, y) then
                    return "goLoud", slot.index
                end
            end
        end
    end

    return nil, nil
end

function BattleView.hitTestPhaseTracker(state, handZone, screenHeight, assets, x, y)
    return hitTestRect(getPhaseTrackerRect(state, handZone, screenHeight, assets), x, y)
end

function BattleView.hitTestActiveChampion(state, handZone, screenHeight, assets, x, y)
    local rect = getChampionCardRect(state, handZone, screenHeight, assets)

    return rect and hitTestRect(rect, x, y) or false
end

function BattleView.hitTestJaclDeployAction(state, handZone, screenHeight, assets, x, y)
    if not state.jaclDeployActionVisible or not state.activeJaclCard then
        return false, false
    end

    return hitTestRect(getJaclDeployButtonRect(state, handZone, screenHeight, assets), x, y),
        state:isJaclDeployAvailable()
end

function BattleView.hitTestActiveJacl(state, handZone, screenHeight, assets, x, y)
    if not state.activeJaclCard or state:getJaclSpawnProgress() <= 0 then
        return false
    end

    return hitTestRect(getJaclFootprintRect(state, handZone, screenHeight, assets), x, y)
end

local function drawTagActionButton(rect, label, assets, accent)
    local style = BattleStyle.tagAction
    local actionColor = accent or style.text

    love.graphics.setColor(style.fill)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 4, 4)

    love.graphics.setColor(actionColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 4, 4)

    love.graphics.setFont(assets.fonts.cardLabel)
    love.graphics.setColor(actionColor)
    love.graphics.printf(label, rect.x, Pixel.snap(rect.y + rect.height / 2 - assets.fonts.cardLabel:getHeight() / 2), rect.width, "center")
end

local function drawTagActionButtons(state, assets, handZone, screenHeight)
    local style = BattleStyle.tagAction

    if state.tagActionMode == "goSilent" then
        drawTagActionButton(getGoSilentButtonRect(handZone, screenHeight, assets), "Go Silent", assets, style.goSilent)
    elseif state.tagActionMode == "goLoud" then
        for _, rect in ipairs(getGoLoudButtonRects(state, handZone, screenHeight)) do
            drawTagActionButton(rect, "Go Loud", assets, style.goLoud)
        end
    end
end

function BattleView.draw(state, assets)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)

    setColor(BattleStyle.colors.background)
    love.graphics.rectangle("fill", 0, 0, width, height)

    local layoutCards = HandLayout.getCards(state, handZone, height)

    drawTroopZones(state, assets, handZone, height)

    if state.hostileSortieAttackAnimation then
        drawActiveAgentCard(state, assets, handZone, height)
        drawActiveChampionCard(state, assets, handZone, height)
    else
        drawActiveChampionCard(state, assets, handZone, height)
        drawActiveAgentCard(state, assets, handZone, height)
    end

    TagView.draw(state, assets, handZone, height)
    drawTagActionButtons(state, assets, handZone, height)
    drawJaclDeployAction(state, assets, handZone, height)
    drawPhaseTracker(state, assets, handZone, height)
    drawResourceBox(state, assets, handZone, height)

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

    drawResourceDiscardButtons(state, assets, layoutCards)
    drawResourceConversionEffects(state, assets)
    drawActiveJaclCard(state, assets, handZone, height)

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
    drawJaclFootprint(state, handZone, height, assets)
end

return BattleView
