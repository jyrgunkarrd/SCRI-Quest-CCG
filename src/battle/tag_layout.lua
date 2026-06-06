local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local Animation = require("src.ui.animation")
local Pixel = require("src.pixel")

local TagLayout = {}

local SLOT_OFFSETS = {
    { position = "active", angle = -math.pi / 2, depth = 3 },
    { position = "left", angle = math.pi * 0.84, depth = 1 },
    { position = "right", angle = math.pi * 0.16, depth = 2 },
}

function TagLayout.getWheelCenter(handZone, screenHeight)
    local handPortraitBottom = CardStyle.portraitY + CardStyle.portraitSize
    local handBaseY = screenHeight - handPortraitBottom * BattleStyle.hand.cardScale - BattleStyle.hand.portraitBottomPadding
    local centerX = handZone.x + handZone.width / 2
    local centerY = handBaseY - BattleStyle.tag.centerYOffset

    return Pixel.snap(centerX), Pixel.snap(centerY)
end

local function getStaticSlots(tags, activeIndex, handZone, screenHeight)
    local slots = {}

    if #tags == 0 then
        return slots
    end

    local style = BattleStyle.tag
    local centerX, centerY = TagLayout.getWheelCenter(handZone, screenHeight)

    for slotIndex, offset in ipairs(SLOT_OFFSETS) do
        local tagIndex = ((activeIndex + slotIndex - 2) % #tags) + 1
        local baseSize = offset.position == "active" and style.activeSize or style.reserveSize
        local size = Pixel.snap(baseSize)
        local x = Pixel.snap(centerX + math.cos(offset.angle) * style.radiusX - size / 2)
        local y = Pixel.snap(centerY + math.sin(offset.angle) * style.radiusY - size / 2)

        slots[#slots + 1] = {
            index = tagIndex,
            tag = tags[tagIndex],
            position = offset.position,
            x = x,
            y = y,
            size = size,
            rotation = math.cos(offset.angle) * style.rotationStep,
            isActive = offset.position == "active",
            depth = offset.depth,
        }
    end

    table.sort(slots, function(a, b)
        return a.depth < b.depth
    end)

    return slots
end

local function mergeAnimatedSlots(sourceSlots, targetSlots, progress)
    local sourceByIndex = {}
    local slots = {}

    for _, slot in ipairs(sourceSlots) do
        sourceByIndex[slot.index] = slot
    end

    for _, target in ipairs(targetSlots) do
        local source = sourceByIndex[target.index] or target

        slots[#slots + 1] = {
            index = target.index,
            tag = target.tag,
            position = target.position,
            x = Pixel.snap(Animation.lerp(source.x, target.x, progress)),
            y = Pixel.snap(Animation.lerp(source.y, target.y, progress)),
            size = Pixel.snap(Animation.lerp(source.size, target.size, progress)),
            rotation = Animation.lerp(source.rotation, target.rotation, progress),
            isActive = target.isActive,
            depth = target.depth,
        }
    end

    table.sort(slots, function(a, b)
        return a.depth < b.depth
    end)

    return slots
end

function TagLayout.getSlots(state, handZone, screenHeight)
    local tags = state.tags or {}
    local targetSlots = getStaticSlots(tags, state.activeTagIndex or 1, handZone, screenHeight)
    local animation = state.tagSwapAnimation

    if not animation then
        return targetSlots
    end

    local sourceSlots = getStaticSlots(tags, animation.fromIndex or state.activeTagIndex or 1, handZone, screenHeight)

    return mergeAnimatedSlots(sourceSlots, targetSlots, Animation.easedProgress(animation))
end

function TagLayout.getActionYOffset(state, slot)
    if not state or state.tagActionMode ~= "goLoud" or not slot or slot.isActive then
        return 0
    end

    local style = BattleStyle.tagAction

    return math.sin(love.timer.getTime() * style.bobSpeed + slot.index * 0.55) * style.bobAmount
end

return TagLayout
