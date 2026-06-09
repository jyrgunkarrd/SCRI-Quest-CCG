-- data/cards/champions.lua
-- champion card definition

local champions = {


    {
        id = "PAM",
        name = "PAM",
        cost = 0,
        type = "Champion",
        tags = {
            "Robotic",
            "Relic",
        },
        statblock = {
            { type = "ATK", value = 2 },
            { type = "OPS", value = 2 },
            { type = "SEC", value = 2 },
            { type = "TAC", value = 2 },
        },
        health = 2,
        body = "This is a visual mockup of a card. It is not a real card.",
        objective = "NANSPAC",
    },

}

return champions