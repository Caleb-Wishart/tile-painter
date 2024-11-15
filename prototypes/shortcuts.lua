local shortcut = {
    type = "shortcut",
    name = "tp-get-tool",
    order = "d[tools]-p[tile-painter]",
    style = "default",
    icon = "__tile-painter__/graphics/paintbrush-x32.png",
    small_icon = "__tile-painter__/graphics/paintbrush-x24.png",
    icon_size = 32,
    small_icon_size = 24,
    action = "lua",
    associated_control_input = "tp-get-tool",
}

data:extend { shortcut }
