local util = require("__tile-painter__/util")
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

data:extend { shortcut }
