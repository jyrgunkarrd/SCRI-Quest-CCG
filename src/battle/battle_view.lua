local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local CardView = require("src.cards.card_view")
local HandLayout = require("src.battle.hand_layout")
local Pixel = require("src.pixel")
local Zones = require("src.battle.zones")

local BattleView = {}

local function setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

function BattleView.draw(state, assets)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)

    setColor(BattleStyle.colors.background)
    love.graphics.rectangle("fill", 0, 0, width, height)

    local layoutCards = HandLayout.getCards(state, handZone, height)

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
        local previewScale = BattleStyle.hand.previewScale
        local previewWidth = CardStyle.width * previewScale
        local previewX = Pixel.snap((width - previewWidth) / 2)
        local previewY = BattleStyle.hand.previewTopPadding

        CardView.draw(hoveredCard, previewX, previewY, {
            assets = assets,
            scale = previewScale,
        })
    end
end

return BattleView
