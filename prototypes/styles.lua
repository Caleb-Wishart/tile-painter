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
    horizontally_stretchable = "on"
}
