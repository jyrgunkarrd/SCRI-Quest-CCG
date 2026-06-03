local Input = {}

function Input.keypressed(scene, key)
    if key == "escape" then
        love.event.quit()
        return
    end

    if scene and scene.keypressed then
        scene.keypressed(key)
    end
end

function Input.wheelmoved(scene, x, y)
    if scene and scene.wheelmoved then
        scene.wheelmoved(x, y)
    end
end

function Input.mousemoved(scene, x, y, dx, dy, istouch)
    if scene and scene.mousemoved then
        scene.mousemoved(x, y, dx, dy, istouch)
    end
end

return Input
