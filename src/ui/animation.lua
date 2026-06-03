local Animation = {}

function Animation.new(duration, data)
    data = data or {}
    data.elapsed = 0
    data.duration = duration or 0.16

    return data
end

function Animation.update(animation, dt)
    if not animation then
        return nil
    end

    animation.elapsed = math.min(animation.duration, animation.elapsed + dt)

    if animation.elapsed >= animation.duration then
        return nil
    end

    return animation
end

function Animation.progress(animation)
    if not animation or animation.duration <= 0 then
        return 1
    end

    return math.min(1, animation.elapsed / animation.duration)
end

function Animation.easeOutCubic(t)
    local inverse = 1 - t

    return 1 - inverse * inverse * inverse
end

function Animation.easedProgress(animation)
    return Animation.easeOutCubic(Animation.progress(animation))
end

function Animation.lerp(from, to, t)
    return from + (to - from) * t
end

return Animation
