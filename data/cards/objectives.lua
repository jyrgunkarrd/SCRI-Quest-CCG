-- data/cards/objectives.lua
-- objective card definitions

local objectives = {


    {
        id = "NANSPAC",
        name = "St. Nancy\nSpace Center",
        cost = 0,
        type = "Objective",
        tags = {
            "Facility",
            "Ruin",
        },
        progress = {
           { track = 2 },
           { limit = 3 },
        },
        body = "This is a visual mockup of a card. It is not a real card.",
    },

}

return objectives