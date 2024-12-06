local flib_gui = require("__flib__.gui")
local templates = require("scripts.gui.templates")

local tp_tab_fill = {}

local tab_def = {
    name = "fill",
    subheading = {
        {
            type = "label",
            caption = "Fill Area",
            style = "heading_2_label",
        },
        {
            type = "empty-widget",
            style = "flib_horizontal_pusher",
        },
    },
    contents = {
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { top_padding = 4, bottom_padding = 4 },
            {
                type = "label",
                caption = "Options",
                style = "heading_2_label",
            },
        },
    },
}

tp_tab_fill.def = templates.tab_heading(tab_def)

--- @class FillTabData

function tp_tab_fill.init(self)
    local tab = {}
    self.tabs["fill"] = tab
end

function tp_tab_fill.refresh(self) end

return tp_tab_fill
