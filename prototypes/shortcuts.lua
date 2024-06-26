local entity_shortcut = {
    type = "shortcut",
    name = "tp-entity-selector",
    order = "d[tools]-p[paint-entity]",
    style = "default",
    icon = {
        filename = "__TilePainter__/graphics/icons/paintbrush-white-64.png",
        flags = {
            "gui-icon"
        },
        priority = "extra-high-no-scale",
        scale = 1,
        size = 64
    },
    associated_control_input = "tp-get-entity-tool",
    action = "spawn-item",
    item_to_spawn = "tp-entity-tool",
}

local shape_shortcut = {
    type = "shortcut",
    name = "tp-shape-selector",
    order = "d[tools]-p[paint-shape]",
    style = "default",
    icon = {
        filename = "__TilePainter__/graphics/shortcuts/shape-shortcut-x32-white.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_icon = {
        filename = "__TilePainter__/graphics/shortcuts/shape-shortcut-x32-black.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    associated_control_input = "tp-get-shape-tool",
    action = "lua",
}

data:extend { entity_shortcut, shape_shortcut }
