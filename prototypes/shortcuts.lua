local entity_shortcut = {
    type = "shortcut",
    name = "tp-get-entity-tool",
    order = "d[tools]-p[paint-entity]",
    style = "default",
    icon = {
        filename = "__TilePainter__/graphics/tool-entity-x32.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_icon = {
        filename = "__TilePainter__/graphics/tool-entity-x32-white.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    small_icon = {
        filename = "__TilePainter__/graphics/tool-entity-x24.png",
        size = 24,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_small_icon = {
        filename = "__TilePainter__/graphics/tool-entity-x24-white.png",
        size = 24,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    associated_control_input = "tp-get-entity-tool",
    action = "lua",
}

local shape_shortcut = {
    type = "shortcut",
    name = "tp-get-shape-tool",
    order = "d[tools]-p[paint-shape]",
    style = "default",
    icon = {
        filename = "__TilePainter__/graphics/tool-shape-x32.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_icon = {
        filename = "__TilePainter__/graphics/tool-shape-x32-white.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    small_icon = {
        filename = "__TilePainter__/graphics/tool-shape-x24.png",
        size = 24,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_small_icon = {
        filename = "__TilePainter__/graphics/tool-shape-x24-white.png",
        size = 24,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    associated_control_input = "tp-get-shape-tool",
    action = "lua",
}

data:extend { entity_shortcut, shape_shortcut }
