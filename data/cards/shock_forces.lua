-- data/cards/shock_forces.lua
-- shock_forces card definition

local shock_forces = {

    {
        id = "SFSKY",
        name = "Skywolf",
        cost = 0,
        type = "Shock Forces",
        tags = {
            "Robotic",
            "Drone",
            "Aircraft",
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

return shock_forces