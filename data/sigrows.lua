-- data/sigrows.lua
-- signature row definitions

local sigrows = {

    --- Border Color Definitions ---

    {
        id = "fe",
        lrow = {
            slot1 = "Temple",
            slot2 = "Arsenal",
            slot3 = "Troop",
            slot4 = "Troop",
        },
        rrow = {
            slot1 = "Troop",
            slot2 = "Troop",
            slot3 = "Arsenal",
            slot4 = "Mission",
        },
    },

    {
        id = "pb",
        lrow = {
            slot1 = "Wild",
            slot2 = "Arsenal",
            slot3 = "Arsenal",
            slot4 = "Arsenal",
        },
        rrow = {
            slot1 = "Arsenal",
            slot2 = "Arsenal",
            slot3 = "Arsenal",
            slot4 = "Wild",
        },
    },

    {
        id = "hg",
        lrow = {
            slot1 = "Wild",
            slot2 = "Mission",
            slot3 = "Mission",
            slot4 = "Arsenal",
        },
        rrow = {
            slot1 = "Troop",
            slot2 = "Mission",
            slot3 = "Mission",
            slot4 = "Temple",
        },
    },
}

return sigrows
