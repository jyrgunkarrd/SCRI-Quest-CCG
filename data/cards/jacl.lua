-- data/cards/jacl.lua
-- jacl card definitions

local jacls = {

    --- Visual Card Mockup ---

    {
        id = "val",
        name = "JACL-S3D2 VALSHAMR",
        method = {
            { type = "gate", value = 1 },
        },
        cost = 0,
        sig = "hg",
        type = "JACL",
        tags = {
            "Carrier",
            "Cybernetic",
            "Vehicle",
        },
        body = "This is a visual mockup of a card. It is not a real card.",
    },

    {
        id = "mj",
        name = "JACL-S1D0 MJOLNIR",
        method = {
            { type = "trigger", value = 1 },
        },
        cost = 0,
        sig = "pb",
        type = "JACL",
        tags = {
            "Artillery",
            "Cybernetic",
            "Vehicle",
        },
        body = "This is a visual mockup of a card. It is not a real card.",
    },

    {
        id = "sur",
        name = "JACL-S4D7 SURTUR",
        method = {
            { type = "inferno", value = 1 },
        },
        cost = 0,
        sig = "fe",
        type = "JACL",
        tags = {
            "Incendiary",
            "Cybernetic",
            "Vehicle",
        },
        body = "This is a visual mockup of a card. It is not a real card.",
    },

}

return jacls
