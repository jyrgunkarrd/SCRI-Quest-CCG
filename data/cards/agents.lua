-- data/cards/agents.lua
-- agent card definition

local agents = {

    --- Visual Card Mockup ---

    {
        id = "MAM",
        name = "Mammoth",
        method = {
            { type = "beast", value = 1 },
        },
        cost = 0,
        sig = "fe",
        type = "Agent",
        tags = {
            "Oni",
            "Tacskin",
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

    {
        id = "B6",
        name = "Betty Six",
        method = {
            { type = "trigger", value = 1 },
        },
        cost = 0,
        sig = "pb",
        type = "Agent",
        tags = {
            "Augs",
            "Soldier",
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

    {
        id = "BMNCH",
        name = "Big Munch",
        method = {
            { type = "rampage", value = 1 },
        },
        cost = 2,
        sig = "hg",
        type = "Agent",
        tags = {
            "Experiment",
            "Tacskin",
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

return agents