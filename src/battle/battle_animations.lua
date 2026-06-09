local Animation = require("src.ui.animation")
local BattleStyle = require("src.battle.battle_style")
local CardView = require("src.cards.card_view")
local Pixel = require("src.pixel")
local PlayLayout = require("src.battle.play_layout")

local BattleAnimations = {}

local function getActionTimings(style)
    local impactTime = style.windupDuration + style.lungeDuration
    local returnStartTime = impactTime + style.impactHoldDuration
    local returnEndTime = returnStartTime + style.returnDuration

    return impactTime, returnStartTime, returnEndTime
end

local function getHostileMissionTimings()
    local style = BattleStyle.hostileMissionAction
    local impactTime, returnStartTime, returnEndTime = getActionTimings(style)

    return style, impactTime, returnStartTime, returnEndTime
end

local function getHostileSortieAttackTimings()
    local style = BattleStyle.hostileSortieAttack
    local impactTime, returnStartTime, returnEndTime = getActionTimings(style)

    return style, impactTime, returnStartTime, returnEndTime
end

local function updateImpactAnimation(animation, dt, impactTime, onImpact)
    if not animation then
        return nil, false
    end

    animation.elapsed = math.min(animation.duration, animation.elapsed + dt)

    if not animation.applied and animation.elapsed >= impactTime then
        if onImpact then
            onImpact(animation)
        end

        animation.applied = true
    end

    if animation.elapsed >= animation.duration then
        return nil, true
    end

    return animation, false
end

local function getImpactProgress(animation, impactTime, returnStartTime)
    if not animation then
        return nil
    end

    local flashDuration = math.max(0.001, returnStartTime - impactTime)

    if animation.elapsed < impactTime then
        return nil
    end

    return math.min(1, (animation.elapsed - impactTime) / flashDuration)
end

local function drawLungingChampion(animation, championCard, originRect, targetRect, assets, style, returnStartTime, returnEndTime)
    if not animation or not championCard or not originRect then
        return false
    end

    targetRect = targetRect or originRect

    local windupProgress = math.min(1, animation.elapsed / style.windupDuration)
    local lungeElapsed = animation.elapsed - style.windupDuration
    local lungeProgress = math.min(1, math.max(0, lungeElapsed / style.lungeDuration))
    local returnElapsed = animation.elapsed - returnStartTime
    local returnProgress = math.min(1, math.max(0, returnElapsed / style.returnDuration))
    local moveProgress = Animation.easeOutCubic(lungeProgress)

    if animation.elapsed >= returnStartTime then
        moveProgress = 1 - Animation.easeOutCubic(returnProgress)
    end

    local targetX = Pixel.snap(targetRect.x + targetRect.width / 2 - originRect.width / 2)
    local targetY = Pixel.snap(targetRect.y + targetRect.height / 2 - originRect.height / 2)
    local cardX = Pixel.snap(Animation.lerp(originRect.x, targetX, moveProgress))
    local cardY = Pixel.snap(Animation.lerp(originRect.y, targetY, moveProgress))
    local rotation = style.tilt * (1 - math.min(1, lungeProgress + returnProgress)) * windupProgress

    if animation.elapsed >= returnEndTime then
        cardX = originRect.x
        cardY = originRect.y
        rotation = 0
    end

    love.graphics.push()
    love.graphics.translate(Pixel.snap(cardX + originRect.width / 2), Pixel.snap(cardY + originRect.height / 2))
    love.graphics.rotate(rotation)
    CardView.drawCompactStats(championCard, Pixel.snap(-originRect.width / 2), Pixel.snap(-originRect.height / 2), {
        assets = assets,
        scale = originRect.scale,
    })
    love.graphics.pop()

    return true
end

function BattleAnimations.newHostileMission(targetCard, value, targetZoneId, trackType)
    return Animation.new(BattleStyle.hostileMissionAction.duration, {
        objectiveCard = targetCard,
        targetCard = targetCard,
        targetZoneId = targetZoneId or "upper_right_4",
        trackType = trackType or "progress",
        value = value,
        applied = false,
    })
end

function BattleAnimations.updateHostileMission(animation, dt, onImpact)
    local _, impactTime = getHostileMissionTimings()

    return updateImpactAnimation(animation, dt, impactTime, onImpact)
end

