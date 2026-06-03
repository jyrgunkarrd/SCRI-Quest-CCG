local BattleState = require("src.battle.battle_state")
local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local BattleView = require("src.battle.battle_view")
local HandLayout = require("src.battle.hand_layout")
local Zones = require("src.battle.zones")

local Battle = {}

local assets
local state

function Battle.load(loadedAssets)
    assets = loadedAssets
    love.math.setRandomSeed(os.time())
    state = BattleState.new({
        handSize = 20,
    })
end

function Battle.update(_dt)
end

function Battle.draw()
    BattleView.draw(state, assets)
end

local function scrollHand(delta)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local displayWidth = CardStyle.width * BattleStyle.hand.cardScale

    state:scrollHand(delta, handZone.width, displayWidth, BattleStyle.hand.spacing)
end

local function updateHoveredCard(x, y)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local handZone = Zones.getHandZone(width, height)
    local layoutCards = HandLayout.getCards(state, handZone, height)

    state:setHoveredHandIndex(HandLayout.hitTest(layoutCards, x, y))
end

function Battle.keypressed(key)
    if key == "left" then
        scrollHand(BattleStyle.hand.scrollSpeed)
        updateHoveredCard(love.mouse.getPosition())
    elseif key == "right" then
        scrollHand(-BattleStyle.hand.scrollSpeed)
        updateHoveredCard(love.mouse.getPosition())
    end
end

function Battle.wheelmoved(x, y)
    local delta = 0

    if math.abs(x) > math.abs(y) then
        delta = x * BattleStyle.hand.scrollSpeed
    else
        delta = y * BattleStyle.hand.scrollSpeed
    end

    scrollHand(delta)
    updateHoveredCard(love.mouse.getPosition())
end

function Battle.mousemoved(x, y)
    updateHoveredCard(x, y)
end

return Battle
