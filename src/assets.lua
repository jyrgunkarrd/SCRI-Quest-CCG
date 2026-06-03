local Assets = {
    audio = {
        sfx = {},
    },
    fonts = {},
    images = {
        methods = {},
        signature = {},
        cards = {
            agents = {},
            mockup = {},
        },
        portraits = {},
    },
}

local Sfx = require("src.audio.sfx")

local function loadFont(path, size)
    if love.filesystem.getInfo(path) then
        return love.graphics.newFont(path, size)
    end

    return love.graphics.newFont(size)
end

local function loadImage(path, settings)
    if not love.filesystem.getInfo(path) then
        return nil
    end

    return love.graphics.newImage(path, settings)
end

local function loadBadgeImage(path)
    if not love.filesystem.getInfo(path) then
        return nil
    end

    local imageData = love.image.newImageData(path)
    local image = love.graphics.newImage(imageData)
    image:setFilter("nearest", "nearest")

    return image
end

local function loadPortraitImage(path)
    local image = loadImage(path, { mipmaps = true })

    if image then
        image:setFilter("linear", "linear")
        image:setMipmapFilter("linear", 1)
    end

    return image
end

local function getFileStem(filename)
    return filename:match("^(.*)%.[^%.]+$") or filename
end

local function loadImageDirectory(directory, target)
    if not love.filesystem.getInfo(directory) then
        return
    end

    for _, filename in ipairs(love.filesystem.getDirectoryItems(directory)) do
        local path = directory .. "/" .. filename
        local info = love.filesystem.getInfo(path)

        if info and info.type == "file" and filename:match("%.png$") then
            target[getFileStem(filename)] = loadPortraitImage(path)
        end
    end
end

function Assets.load()
    Assets.fonts.default = loadFont("assets/fonts/Furore.otf", 56)
    Assets.fonts.title = loadFont("assets/fonts/Furore.otf", 42)
    Assets.fonts.body = loadFont("assets/fonts/Furore.otf", 24)
    Assets.fonts.small = loadFont("assets/fonts/Furore.otf", 16)
    Assets.fonts.cardTitle = loadFont("assets/fonts/Furore.otf", 15)
    Assets.fonts.cardBody = loadFont("assets/fonts/Furore.otf", 12)
    Assets.fonts.cardLabel = loadFont("assets/fonts/Furore.otf", 13)
    Assets.fonts.cardSmall = loadFont("assets/fonts/Furore.otf", 9)
    Assets.fonts.cardTiny = loadFont("assets/fonts/Furore.otf", 7)

    love.graphics.setFont(Assets.fonts.default)

    Assets.images.cards.mockup.front = loadPortraitImage("assets/images/cards/mockup/MCKVIS.png")
    loadImageDirectory("assets/images/cards/agents", Assets.images.cards.agents)
    loadImageDirectory("assets/images/portraits", Assets.images.portraits)

    for name, image in pairs(Assets.images.portraits) do
        Assets.images.portraits[string.upper(name)] = Assets.images.portraits[string.upper(name)] or image
    end

    local methodNames = {
        "beast",
        "blade",
        "crusade",
        "gate",
        "inferno",
        "nightmare",
        "rampage",
        "shadow",
        "stitch",
        "trigger",
    }

    for _, name in ipairs(methodNames) do
        Assets.images.methods[name] = loadBadgeImage("assets/images/methods/" .. name .. ".png")
    end

    local signatureNames = { "au", "fe", "hg", "pb", "u" }

    for _, name in ipairs(signatureNames) do
        Assets.images.signature[name] = loadBadgeImage("assets/images/signature/" .. name .. ".png")
    end

    Assets.audio.sfx.cardHover = Sfx.load("assets/audio/cardhover.wav")
    Assets.audio.sfx.reject = Sfx.load("assets/audio/reject.wav")
end

return Assets
