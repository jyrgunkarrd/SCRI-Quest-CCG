local BattleStyle = {
    colors = {
        background = { 0.08, 0.09, 0.11, 1 },
    },

    hand = {
        cardScale = 0.5,
        spacing = 122,
        edgeDrop = 30,
        maxRotation = 0.12,
        portraitBottomPadding = 26,
        scrollSpeed = 100,
        previewScale = 1,
        previewTopPadding = 52,
        previewAnimDuration = 0.12,
        previewStartScale = 0.975,
        previewStartYOffset = 18,
        previewShadowPad = 12,
        previewShadowAlpha = 0.1,
        previewShadowHeightRatio = 1.72,
        previewWipeEdgeWidth = 10,
        previewWipeEdgeAlpha = 0.18,
    },

    tag = {
        centerYOffset = 96,
        radiusX = 118,
        radiusY = 38,
        activeSize = 126,
        reserveSize = 82,
        framePad = 4,
        labelHeight = 24,
        rotationStep = 0.08,
        swapDuration = 0.16,

        colors = {
            active = { 0.18, 0.72, 1.0, 1 },
            reserve = { 0.45, 0.74, 1.0, 0.78 },
            fill = { 0.01, 0.018, 0.028, 0.88 },
            shadow = { 0, 0, 0, 0.35 },
            text = { 0.86, 0.94, 1.0, 1 },
        },
    },

    agentCard = {
        scale = 0.5,
        gapAboveTag = 12,
    },

    playZones = {
        gapFromAgent = 22,
        slotGap = 14,
        tabCount = 5,
        tabGap = 2,
        tabTopGap = 6,
        emptyFill = { 0.01, 0.018, 0.028, 0.3 },
        emptyStroke = { 0.45, 0.74, 1.0, 0.32 },
        validStroke = { 0.45, 1.0, 0.58, 0.55 },
        tabFill = { 0.02, 0.04, 0.06, 0.72 },
        occupiedTabFill = { 0.757, 0, 0, 0.86 },
        activeTabFill = { 0.18, 0.72, 1.0, 0.72 },
        tabText = { 0.86, 0.94, 1.0, 1 },
    },
}

return BattleStyle