function BattleAnimations.getHostileMissionImpactProgress(animation)
    local style, impactTime, returnStartTime = getHostileMissionTimings()

    return getImpactProgress(animation, impactTime, returnStartTime)
end

function BattleAnimations.drawHostileMissionChampion(animation, championCard, rect, assets, handZone, screenHeight)
    local style, _, returnStartTime, returnEndTime = getHostileMissionTimings()
    local zones = PlayLayout.getTroopZones(handZone, screenHeight, assets)
    local targetZone = zones[animation and animation.targetZoneId or "upper_right_4"]

    return drawLungingChampion(animation, championCard, rect, targetZone, assets, style, returnStartTime, returnEndTime)
end

function BattleAnimations.drawHostileMissionObjectiveFlash(animation, zone, assets)
    local impactProgress = BattleAnimations.getHostileMissionImpactProgress(animation)

    if not impactProgress then
        return false
    end

    local style = BattleStyle.hostileMissionAction
    local alpha = 1 - impactProgress

    love.graphics.setColor(style.flashColor[1], style.flashColor[2], style.flashColor[3], 0.24 * alpha)
    love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height, 6, 6)

    love.graphics.setColor(style.flashStroke[1], style.flashStroke[2], style.flashStroke[3], 0.9 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", zone.x, zone.y, zone.width, zone.height, 6, 6)

    love.graphics.setFont(assets.fonts.body)
    love.graphics.setColor(style.flashStroke[1], style.flashStroke[2], style.flashStroke[3], alpha)
    love.graphics.printf(
        "+" .. tostring(animation.value or 0),
        zone.x,
        Pixel.snap(zone.y + zone.height / 2 - assets.fonts.body:getHeight() / 2 - impactProgress * 18),
        zone.width,
        "center"
    )

    return true
end

function BattleAnimations.newHostileSortieAttack(agentCard, value)
    return Animation.new(BattleStyle.hostileSortieAttack.duration, {
        agentCard = agentCard,
        value = value,
        applied = false,
    })
end

function BattleAnimations.updateHostileSortieAttack(animation, dt, onImpact)
    local _, impactTime = getHostileSortieAttackTimings()

    return updateImpactAnimation(animation, dt, impactTime, onImpact)
end

function BattleAnimations.getHostileSortieAttackImpactProgress(animation)
    local _, impactTime, returnStartTime = getHostileSortieAttackTimings()

    return getImpactProgress(animation, impactTime, returnStartTime)
end

function BattleAnimations.drawHostileSortieChampion(animation, championCard, originRect, targetRect, assets)
    local style, _, returnStartTime, returnEndTime = getHostileSortieAttackTimings()

    return drawLungingChampion(animation, championCard, originRect, targetRect, assets, style, returnStartTime, returnEndTime)
end

function BattleAnimations.drawHostileSortieAgentImpact(animation, agentCard, rect, assets)
    local impactProgress = BattleAnimations.getHostileSortieAttackImpactProgress(animation)

    if not animation or not agentCard or not rect then
        return false
    end

    local style = BattleStyle.hostileSortieAttack
    local jitterX = 0
    local alpha = 0

    if impactProgress then
        alpha = 1 - impactProgress
        jitterX = math.sin(animation.elapsed * style.jitterSpeed) * style.jitterAmount * alpha
    end

    local drawX = Pixel.snap(rect.x + jitterX)

    CardView.drawCompactStats(agentCard, drawX, rect.y, {
        assets = assets,
        scale = rect.scale,
    })

    if impactProgress then
        love.graphics.setColor(style.flashColor[1], style.flashColor[2], style.flashColor[3], 0.22 * alpha)
        love.graphics.rectangle("fill", drawX, rect.y, rect.width, rect.height, 6, 6)

        love.graphics.setColor(style.flashStroke[1], style.flashStroke[2], style.flashStroke[3], 0.9 * alpha)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", drawX, rect.y, rect.width, rect.height, 6, 6)

        love.graphics.setFont(assets.fonts.body)
        love.graphics.setColor(style.flashStroke[1], style.flashStroke[2], style.flashStroke[3], alpha)
        love.graphics.printf(
            "-" .. tostring(animation.value or 0),
            drawX,
            Pixel.snap(rect.y + rect.height / 2 - assets.fonts.body:getHeight() / 2 - impactProgress * 18),
            rect.width,
            "center"
        )
    end

    return true
end

return BattleAnimations
