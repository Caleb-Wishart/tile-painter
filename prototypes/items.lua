local entity_tool = {
    type = "selection-tool",
    name = "tp-entity-tool",
    subgroup = "tool",
    order = "d[tools]-p[paint-entity]",

    icons = {
        {
            icon = "__TilePainter__/graphics/TilePainter.png",
            icon_size = 64,
        }
    },

    flags = { "hidden", "not-stackable", "spawnable", "mod-openable" },
    stack_size = 1,

    selection_mode = { "buildable-type", "same-force" },
    selection_cursor_box_type = "entity",
    selection_color = { r = 0.72, g = 0.45, b = 0.2, a = 1 },

    alt_selection_mode = { "buildable-type", "same-force" },
    alt_selection_cursor_box_type = "entity",
    alt_selection_color = { r = 0.72, g = 0.22, b = 0.1, a = 1 },
}

local shape_tool = {
    type = "selection-tool",
    name = "tp-shape-tool",
    subgroup = "tool",
    order = "d[tools]-p[paint-shape]",

    icons = {
        {
            icon = "__TilePainter__/graphics/icons/paintbrush-white-64.png",
            icon_size = 64
        }
    },

    flags = { "hidden", "not-stackable", "spawnable", "only-in-cursor" },
    stack_size = 1,

    selection_mode = { "nothing" },
    selection_cursor_box_type = "entity",
    selection_color = { 0, 0, 0, 0 },

    alt_selection_mode = { "nothing" },
    alt_selection_cursor_box_type = "entity",
    alt_selection_color = { 0, 0, 0, 0 },

    -- TODO make selection tool cursor custom
    mouse_cursor = "selection-tool-cursor",
}

data:extend { entity_tool, shape_tool }
