-- data/cards/line_forces.lua
-- line_forces card definition

local line_forces = {

    --- Visual Card Mockup ---

    {
        id = "LFEXT",
        name = "Exterminator",
        cost = 0,
        type = "Line Forces",
        tags = {
            "Robotic",
            "Relic",
        },
        statblock = {
            { type = "ATK", value = 2, ex = 1 },
            { type = "OPS", value = 2, ex = 1 },
            { type = "SEC", value = 2, ex = 1 },
            { type = "TAC", value = 2, ex = 1 },
        },
        health = 2,
        body = "This is a visual mockup of a card. It is not a real card.",
    },

}

return line_forces