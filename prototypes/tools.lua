local util = require("util")

local item_name = util.defines.item_name

local paint_selector = {
    type = "selection-tool",
    name = item_name,
    subgroup = "tool",
    order = "z[" .. item_name .. "]",
    show_in_library = true,
    icons = {
        {
            icon = "__tile-painter__/graphics/tile-painter.png",
            icon_size = 64,
        }
    },
    flags = { "hidden", "not-stackable", "spawnable", "mod-openable" },
    stack_size = 1,
    selection_color = { r = 0.72, g = 0.45, b = 0.2, a = 1 },
    alt_selection_color = { r = 0.72, g = 0.22, b = 0.1, a = 1 },
    selection_mode = { "buildable-type", "same-force" },
    alt_selection_mode = { "buildable-type", "same-force" },
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "entity",
}

data:extend { paint_selector }
