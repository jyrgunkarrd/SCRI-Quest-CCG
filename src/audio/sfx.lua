local Sfx = {}

Sfx.volume = 0.75

function Sfx.load(path, kind)
    if not love.filesystem.getInfo(path) then
        return nil
    end

    local source = love.audio.newSource(path, kind or "static")
    source:setVolume(Sfx.volume)

    return source
end

function Sfx.play(source, volume)
    if not source then
        return
    end

    local instance = source:clone()
    instance:setVolume(volume or source:getVolume())
    instance:play()
end

return Sfx
