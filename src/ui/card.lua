local Pixel = require("src.pixel")

local Card = {}

local function setColor(color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function drawImageFit(image, x, y, width, height)
    if not image then
        return false
    end

    local scale = math.min(width / image:getWidth(), height / image:getHeight())
    local drawWidth = image:getWidth() * scale
    local drawHeight = image:getHeight() * scale
    local drawX = Pixel.snap(x + (width - drawWidth) / 2)
    local drawY = Pixel.snap(y + (height - drawHeight) / 2)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)
    return true
end

function Card.drawPortrait(image, x, y, size, color)
    x, y, size = Pixel.snap(x), Pixel.snap(y), Pixel.snap(size)
    color = color or { 0.18, 0.72, 1.0, 1 }

    setColor({ 0.01, 0.015, 0.022, 1 }, 0.96)
    love.graphics.rectangle("fill", x, y, size, size, 6, 6)

    if not drawImageFit(image, x, y, size, size) then
        love.graphics.setColor(color[1], color[2], color[3], 0.85)
        love.graphics.setLineWidth(2)
        love.graphics.line(x + size * 0.25, y + size * 0.5, x + size * 0.75, y + size * 0.5)
        love.graphics.line(x + size * 0.5, y + size * 0.25, x + size * 0.5, y + size * 0.75)
    end
end

return Card
