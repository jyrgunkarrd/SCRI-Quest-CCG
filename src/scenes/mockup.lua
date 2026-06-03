local CardStyle = require("src.cards.card_style")
local CardView = require("src.cards.card_view")
local Panels = require("src.ui.panels")
local Pixel = require("src.pixel")
local mockCards = require("data.mockcard")

local Mockup = {}

local assets

function Mockup.load(loadedAssets)
    assets = loadedAssets
    love.graphics.setBackgroundColor(0.08, 0.09, 0.11)
end

function Mockup.update(_dt)
end

function Mockup.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    love.graphics.clear(0.08, 0.09, 0.11, 1)

    Panels.drawFrame(42, 36, width - 84, height - 72)

    local scale = 0.55
    local displayWidth = CardStyle.width * scale
    local displayHeight = CardStyle.height * scale
    local gapX = 24
    local gapY = 38
    local columns = 5
    local rows = 2
    local gridWidth = columns * displayWidth + (columns - 1) * gapX
    local gridHeight = rows * displayHeight + (rows - 1) * gapY
    local startX = Pixel.snap((width - gridWidth) / 2)
    local startY = Pixel.snap((height - gridHeight) / 2)

    for i, card in ipairs(mockCards) do
        if i > columns * rows then
            break
        end

        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        local x = startX + col * (displayWidth + gapX)
        local y = startY + row * (displayHeight + gapY)

        CardView.draw(card, x, y, {
            assets = assets,
            scale = scale,
        })
    end

    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(0.5, 0.8, 1, 0.85)
    love.graphics.print("temporary mockup scene - mockcard.lua grid", 64, height - 56)
end

function Mockup.keypressed(_key)
end

return Mockup
