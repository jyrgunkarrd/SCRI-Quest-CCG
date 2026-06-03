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

function Input.mousepressed(scene, x, y, button, istouch, presses)
    if scene and scene.mousepressed then
        scene.mousepressed(x, y, button, istouch, presses)
    end
end

function Input.mousereleased(scene, x, y, button, istouch, presses)
    if scene and scene.mousereleased then
        scene.mousereleased(x, y, button, istouch, presses)
    end
end

return Input
