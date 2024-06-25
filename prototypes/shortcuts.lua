local util = require("util")
local item_name = util.defines.item_name

local shortcut = {
    type = "shortcut",
    name = "shortcut-" .. item_name .. "-item",
    action = "spawn-item",
    item_to_spawn = item_name,
    order = "b[blueprints]-p[" .. item_name .. "]",
    style = "blue",
    icon = {
        filename = "__tile-painter__/graphics/icons/paintbrush-white-64.png",
        flags = {
            "gui-icon"
        },
        priority = "extra-high-no-scale",
        scale = 1,
        size = 64
    }
}

local shape_shortcut = {
    type = "shortcut",
    name = "shortcut-" .. item_name .. "-shape",
    action = "lua",
    associated_control_input = "tile-painter-shape",
    order = "b[blueprints]-p[" .. item_name .. "-polygon]",
    style = "default",
    icon = {
        filename = "__tile-painter__/graphics/shortcuts/shape-shortcut-x32-white.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    },
    disabled_icon = {
        filename = "__tile-painter__/graphics/shortcuts/shape-shortcut-x32-black.png",
        size = 32,
        mipmap_count = 2,
        flags = { "gui-icon" },
    }
}

data:extend { shortcut, shape_shortcut }
