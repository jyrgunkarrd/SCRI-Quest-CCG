local Pixel = {}

function Pixel.snap(value)
    return math.floor(value + 0.5)
end

function Pixel.snapRect(x, y, width, height)
    return Pixel.snap(x), Pixel.snap(y), Pixel.snap(width), Pixel.snap(height)
end

function Pixel.snapPoints(points)
    local snapped = {}

    for i, value in ipairs(points) do
        snapped[i] = Pixel.snap(value)
    end

    return snapped
end

return Pixel
