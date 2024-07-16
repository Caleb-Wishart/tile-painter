local shortcut = {
    type = "shortcut",
    name = "tp-get-tool",
    order = "d[tools]-p[tile-painter]",
    style = "default",
    icon = {
        filename = "__tile-painter__/graphics/paintbrush-x32.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_icon = {
        filename = "__tile-painter__/graphics/paintbrush-x32-white.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    small_icon = {
        filename = "__tile-painter__/graphics/paintbrush-x24.png",
        size = 24,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_small_icon = {
        filename = "__tile-painter__/graphics/paintbrush-x24-white.png",
        size = 24,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    associated_control_input = "tp-get-tool",
    action = "lua",
}

data:extend { shortcut }
