local item = {
  type = "selection-tool",
  name = "tile-painter",
  subgroup = "tool",
  order = "z[tile-painter]",
  show_in_library = true,
  icons = {
    {
      icon = "__tile-painter__/graphics/tile-painter.png",
      icon_size = 64,
    }
  },
  flags = {"hidden", "not-stackable","only-in-cursor", "spawnable"},
  stack_size = 1,
  selection_color = { r = 0.72, g = 0.45, b = 0.2, a = 1 },
  alt_selection_color = { r = 0.72, g = 0.22, b = 0.1, a = 1 },
  selection_mode = { "buildable-type", "same-force" },
  alt_selection_mode = { "buildable-type", "same-force" },
  selection_cursor_box_type = "entity",
  alt_selection_cursor_box_type = "entity",
}

local shortcut = {
  type = "shortcut",
  name = "shortcut-tile-painter-item",
  action = "spawn-item",
  item_to_spawn = "tile-painter",
  order = "b[blueprints]-p[tile-painter]",
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

data:extend{item, shortcut}
