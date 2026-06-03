local CardPortrait = require("src.ui.card")
local Pixel = require("src.pixel")
local Style = require("src.cards.card_style")
local borderColors = require("data.bordercolors")

local CardView = {}

local function setColor(color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function addMethodEntry(entries, name, count)
    count = count or 1

    if name and count > 0 then
        entries[#entries + 1] = {
            name = string.lower(tostring(name):match("^%s*(.-)%s*$")),
            count = count,
        }
    end
end

local function getMethodEntries(card)
    local entries = {}
    local method = card.method

    if type(method) == "string" then
        addMethodEntry(entries, method, card.methodValue or card.methodCount or 1)
    elseif type(method) == "table" then
        for key, value in pairs(method) do
            if type(key) == "string" and type(value) == "number" then
                addMethodEntry(entries, key, value)
            elseif type(value) == "string" then
                addMethodEntry(entries, value, 1)
            elseif type(value) == "table" then
                addMethodEntry(entries, value.name or value.id or value.method or value.type, value.value or value.count or 1)
            end
        end
    end

    return entries
end

local function countMethodIcons(entries)
    local total = 0

    for _, entry in ipairs(entries) do
        total = total + entry.count
    end

    return total
end

local function hexToColor(hex)
    hex = tostring(hex or ""):gsub("#", "")

    if #hex ~= 6 then
        return nil
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    if not r or not g or not b then
        return nil
    end

    return { r / 255, g / 255, b / 255, 1 }
end

local function getMethodColorMap()
    local map = {}

    for _, definition in ipairs(borderColors) do
        for _, methodColor in ipairs(definition.methodcolors or {}) do
            if methodColor.type and methodColor.color then
                map[string.lower(methodColor.type)] = hexToColor(methodColor.color)
            end
        end
    end

    return map
end

local methodColorMap = getMethodColorMap()

local function getCardBorderColor(card)
    local methodEntries = getMethodEntries(card)

    for _, entry in ipairs(methodEntries) do
        local color = methodColorMap[entry.name]

        if color then
            return color
        end
    end

    return Style.colors.fallbackBorder
end

local function drawIconBadge(entries, imageSet, x, y, iconSize, iconGap, pad, borderColor, font)
    local iconCount = countMethodIcons(entries)
    local badgeWidth = iconCount * iconSize + math.max(0, iconCount - 1) * iconGap + pad * 2
    local badgeHeight = iconSize + pad * 2

    setColor(Style.colors.panelFill)
    love.graphics.rectangle("fill", x, y, badgeWidth, badgeHeight, 5, 5)

    setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, badgeWidth, badgeHeight, 5, 5)

    local iconX = Pixel.snap(x + pad)
    local iconY = Pixel.snap(y + pad)

    for _, entry in ipairs(entries) do
        for _ = 1, entry.count do
            local icon = imageSet[entry.name]

            love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 0.18)
            love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize, 3, 3)

            if icon then
                local scale = math.min(iconSize / icon:getWidth(), iconSize / icon:getHeight())
                local iconWidth = icon:getWidth() * scale
                local iconHeight = icon:getHeight() * scale
                local drawX = Pixel.snap(iconX + (iconSize - iconWidth) / 2)
                local drawY = Pixel.snap(iconY + (iconSize - iconHeight) / 2)

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(icon, drawX, drawY, 0, scale, scale)
            else
                setColor(borderColor)
                love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize, 3, 3)
                love.graphics.setFont(font)
                setColor(Style.colors.black)
                love.graphics.printf(string.sub(entry.name, 1, 1), iconX, iconY + 10, iconSize, "center")
            end

            iconX = Pixel.snap(iconX + iconSize + iconGap)
        end
    end

    return badgeWidth, badgeHeight
end

