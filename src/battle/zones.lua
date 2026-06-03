local Zones = {}

function Zones.getHandZone(width, height)
    return {
        x = 0,
        y = height * 0.70,
        width = width,
        height = height * 0.30,
    }
end

return Zones
