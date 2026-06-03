local Pixel = require("src.pixel")

local Panels = {}

function Panels.drawFrame(x, y, width, height)
    x, y, width, height = Pixel.snapRect(x, y, width, height)

    local cut = Pixel.snap(36)
    local points = {
        x + cut, y,
        x + width - cut, y,
        x + width, y + cut,
        x + width, y + height - cut,
        x + width - cut, y + height,
        x + cut, y + height,
        x, y + height - cut,
        x, y + cut,
    }

    love.graphics.setColor(0.02, 0.04, 0.06, 0.45)
    love.graphics.polygon("fill", Pixel.snapPoints(points))

    love.graphics.setColor(0.18, 0.72, 1.0, 0.35)
    love.graphics.setLineWidth(6)
    love.graphics.polygon("line", Pixel.snapPoints(points))

    love.graphics.setColor(0.18, 0.72, 1.0, 0.95)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", Pixel.snapPoints(points))
end

return Panels