function CardView.draw(card, x, y, options)
    options = options or {}
    local assets = options.assets
    local scale = options.scale or 1

    love.graphics.push()
    love.graphics.translate(Pixel.snap(x), Pixel.snap(y))
    love.graphics.scale(scale, scale)

    local portraitSize = Style.portraitSize
    local portraitX = Style.portraitX
    local portraitY = Style.portraitY
    local statBadges = card.statblock or {}
    local hasHealth = card.health ~= nil
    local hasStats = #statBadges > 0
    local hasValueBadges = hasHealth or hasStats
    local healthBadgeWidth = Style.valueBadge.width
    local healthBadgeHeight = Style.valueBadge.height
    local healthHeaderHeight = assets.fonts.cardLabel:getHeight()
    local healthHeaderY = Pixel.snap(portraitY + portraitSize + Style.valueBadge.rowGap)
    local healthBadgeY = Pixel.snap(healthHeaderY + healthHeaderHeight + Style.valueBadge.headerGap)
    local bodyX = portraitX
    local badgeBodyY = Pixel.snap(healthBadgeY + healthBadgeHeight + Style.body.gap)
    local noBadgeBodyY = Pixel.snap(portraitY + portraitSize + Style.body.gap)
    local nameY = Pixel.snap(portraitY - assets.fonts.body:getHeight() - 20)
    local frameX = Pixel.snap(portraitX - Style.framePad)
    local frameY = Pixel.snap(nameY - 18)
    local methodIconSize = Style.methodBadge.iconSize
    local methodIconGap = Style.methodBadge.iconGap
    local methodPad = Style.methodBadge.pad
    local signatureBadgeWidth = methodIconSize + methodPad * 2
    local cardBottom = Pixel.snap(badgeBodyY + Style.body.baseHeight + Style.framePad)
    local signatureBadgeX = Pixel.snap(frameX + 8)
    local signatureBadgeY = Pixel.snap(cardBottom - signatureBadgeWidth - 8)
    local bodyBottom = Pixel.snap(signatureBadgeY - 8)
    local bodyY = hasValueBadges and badgeBodyY or noBadgeBodyY
    local bodyHeight = Pixel.snap(bodyBottom - bodyY)
    local pipCount = card.cost or 0
    local frameWidth = Pixel.snap(portraitSize + Style.framePad * 2)
    local frameHeight = Pixel.snap(cardBottom - frameY)
    local borderColor = getCardBorderColor(card)

    setColor(Style.colors.frameFill)
    love.graphics.rectangle("fill", frameX, frameY, frameWidth, frameHeight, 8, 8)

    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 0.28)
    love.graphics.setLineWidth(8)
    love.graphics.rectangle("line", frameX, frameY, frameWidth, frameHeight, 8, 8)

    setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", frameX, frameY, frameWidth, frameHeight, 8, 8)

    local pipRowWidth = pipCount * Style.cost.pipWidth + math.max(0, pipCount - 1) * Style.cost.pipGap
    local pipStartX = Pixel.snap(portraitX + portraitSize / 2 - pipRowWidth / 2)
    local pipY = frameY
    local pipHeight = Pixel.snap((nameY - frameY) / 2) + 2

    setColor(borderColor)
    for i = 1, pipCount do
        local pipX = Pixel.snap(pipStartX + (i - 1) * (Style.cost.pipWidth + Style.cost.pipGap))
        love.graphics.rectangle("fill", pipX, pipY, Style.cost.pipWidth, pipHeight, 2, 2)
    end

    CardPortrait.drawPortrait(assets.images.cards.mockup.front, portraitX, portraitY, portraitSize, borderColor)

    local methodEntries = getMethodEntries(card)
    local signatureEntries = {}
    local methodBadgeHeight = methodIconSize + methodPad * 2
    local methodIconCount = countMethodIcons(methodEntries)
    local methodBadgeWidth = methodIconCount * methodIconSize + math.max(0, methodIconCount - 1) * methodIconGap + methodPad * 2
    local methodBadgeY = Pixel.snap(nameY - 2)

    addMethodEntry(signatureEntries, card.sig, 1)
    drawIconBadge(methodEntries, assets.images.methods, portraitX, methodBadgeY, methodIconSize, methodIconGap, methodPad, borderColor, assets.fonts.cardSmall)

    love.graphics.setFont(assets.fonts.body)
    setColor(Style.colors.headerText)
    love.graphics.print(
        card.name,
        Pixel.snap(portraitX + methodBadgeWidth + 12),
        Pixel.snap(methodBadgeY + methodBadgeHeight / 2 - assets.fonts.body:getHeight() / 2)
    )

    local statGroupWidth = #statBadges * healthBadgeWidth + math.max(0, #statBadges - 1) * Style.valueBadge.statGap
    local statGroupX = Pixel.snap(portraitX + portraitSize - statGroupWidth)

    local function drawValueBadge(label, value, exValue, badgeX)
        badgeX = Pixel.snap(badgeX)

        local isStatblock = label ~= "HP"
        local statColor = isStatblock and Style.colors.valueRed or nil
        local headerColor = isStatblock and Style.colors.white or Style.colors.headerText
        local fillColor = isStatblock and Style.colors.black or Style.colors.valueRed
        local isSplit = isStatblock and exValue ~= nil
        local halfWidth = Pixel.snap(healthBadgeWidth / 2)
        local valueY = Pixel.snap(healthBadgeY + healthBadgeHeight / 2 - assets.fonts.body:getHeight() / 2) - 1

        love.graphics.setFont(assets.fonts.cardLabel)
        setColor(headerColor)
        love.graphics.printf(label, badgeX, healthHeaderY, healthBadgeWidth, "center")

        setColor(fillColor)
        if isSplit then
            love.graphics.rectangle("fill", badgeX, healthBadgeY, halfWidth, healthBadgeHeight, 5, 5)

            setColor(Style.colors.valueRed)
            love.graphics.rectangle("fill", badgeX + halfWidth, healthBadgeY, healthBadgeWidth - halfWidth, healthBadgeHeight, 5, 5)

            love.graphics.setColor(0.01, 0.015, 0.022, 0.75)
            love.graphics.rectangle("fill", badgeX + halfWidth - 1, healthBadgeY, 2, healthBadgeHeight)
        else
            love.graphics.rectangle("fill", badgeX, healthBadgeY, healthBadgeWidth, healthBadgeHeight, 5, 5)
        end

        if statColor then
            setColor(statColor)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", badgeX, healthBadgeY, healthBadgeWidth, healthBadgeHeight, 5, 5)
        end

        love.graphics.setFont(assets.fonts.body)
        setColor(Style.colors.white)
        love.graphics.printf(tostring(value or 0), badgeX, valueY, isSplit and halfWidth or healthBadgeWidth, "center")

        if isSplit then
            setColor(Style.colors.white)
            love.graphics.printf(tostring(exValue or 0), badgeX + halfWidth, valueY, healthBadgeWidth - halfWidth, "center")
        end
    end

    if hasHealth then
        drawValueBadge("HP", card.health, card.ex or card.healthEx, portraitX)
    end

    if hasStats then
        for i, stat in ipairs(statBadges) do
            drawValueBadge(stat.type, stat.value, stat.ex or stat.EX, statGroupX + (i - 1) * (healthBadgeWidth + Style.valueBadge.statGap))
        end
    end

    setColor(Style.colors.panelFill)
    love.graphics.rectangle("fill", bodyX, bodyY, portraitSize, bodyHeight, 6, 6)

    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 0.25)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bodyX, bodyY, portraitSize, bodyHeight, 6, 6)

    local tagWidths = {}
    local tagRowWidth = 0

    love.graphics.setFont(assets.fonts.cardBody)
    for i, tag in ipairs(card.tags or {}) do
        local tagWidth = Pixel.snap(assets.fonts.cardBody:getWidth(tag) + 16)
        tagWidths[i] = tagWidth
        tagRowWidth = tagRowWidth + tagWidth

        if i > 1 then
            tagRowWidth = tagRowWidth + Style.body.tagGap
        end
    end

    local tagX = Pixel.snap(bodyX + portraitSize / 2 - tagRowWidth / 2)
    local tagY = bodyY + 18

    for i, tag in ipairs(card.tags or {}) do
        local tagWidth = tagWidths[i]

        setColor(Style.colors.white)
        love.graphics.rectangle("fill", tagX, tagY, tagWidth, Style.body.tagHeight)

        setColor(Style.colors.black)
        love.graphics.printf(tag, tagX, Pixel.snap(tagY + Style.body.tagHeight / 2 - assets.fonts.cardBody:getHeight() / 2), tagWidth, "center")

        tagX = Pixel.snap(tagX + tagWidth + Style.body.tagGap)
    end

    love.graphics.setFont(assets.fonts.cardBody)
    setColor(Style.colors.bodyText)
    love.graphics.printf(card.body or "", bodyX + 22, bodyY + 56, portraitSize - 44, "left")

    love.graphics.setFont(assets.fonts.cardLabel)
    setColor(Style.colors.white)
    love.graphics.printf(
        card.type or "",
        portraitX,
        Pixel.snap(signatureBadgeY + signatureBadgeWidth / 2 - assets.fonts.cardLabel:getHeight() / 2),
        portraitSize,
        "center"
    )

    drawIconBadge(signatureEntries, assets.images.signature, signatureBadgeX, signatureBadgeY, methodIconSize, methodIconGap, methodPad, borderColor, assets.fonts.cardSmall)

    love.graphics.pop()
end

return CardView
