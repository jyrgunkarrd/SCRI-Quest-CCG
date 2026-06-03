local Assets = require("src.assets")
local Battle = require("src.scenes.battle")
local Input = require("src.input")

local currentScene = Battle

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setLineJoin("miter")
    Assets.load()

    if currentScene.load then
        currentScene.load(Assets)
    end
end

function love.update(dt)
    if currentScene.update then
        currentScene.update(dt)
    end
end

function love.draw()
    if currentScene.draw then
        currentScene.draw()
    end
end

function love.keypressed(key)
    Input.keypressed(currentScene, key)
end

function love.wheelmoved(x, y)
    Input.wheelmoved(currentScene, x, y)
end

function love.mousemoved(x, y, dx, dy, istouch)
    Input.mousemoved(currentScene, x, y, dx, dy, istouch)
end
