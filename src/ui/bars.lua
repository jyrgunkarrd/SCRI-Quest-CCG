local Pixel = require("src.pixel")

local Bars = {}

function Bars.drawStatusBar(x, y, width, height, fill, color)
    x, y, width, height = Pixel.snapRect(x, y, width, height)

    local r, g, b, a = color[1], color[2], color[3], color[4] or 1
    local fillWidth = Pixel.snap(math.max(0, math.min(1, fill)) * width)

    love.graphics.setColor(0.02, 0.03, 0.04, 0.9)
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)

    love.graphics.setColor(r, g, b, 0.95 * a)
    love.graphics.rectangle("fill", x + 3, y + 3, fillWidth - 6, height - 6, 3, 3)

    love.graphics.setColor(r, g, b, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 4, 4)
end

return Bars
