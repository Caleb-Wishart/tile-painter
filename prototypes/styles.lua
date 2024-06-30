local styles = data.raw["gui-style"].default

styles["tp_inventory_frame"] = {
    type = "frame_style",
    parent = "inset_frame_container_frame",
    horizontally_stretchable = "on",
}

styles["tp_config_flow"] = {
    type = "vertical_flow_style",
    parent = "vertical_flow",
    horizontally_stretchable = "on",
}

styles["tp_config_table"] = {
    type = "table_style",
    parent = "slot_table",
    horizontally_stretchable = "on",
    right_cell_padding = 1,
    horizontal_spacing = 4,
}

styles["tp_inventory_scroll_pane"] = {
    type = "scroll_pane_style",
    parent = "inventory_scroll_pane",
    horizontally_squashable = "auto",
}

styles["tp_flow_titlebar"] = {
    type = "horizontal_flow_style",
    parent = "flib_titlebar_flow",
    vertically_stretchable = "off",
}

styles["tp_titlebar_label"] = {
    type = "label_style",
    parent = "frame_title",
    vertically_stretchable = "on",
    horizontally_squashable = "on",
}

styles["tp_titlebar_handle"] = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    left_margin = 4,
    right_margin = 4,
    height = 24,
    horizontally_stretchable = "on",
}

styles["tp_textfield_number"] = {
    type = "textbox_style",
    width = 36,
    natural_width = 36,
}

styles["tp_inside_frame"] = {
    type = "frame_style",
    parent = "frame",
    padding = 0,
    horizontally_stretchable = "on",
    graphical_set =
    {
        base =
        {
            position = { 17, 0 },
            corner_size = 8,
            draw_type = "outer",
            center = { position = { 256, 25 }, size = { 1, 1 } },
        },
        shadow = default_inner_shadow,
    },
    vertical_flow_style =
    {
        type = "vertical_flow_style",
        vertical_spacing = 0
    },
}

styles["tp_tabbed_pane_frame"] = {
    type = "frame_style",
    top_padding = 4,
    right_padding = 0,
    left_padding = 0,
    bottom_padding = 0,
    graphical_set = {
        base =
        {
            top = { position = { 256, 18 }, size = { 1, 1 } },
            center = { position = { 256, 25 }, size = { 1, 1 } },
        },
        shadow = top_glow({ 255, 255, 255, 0.35 }, 0.5)
    },
}

styles["tp_tabbed_pane"] = {
    type = "tabbed_pane_style",
    padding = 0,
    top_margin = 6,
    tab_content_frame = {
        type = "frame_style",
        parent = "tp_tabbed_pane_frame",
    }
}

styles["tp_header_tab"] = {
    type = "tab_style",
    parent = "tab",
    selected_graphical_set = {
        base = {
            filename = "__TilePainter__/graphics/gui-tab.png",
            position = { 0, 0 },
            corner_size = 8
        },
        shadow = tab_glow(default_shadow_color, 0.5)
    },

}


styles["tp_tab_inside_shallow_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    top_padding = 4,
    left_padding = 12,
    right_padding = 12,
    bottom_padding = 12,
    vertically_stretchable = "on",
    graphical_set = {
        base =
        {
            position = { 17, 0 },
            corner_size = 8,
            center = { position = { 76, 8 }, size = { 1, 1 } },
            top = { position = { 256, 25 }, size = { 1, 1 } },
            draw_type = "outer"
        },
        shadow = tab_glow(default_shadow_color, 0.5)
    },
}
