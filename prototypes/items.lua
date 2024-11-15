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
        },
    },

    flags = { "not-stackable", "spawnable", "only-in-cursor" },
    hidden = true,
    stack_size = 1,

    select = {
        border_color = { r = 0.72, g = 0.45, b = 0.2, a = 1 },
        mode = { "buildable-type", "same-force" },
        cursor_box_type = "entity"
    },

    reverse_select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    },

    alt_select = {
        border_color = { r = 0.72, g = 0.2, b = 0.2, a = 1 },
        mode = { "buildable-type", "same-force" },
        cursor_box_type = "not-allowed"
    },

    alt_reverse_select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "not-allowed"
    },
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
        },
    },

    flags = { "not-stackable", "spawnable", "only-in-cursor" },
    hidden = true,
    stack_size = 1,

    select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    },

    reverse_select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    },

    alt_select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    }
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
        },
    },

    flags = { "not-stackable", "spawnable", "only-in-cursor" },
    hidden = true,
    stack_size = 1,

    select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    },

    reverse_select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    },

    alt_select = {
        border_color = { 0, 0, 0, 0 },
        mode = { "nothing" },
        cursor_box_type = "entity"
    }
}

data:extend { entity_tool, shape_tool, fill_tool }
