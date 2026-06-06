local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local CardView = require("src.cards.card_view")
local Pixel = require("src.pixel")
local TagLayout = require("src.battle.tag_layout")

local PlayLayout = {}

local orderedTroopZoneIds = {
    "upper_left_4",
    "upper_left_3",
    "upper_left_2",
    "upper_left_1",
    "upper_right_1",
    "upper_right_2",
    "upper_right_3",
    "upper_right_4",
    "left_4",
    "left_3",
    "left_2",
    "left_1",
    "right_1",
    "right_2",
    "right_3",
    "right_4",
}

function PlayLayout.getOrderedTroopZoneIds()
    return orderedTroopZoneIds
end

function PlayLayout.isInnerPlayerZone(zoneId)
    return zoneId == "left_1" or zoneId == "right_1"
end

function PlayLayout.getCompactCardSize(scale, assets)
    return {
        width = Pixel.snap(CardStyle.width * scale),
        height = Pixel.snap(CardView.getCompactStatsHeight(scale, assets)),
    }
end

function PlayLayout.getAgentCardRect(handZone, screenHeight, assets)
    local centerX, centerY = TagLayout.getWheelCenter(handZone, screenHeight)
    local scale = BattleStyle.agentCard.scale
    local size = PlayLayout.getCompactCardSize(scale, assets)
    local tagTop = centerY - BattleStyle.tag.radiusY - BattleStyle.tag.activeSize / 2 - BattleStyle.tag.framePad

    return {
        x = Pixel.snap(centerX - size.width / 2),
        y = Pixel.snap(tagTop - BattleStyle.agentCard.gapAboveTag - size.height),
        width = size.width,
        height = size.height,
        scale = scale,
    }
end

function PlayLayout.getTroopZones(handZone, screenHeight, assets)
    local agentRect = PlayLayout.getAgentCardRect(handZone, screenHeight, assets)
    local gap = BattleStyle.playZones.gapFromAgent
    local slotGap = BattleStyle.playZones.slotGap
    local step = agentRect.width + slotGap
    local leftInnerX = agentRect.x - gap - agentRect.width
    local rightInnerX = agentRect.x + agentRect.width + gap
    local tabCount = BattleStyle.playZones.tabCount
    local tabGap = BattleStyle.playZones.tabGap
    local tabWidth = Pixel.snap((agentRect.width - (tabCount - 1) * tabGap) / tabCount)
    local upperY = Pixel.snap(agentRect.y - agentRect.height - BattleStyle.playZones.tabTopGap - tabWidth - BattleStyle.playZones.rowGap)

    return {
        upper_left_4 = {
            id = "upper_left_4",
            x = Pixel.snap(leftInnerX - step * 3),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_left_3 = {
            id = "upper_left_3",
            x = Pixel.snap(leftInnerX - step * 2),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_left_2 = {
            id = "upper_left_2",
            x = Pixel.snap(leftInnerX - step),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_left_1 = {
            id = "upper_left_1",
            x = Pixel.snap(leftInnerX),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_right_1 = {
            id = "upper_right_1",
            x = Pixel.snap(rightInnerX),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_right_2 = {
            id = "upper_right_2",
            x = Pixel.snap(rightInnerX + step),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_right_3 = {
            id = "upper_right_3",
            x = Pixel.snap(rightInnerX + step * 2),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        upper_right_4 = {
            id = "upper_right_4",
            x = Pixel.snap(rightInnerX + step * 3),
            y = upperY,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        left_4 = {
            id = "left_4",
            x = Pixel.snap(leftInnerX - step * 3),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        left_3 = {
            id = "left_3",
            x = Pixel.snap(leftInnerX - step * 2),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        left_2 = {
            id = "left_2",
            x = Pixel.snap(leftInnerX - step),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        left_1 = {
            id = "left_1",
            x = Pixel.snap(leftInnerX),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        right_1 = {
            id = "right_1",
            x = Pixel.snap(rightInnerX),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        right_2 = {
            id = "right_2",
            x = Pixel.snap(rightInnerX + step),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        right_3 = {
            id = "right_3",
            x = Pixel.snap(rightInnerX + step * 2),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
        right_4 = {
            id = "right_4",
            x = Pixel.snap(rightInnerX + step * 3),
            y = agentRect.y,
            width = agentRect.width,
            height = agentRect.height,
            scale = agentRect.scale,
        },
    }
end

function PlayLayout.hitTestTroopZones(zones, x, y)
    for id, zone in pairs(zones) do
        if x >= zone.x and x <= zone.x + zone.width and y >= zone.y and y <= zone.y + zone.height then
            return id
        end
    end

    return nil
end

function PlayLayout.getAcceptedTypeLabelHeight(zone, assets)
    if zone.id and zone.id:match("^upper_") then
        return 0
    end

    return assets and assets.fonts.cardSmall:getHeight() + 6 or 15
end

function PlayLayout.getTabRects(zone, assets)
    local rects = {}
    local tabCount = BattleStyle.playZones.tabCount
    local tabGap = BattleStyle.playZones.tabGap
    local totalGap = (tabCount - 1) * tabGap
    local tabWidth = Pixel.snap((zone.width - totalGap) / tabCount)
    local tabHeight = tabWidth
    local tabY = Pixel.snap(zone.y + zone.height + BattleStyle.playZones.tabTopGap + PlayLayout.getAcceptedTypeLabelHeight(zone, assets))

    for i = 1, tabCount do
        rects[i] = {
            x = Pixel.snap(zone.x + (i - 1) * (tabWidth + tabGap)),
            y = tabY,
            width = tabWidth,
            height = tabHeight,
        }
    end

    return rects
end

function PlayLayout.hitTestZoneTabs(zones, x, y, assets)
    for zoneId, zone in pairs(zones) do
        for tabIndex, rect in ipairs(PlayLayout.getTabRects(zone, assets)) do
            if x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height then
                return zoneId, tabIndex
            end
        end
    end

    return nil, nil
end

function PlayLayout.hitTestRect(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height
end

return PlayLayout
