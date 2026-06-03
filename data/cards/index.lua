local cardSets = {
    require("data.cards.agents"),
    require("data.cards.mockcard"),
}

local cards = {}

for _, cardSet in ipairs(cardSets) do
    for _, card in ipairs(cardSet) do
        cards[#cards + 1] = card
    end
end

return cards
