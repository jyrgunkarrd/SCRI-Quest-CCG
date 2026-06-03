local BattleStyle = require("src.battle.battle_style")
local CardStyle = require("src.cards.card_style")
local Pixel = require("src.pixel")

local HandLayout = {}

function HandLayout.getCards(state, handZone, screenHeight)
    local hand = state.hand or {}
    local count = #hand
    local cards = {}

    if count == 0 then
        return cards
    end

    local scale = BattleStyle.hand.cardScale
    local displayWidth = CardStyle.width * scale
    local displayHeight = CardStyle.height * scale
    local portraitBottom = CardStyle.portraitY + CardStyle.portraitSize
    local centerX = handZone.x + handZone.width / 2
    local baseY = screenHeight - portraitBottom * scale - BattleStyle.hand.portraitBottomPadding
    local spacing = BattleStyle.hand.spacing
    local totalWidth = displayWidth + (count - 1) * spacing

    state:clampHandScroll(handZone.width, displayWidth, spacing)

    local startX = centerX - totalWidth / 2 + state.handScrollX

    for i, card in ipairs(hand) do
        local t = count == 1 and 0 or (i - 1) / (count - 1) * 2 - 1
        local x = Pixel.snap(startX + (i - 1) * spacing)
        local y = Pixel.snap(baseY + math.abs(t) * BattleStyle.hand.edgeDrop)
        local rotation = t * BattleStyle.hand.maxRotation

        cards[i] = {
            index = i,
            card = card,
            x = x,
            y = y,
            rotation = rotation,
            scale = scale,
            width = displayWidth,
            height = displayHeight,
            bounds = {
                x = x,
                y = y,
                width = displayWidth,
                height = displayHeight,
            },
        }
    end

    return cards
end

function HandLayout.hitTest(layoutCards, x, y)
    for i = #layoutCards, 1, -1 do
        local bounds = layoutCards[i].bounds

        if x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height then
            return layoutCards[i].index
        end
    end

    return nil
end

return HandLayout
