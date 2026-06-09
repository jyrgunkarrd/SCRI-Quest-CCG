-- data/cards/landmarks.lua
-- landmark card definitions

local landmarks = {


    {
        id = "VECGEN",
        name = "Vector Genomics",
        cost = 0,
        type = "Landmark",
        tags = {
            "Facility",
            "Research",
            "Biotechnology",
        },
        control = {
           { track = 2 },
           { limit = 4 },
        },
        body = "This is a visual mockup of a card. It is not a real card.",
    },

}

return landmarks