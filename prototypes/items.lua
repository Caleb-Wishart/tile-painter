local data_util = require("__flib__.data-util")

local entity_tool = {
    type = "selection-tool",
    name = "tp-tool-entity",
    subgroup = "tool",
    order = "d[tools]-p[paint-entity]",

    icons = {
        { icon = data_util.black_image, icon_size = 1, scale = 64 },
        {
            icon = "__tile-painter__/graphics/tool-entity-x32-white.png",
            icon_size = 32,
            mipmap_count = 2,
        },
    },

    flags = { "hidden", "not-stackable", "spawnable", "only-in-cursor" },
    stack_size = 1,

    selection_mode = { "buildable-type", "same-force" },
    selection_cursor_box_type = "entity",
    selection_color = { r = 0.72, g = 0.45, b = 0.2, a = 1 },

    reverse_selection_mode = { "nothing" },
    reverse_selection_cursor_box_type = "entity",
    reverse_selection_color = { 0, 0, 0, 0 },

    alt_selection_mode = { "buildable-type", "same-force" },
    alt_selection_cursor_box_type = "not-allowed",
    alt_selection_color = { r = 0.72, g = 0.2, b = 0.2, a = 1 },

    alt_reverse_selection_mode = { "nothing" },
    alt_reverse_selection_cursor_box_type = "not-allowed",
    alt_reverse_selection_color = { 0, 0, 0, 0 },
}

local shape_tool = {
    type = "selection-tool",
    name = "tp-tool-shape",
    subgroup = "tool",
    order = "d[tools]-p[paint-shape]",

    icons = {
        { icon = data_util.black_image, icon_size = 1, scale = 64 },
        {
            icon = "__tile-painter__/graphics/tool-shape-x32-white.png",
            icon_size = 32,
            mipmap_count = 2,
        },
    },

    flags = { "hidden", "not-stackable", "spawnable", "only-in-cursor" },
    stack_size = 1,

    selection_mode = { "nothing" },
    selection_cursor_box_type = "entity",
    selection_color = { 0, 0, 0, 0 },

    reverse_selection_mode = { "nothing" },
    reverse_selection_cursor_box_type = "entity",
    reverse_selection_color = { 0, 0, 0, 0 },

    alt_selection_mode = { "nothing" },
    alt_selection_cursor_box_type = "entity",
    alt_selection_color = { 0, 0, 0, 0 },
}

local fill_tool = {
    type = "selection-tool",
    name = "tp-tool-fill",
    subgroup = "tool",
    order = "d[tools]-p[paint-fill]",

    icons = {
        { icon = data_util.black_image, icon_size = 1, scale = 64 },
        {
            icon = "__tile-painter__/graphics/tool-fill-x32-white.png",
            icon_size = 32,
            mipmap_count = 2,
        },
    },

    flags = { "hidden", "not-stackable", "spawnable", "only-in-cursor" },
    stack_size = 1,

    selection_mode = { "nothing" },
    selection_cursor_box_type = "entity",
    selection_color = { 0, 0, 0, 0 },

    alt_selection_mode = { "nothing" },
    alt_selection_cursor_box_type = "entity",
    alt_selection_color = { 0, 0, 0, 0 },
}

data:extend { entity_tool, shape_tool, fill_tool }
