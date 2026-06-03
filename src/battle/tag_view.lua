local BattleStyle = require("src.battle.battle_style")
local MethodColors = require("src.battle.method_colors")
local Pixel = require("src.pixel")
local TagLayout = require("src.battle.tag_layout")

local TagView = {}

local function setColor(color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function drawPortraitBackplate(x, y, width, height)
    setColor(BattleStyle.tag.colors.fill)
    love.graphics.rectangle("fill", x, y, width, height)
end

local function drawPortraitImage(image, x, y, width, height, alpha)
    if not image then
        setColor(BattleStyle.tag.colors.reserve, alpha)
        love.graphics.line(x + width * 0.28, y + height * 0.5, x + width * 0.72, y + height * 0.5)
        love.graphics.line(x + width * 0.5, y + height * 0.28, x + width * 0.5, y + height * 0.72)
        return
    end

    local scale = math.min(width / image:getWidth(), height / image:getHeight())
    local drawWidth = image:getWidth() * scale
    local drawHeight = image:getHeight() * scale
    local drawX = Pixel.snap(x + (width - drawWidth) / 2)
    local drawY = Pixel.snap(y + (height - drawHeight) / 2)

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)
end

local function getTagMethodColor(tag)
    return MethodColors.getCardColor(tag and tag.card, BattleStyle.tag.colors.active)
end

local function drawSlot(slot, assets)
    local style = BattleStyle.tag
    local pad = style.framePad
    local labelHeight = slot.isActive and style.labelHeight or 0
    local frameWidth = slot.size + pad * 2
    local frameHeight = slot.size + pad * 2 + labelHeight
    local frameX = Pixel.snap(slot.x - pad)
    local frameY = Pixel.snap(slot.y - pad)
    local alpha = slot.isActive and 1 or 0.72

    love.graphics.push()
    love.graphics.translate(Pixel.snap(frameX + frameWidth / 2), Pixel.snap(frameY + frameHeight / 2))
    love.graphics.rotate(slot.rotation)
    love.graphics.translate(Pixel.snap(-frameWidth / 2), Pixel.snap(-frameHeight / 2))

    setColor(style.colors.shadow)
    love.graphics.rectangle("fill", 4, 6, frameWidth, frameHeight)

    drawPortraitBackplate(0, 0, frameWidth, frameHeight)
    drawPortraitImage(assets.images.portraits[slot.tag.portrait], pad, pad, slot.size, slot.size, alpha)

    if not slot.isActive then
        love.graphics.setColor(0.01, 0.018, 0.028, 0.42)
        love.graphics.rectangle("fill", pad, pad, slot.size, slot.size)
    end

    if slot.isActive then
        local labelY = Pixel.snap(pad + slot.size - 1)
        local labelColor = getTagMethodColor(slot.tag)

        setColor(labelColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", pad, labelY, slot.size, labelHeight, 2, 2)

        love.graphics.setFont(assets.fonts.cardLabel)
        setColor(labelColor)
        love.graphics.printf("ACTIVE", pad, Pixel.snap(labelY + labelHeight / 2 - assets.fonts.cardLabel:getHeight() / 2), slot.size, "center")
    end

    love.graphics.pop()
end

function TagView.draw(state, assets, handZone, screenHeight)
    local slots = TagLayout.getSlots(state, handZone, screenHeight)

    for _, slot in ipairs(slots) do
        drawSlot(slot, assets)
    end
end

return TagView
