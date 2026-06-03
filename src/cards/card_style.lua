local CardStyle = {
    width = 378,
    height = 830,

    portraitSize = 330,
    portraitX = 24,
    portraitY = 88,

    framePad = 24,

    cost = {
        pipWidth = 12,
        pipGap = 7,
    },

    methodBadge = {
        iconSize = 32,
        iconGap = 6,
        pad = 6,
    },

    valueBadge = {
        width = 56,
        height = 34,
        headerGap = 8,
        rowGap = 12,
        statGap = 8,
    },

    body = {
        gap = 14,
        baseHeight = 238,
        tagGap = 8,
        tagHeight = 24,
    },

    colors = {
        fallbackBorder = { 0.659, 0.843, 0.941, 1 },
        frameFill = { 0.015, 0.025, 0.035, 0.96 },
        panelFill = { 0.01, 0.015, 0.022, 0.94 },
        valueRed = { 0.757, 0, 0, 1 },
        bodyText = { 0.84, 0.9, 0.96, 1 },
        headerText = { 0.9, 0.95, 1, 1 },
        white = { 1, 1, 1, 1 },
        black = { 0, 0, 0, 1 },
    },
}

return CardStyle
