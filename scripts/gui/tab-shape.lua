local flib_gui = require("__flib__.gui")
local flib_position = require("__flib__.position")
local flib_math = require("__flib__.math")

local templates = require("scripts.gui.templates")

local renderinglib = require("scripts.rendering")
local polygon = require("scripts.polygon")
local painter = require("scripts.painter")

local get_player_settings = require("util").get_player_settings

local MAX_NSIDES = 9
local MIN_NSIDES = 1

local tp_tab_shape = {}

local function num_to_text(num, opts)
    return tostring(flib_math.round(num, opts and opts.round or 0.01))
end

local function position_to_text(self, position)
    local invertY = get_player_settings(self.player.index, "shape-invert-y-axis")
    return "(" .. num_to_text(position.x) .. "," .. num_to_text(position.y * (invertY and -1 or 1)) .. ")"
end

local function on_angle_changed(self, tdata)
    if tdata.center == nil or tdata.vertex == nil then
        return
    end
    local angle = nil
    local invertY = get_player_settings(self.player.index, "shape-invert-y-axis")
    local theta = tdata.theta * (invertY and -1 or 1)
    if tdata.settings.is_angle then
        if tdata.settings.angle_degrees then
            angle = num_to_text((theta * flib_math.rad_to_deg + 360) % 360)
        else
            local delta = 0.01
            angle = theta + 2 * math.pi * (theta > 0 and 0 or 1)
            if angle < delta or 2 * math.pi - angle < delta then
                angle = "0"
            elseif angle % math.pi < delta then
                angle = num_to_text(angle / math.pi, { round = 1 }) .. "π"
            elseif angle % (math.pi / 2) < delta then
                angle = num_to_text(angle / (math.pi / 2), { round = 1 }) .. "π/2"
            elseif angle % (math.pi / 3) < delta then
                angle = num_to_text(angle / (math.pi / 3), { round = 1 }) .. "π/3"
            elseif angle % (math.pi / 4) < delta then
                angle = num_to_text(angle / (math.pi / 4), { round = 1 }) .. "π/4"
            elseif angle % (math.pi / 6) < delta then
                angle = num_to_text(angle / (math.pi / 6), { round = 1 }) .. "π/6"
            else
                angle = num_to_text(angle)
            end
        end
    else
        angle = num_to_text((90 + 360 + tdata.theta * flib_math.rad_to_deg) % 360)
    end
    self.elems.tp_angle_text.text = angle
end

local function on_angle_config_change(self, tdata)
    if not tdata.settings.is_angle or tdata.settings.angle_degrees then
        self.elems.tp_angle_text.enabled = true
        self.elems.tp_angle_text.tooltip = ""
    else
        self.elems.tp_angle_text.enabled = false
        self.elems.tp_angle_text.tooltip = { "gui.tp-tooltip-angle-text-radians" }
    end
    if tdata.settings.is_angle then
        self.elems.tp_show_angle_degrees.enabled = true
        self.elems.tp_show_angle_radians.enabled = true
        self.elems.tp_angle_label.caption = { "gui.tp-angle" }
    else
        self.elems.tp_show_angle_degrees.enabled = false
        self.elems.tp_show_angle_radians.enabled = false
        self.elems.tp_angle_label.caption = { "gui.tp-bearing" }
    end
    on_angle_changed(self, tdata)
end

local function reset_polygon(self, tdata)
    tdata.center                   = nil
    tdata.vertex                   = nil
    tdata.radius                   = nil
    tdata.theta                    = nil
    self.elems.tp_center_text.text = ""
    self.elems.tp_vertex_text.text = ""
    self.elems.tp_radius_text.text = ""
    self.elems.tp_angle_text.text  = ""
    renderinglib.destroy_renders(tdata)
    self.elems.tp_confirm_button.enabled = false
    tdata.tiles = {}
end

local function on_polygon_changed(self, tdata)
    if tdata.center ~= nil and tdata.vertex ~= nil then
        if tdata.settings.show_tiles then
            tdata.tiles = painter.paint_polygon(self.player, tdata, true)
        else
            tdata.tiles = {}
        end
        renderinglib.draw_prospective_polygon(tdata, self.player)
    end
end

function tp_tab_shape.on_position_changed(self, position, surface, isCenter)
    local tdata = self.tabs["shape"] --[[@as ShapeTabData]]
    if tdata == nil then
        return
    end

    -- Reset the center and vertex if the surface changes
    if surface ~= tdata.surface then
        reset_polygon(self, tdata)
        tdata.surface = surface
    end

    local position_text = position_to_text(self, position)

    if isCenter then
        tdata.center = position
        self.elems.tp_center_text.text = position_text
    else
        tdata.vertex = position
        self.elems.tp_vertex_text.text = position_text
    end
    renderinglib.draw_polygon_points(tdata, self.player, true)
    if tdata.center ~= nil and tdata.vertex ~= nil then
        -- Enable the confirm button if the tile type is selected
        self.elems.tp_confirm_button.enabled = tdata.tile_type ~= nil
        -- Perform pre-calculations
        tdata.radius = flib_position.distance(tdata.center, tdata.vertex)
        self.elems.tp_radius_text.text = num_to_text(tdata.radius)
        tdata.theta = polygon.angle(tdata.center, tdata.vertex)
        on_angle_changed(self, tdata)
        on_polygon_changed(self, tdata)
    else
        self.elems.tp_confirm_button.enabled = false
    end
end

--- @param e defines.events.on_gui_click
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_confirm_click(e, self, tdata)
    if tdata.settings.show_tiles then
        painter.paint_tiles(tdata.tiles, game.surfaces[tdata.surface], tdata.tile_type, self.player.force)
    else
        painter.paint_polygon(self.player, tdata)
    end
    renderinglib.destroy_renders(tdata)
    reset_polygon(self, tdata)
end

--- @param self TPGui
--- @param tdata ShapeTabData
local function on_nsides_changed(self, tdata)
    local polygons = {
        [1] = "Circle",
        [2] = "Line",
        [3] = "Triangle",
        [4] = "Square",
        [5] = "Pentagon",
        [6] = "Hexagon",
        [7] = "Heptagon",
        [8] = "Octagon",
        [9] = "Nonagon",
    }
    local name = polygons[tdata.nsides]
    self.elems.tp_heading_shape.caption = name
    on_polygon_changed(self, tdata)
end

--- @param e EventData.on_gui_value_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_nsides_slider_changed(e, self, tdata)
    tdata.nsides = e.element.slider_value
    self.elems.tp_nsides_text.text = tostring(tdata.nsides)

    on_nsides_changed(self, tdata)
end

--- @param e EventData.on_gui_confirmed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_nsides_text_changed(e, self, tdata)
    local nsides = tonumber(e.element.text) or -1 -- -1 is an invalid value
    if nsides > MAX_NSIDES then
        nsides = MAX_NSIDES
    elseif nsides < MIN_NSIDES then
        nsides = MIN_NSIDES
    end
    tdata.nsides = nsides
    e.element.text = tostring(nsides)
    self.elems.tp_nsides_slider.slider_value = nsides

    on_nsides_changed(self, tdata)
end

--- @param e EventData.on_gui_elem_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_shape_tile_select(e, self, tdata)
    local tile = e.element.elem_value --- @cast tile -SignalID|table
    tdata.tile_type = tile
    self.elems.tp_confirm_button.enabled = tdata.center ~= nil and tdata.vertex ~= nil and tile ~= nil
end

--- @param e EventData.on_gui_switch_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_shape_mode_switch(e, self, tdata)
    tdata.fill = e.element.switch_state == "left"
    on_polygon_changed(self, tdata)
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_vertex_state_canged(e, self, tdata)
    tdata.settings.show_vertex = e.element.state
    if tdata.vertex ~= nil then
        renderinglib.draw_polygon_points(tdata, self.player, true)
        if tdata.center ~= nil then
            renderinglib.draw_prospective_polygon(tdata, self.player)
        end
    end
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_center_state_canged(e, self, tdata)
    tdata.settings.show_center = e.element.state
    if tdata.center ~= nil then
        renderinglib.draw_polygon_points(tdata, self.player, true)
        if tdata.vertex ~= nil then
            renderinglib.draw_prospective_polygon(tdata, self.player)
        end
    end
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_radius_state_canged(e, self, tdata)
    tdata.settings.show_radius = e.element.state
    if tdata.center ~= nil and tdata.vertex ~= nil then
        renderinglib.draw_prospective_polygon(tdata, self.player)
    end
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_box_state_canged(e, self, tdata)
    tdata.settings.show_bounding_box = e.element.state
    if tdata.center ~= nil and tdata.vertex ~= nil then
        renderinglib.draw_prospective_polygon(tdata, self.player)
    end
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_tiles_state_canged(e, self, tdata)
    tdata.settings.show_tiles = e.element.state
    on_polygon_changed(self, tdata)
end

--- @param e EventData.on_gui_switch_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_shape_angle_switch(e, self, tdata)
    local is_angle = e.element.switch_state == "left"
    tdata.settings.is_angle = is_angle
    on_angle_config_change(self, tdata)
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_angle_degrees_changed(e, self, tdata)
    tdata.settings.angle_degrees = e.element.state
    self.elems.tp_show_angle_radians.state = not e.element.state
    on_angle_config_change(self, tdata)
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_show_angle_radians_changed(e, self, tdata)
    tdata.settings.angle_degrees = not e.element.state
    self.elems.tp_show_angle_degrees.state = not e.element.state
    on_angle_config_change(self, tdata)
end

--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_shape_reset_click(e, self, tdata)
    reset_polygon(self, tdata)
end

--- @param e EventData.on_gui_confirmed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_angle_text_changed(e, self, tdata)
    local angle = tonumber(e.element.text) or "NaN"
    if angle == "NaN" then
        on_angle_changed(self, tdata)
        return
    end
    if not tdata.settings.is_angle then
        if angle < 0 or angle > 360 then angle = 0 end
        tdata.theta = (angle - 90) * flib_math.deg_to_rad
    else
        local invertY = get_player_settings(self.player.index, "shape-invert-y-axis")
        -- Should only be degrees mode
        tdata.theta = angle * flib_math.deg_to_rad * (invertY and -1 or 1)
    end
    tdata.vertex = polygon.calculate_vertex(tdata.center, tdata.radius, tdata.theta)
    self.elems.tp_vertex_text.text = position_to_text(self, tdata.vertex)
    on_angle_changed(self, tdata)
    on_polygon_changed(self, tdata)
end

--- @param e EventData.on_gui_confirmed
--- @param self TPGui
--- @param tdata ShapeTabData
local function on_radius_text_changed(e, self, tdata)
    local radius = tonumber(e.element.text) or "NaN"
    if radius == "NaN" then
        self.elems.tp_angle_text.text = num_to_text(tdata.radius)
        return
    end
    radius = radius ---@cast radius -string
    tdata.radius = radius
    self.elems.tp_angle_text.text = num_to_text(tdata.radius)
    tdata.vertex = polygon.calculate_vertex(tdata.center, tdata.radius, tdata.theta)
    self.elems.tp_vertex_text.text = position_to_text(self, tdata.vertex)
    on_polygon_changed(self, tdata)
end

local tab_def = {
    name = "shape",
    subheading = {
        {
            type = "label",
            caption = "Triangle",
            name = "tp_heading_shape",
            style = "heading_2_label",
        },
        {
            type = "empty-widget",
            style = "flib_horizontal_pusher",
        },
        {
            type = "slider",
            name = "tp_nsides_slider",
            minimum_value = MIN_NSIDES,
            maximum_value = MAX_NSIDES,
            value = 3,
            style = "notched_slider",
            handler = { [defines.events.on_gui_value_changed] = on_nsides_slider_changed }
        },
        {
            type = "textfield",
            name = "tp_nsides_text",
            text = "3",
            style = "tp_textfield_number",
            numeric = true,
            allow_decimal = false,
            allow_negative = false,
            looe_focus_on_confirm = true,
            clear_and_focus_on_right_click = true,
            handler = { [defines.events.on_gui_confirmed] = on_nsides_text_changed }
        },

    },
    contents = {
        {
            type = "flow",
            direction = "vertical",
            style_mods = { vertically_stretchable = true, vertical_spacing = 4 },
            {
                type = "frame",
                direction = "vertical",
                style = "bordered_frame",
                style_mods = { horizontally_stretchable = true },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        style = "caption_label",
                        caption = { "gui.tp-label-tiles", 0 },
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "switch",
                        name = "tp_shape_mode_switch",
                        switch_state = "left",
                        left_label_caption = { "gui.tp-fill" },
                        right_label_caption = { "gui.tp-outline" },
                        handler = { [defines.events.on_gui_switch_state_changed] = on_shape_mode_switch },
                    },
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    style_mods = { vertical_align = "bottom" },
                    {
                        type = "frame",
                        direction = "horizontal",
                        style = "deep_frame_in_shallow_frame",
                        {
                            type = "choose-elem-button",
                            style = "slot_button",
                            elem_type = "tile",
                            tile = nil,
                            elem_filters = { { filter = "blueprintable", mode = "and" } },
                            handler = { [defines.events.on_gui_elem_changed] = on_shape_tile_select }
                        },
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "button",
                        name = "tp_confirm_button",
                        caption = { "gui.tp-confirm" },
                        handler = { [defines.events.on_gui_click] = on_confirm_click },
                        enabled = false,
                    },
                },
            },
            {
                type = "frame",
                direction = "vertical",
                style = "bordered_frame",
                style_mods = { horizontally_stretchable = true },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        style = "caption_label",
                        caption = { "gui.tp-label-polygon-info" },
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "sprite-button",
                        style = "mini_tool_button_red",
                        sprite = "utility/reset",
                        tooltip = { "gui.tp-tooltip-reset" },
                        handler = { [defines.events.on_gui_click] = on_shape_reset_click },
                    },
                },
                {
                    type = "table",
                    name = "tp_shape_config_table",
                    column_count = 5,
                    {
                        type = "label",
                        caption = { "gui.tp-vertex" },
                        tooltip = { "gui.tp-tooltip-position-vertex" },
                    },
                    {
                        type = "textfield",
                        name = "tp_vertex_text",
                        text = "",
                        style = "long_number_textfield",
                        style_mods = { horizontal_align = "center" },
                        tooltip = { "gui.tp-tooltip-position-vertex-text" },
                        enabled = false,
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "label",
                        name = "tp_angle_label",
                        caption = { "gui.tp-angle" },
                    },
                    {
                        type = "textfield",
                        name = "tp_angle_text",
                        text = "",
                        style = "short_number_textfield",
                        style_mods = { horizontal_align = "center" },
                        enabled = true,
                        numeric = true,
                        allow_negative = true,
                        looe_focus_on_confirm = true,
                        clear_and_focus_on_right_click = true,
                        handler = { [defines.events.on_gui_confirmed] = on_angle_text_changed }

                    },
                    {
                        type = "label",
                        caption = { "gui.tp-center" },
                        tooltip = { "gui.tp-tooltip-position-center" },
                    },
                    {
                        type = "textfield",
                        name = "tp_center_text",
                        text = "",
                        style = "long_number_textfield",
                        tooltip = { "gui.tp-tooltip-position-center-text" },
                        style_mods = { horizontal_align = "center" },
                        enabled = false,
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "label",
                        caption = { "gui.tp-radius" },
                    },
                    {
                        type = "textfield",
                        name = "tp_radius_text",
                        text = "",
                        style = "short_number_textfield",
                        style_mods = { horizontal_align = "center" },
                        numeric = true,
                        allow_negative = false,
                        looe_focus_on_confirm = true,
                        clear_and_focus_on_right_click = true,
                        handler = { [defines.events.on_gui_confirmed] = on_radius_text_changed }
                    },
                },
            },
            {
                type = "frame",
                direction = "vertical",
                style = "bordered_frame",
                style_mods = { horizontally_stretchable = true },
                {
                    type = "label",
                    style = "caption_label",
                    caption = { "gui-blueprint.settings" },
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "flow",
                        direction = "vertical",
                        {
                            type = "checkbox",
                            style = "caption_checkbox",
                            caption = { "gui.tp-show-guide", { "gui.tp-vertex" } },
                            name = "tp_show_vertex",
                            state = true,
                            handler = { [defines.events.on_gui_checked_state_changed] = on_show_vertex_state_canged },
                        },
                        {
                            type = "checkbox",
                            style = "caption_checkbox",
                            caption = { "gui.tp-show-guide", { "gui.tp-center" } },
                            name = "tp_show_center",
                            state = true,
                            handler = { [defines.events.on_gui_checked_state_changed] = on_show_center_state_canged },
                        },
                        {
                            type = "checkbox",
                            style = "caption_checkbox",
                            caption = { "gui.tp-show-guide", { "gui.tp-radius" } },
                            name = "tp_show_radius",
                            state = false,
                            handler = { [defines.events.on_gui_checked_state_changed] = on_show_radius_state_canged },
                        },
                        {
                            type = "checkbox",
                            style = "caption_checkbox",
                            caption = { "gui.tp-show-guide", { "gui.tp-box" } },
                            name = "tp_show_box",
                            state = false,
                            handler = { [defines.events.on_gui_checked_state_changed] = on_show_box_state_canged },
                        },
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "flow",
                        direction = "vertical",
                        {
                            type = "switch",
                            name = "tp_shape_mode_switch",
                            switch_state = "left",
                            left_label_caption = { "gui.tp-angle" },
                            right_label_caption = { "gui.tp-bearing" },
                            tooltip = { "gui.tp-tooltip-angle-bearing-switch" },
                            handler = { [defines.events.on_gui_switch_state_changed] = on_shape_angle_switch },
                        },
                        {
                            type = "radiobutton",
                            name = "tp_show_angle_degrees",
                            caption = { "gui.tp-degrees" },
                            tooltip = { "gui.tp-tooltip-angle", { "gui.tp-degrees" } },
                            handler = { [defines.events.on_gui_click] = on_show_angle_degrees_changed },
                            state = true,
                            enabled = true,
                        },
                        {
                            type = "radiobutton",
                            name = "tp_show_angle_radians",
                            caption = { "gui.tp-radians" },
                            tooltip = { "gui.tp-tooltip-angle", { "gui.tp-radians" } },
                            handler = { [defines.events.on_gui_click] = on_show_angle_radians_changed },
                            state = false,
                            enabled = true,
                        },
                        {
                            type = "checkbox",
                            style = "caption_checkbox",
                            caption = { "gui.tp-show-guide", { "gui.tp-label-tiles", 0 } },
                            tooltip = { "gui.tp-tooltip-shape-show-tiles" },
                            name = "tp_show_tiles",
                            state = false,
                            handler = { [defines.events.on_gui_checked_state_changed] = on_show_tiles_state_canged },
                        },
                    },
                }
            },
        },
    },
}

tp_tab_shape.def = templates.tab_heading(tab_def)

--- @class ShapeTabData
--- @field center MapPosition|nil
--- @field vertex MapPosition|nil
--- @field nsides integer
--- @field radius number|nil
--- @field theta number|nil
--- @field tile_type string|nil
--- @field surface uint|nil
--- @field fill boolean
--- @field renders uint64[]
--- @field settings table {show_vertex:boolean, show_center:boolean, show_radius:boolean, show_bounding_box:boolean, angle_degrees:boolean, is_angle:boolean, show_tiles:boolean}
--- @field tiles Tile[]

--- @param self TPGui
function tp_tab_shape.init(self)
    local tab = {
        center = nil,
        vertex = nil,
        surface = nil,
        nsides = 3,
        radius = nil,
        theta = nil,
        tile_type = nil,
        fill = true,
        renders = {},
        settings = {
            show_vertex = true,
            show_center = true,
            show_radius = false,
            show_bounding_box = false,
            angle_degrees = true,
            is_angle = true,
            show_tiles = false,
        },
        tiles = {},
    } --[[@as ShapeTabData]]
    self.tabs["shape"] = tab

    self.elems.tp_shape_config_table.style.column_alignments[1] = "left"
    self.elems.tp_shape_config_table.style.column_alignments[3] = "right"
    self.elems.tp_shape_config_table.style.column_alignments[2] = "left"
    self.elems.tp_shape_config_table.style.column_alignments[4] = "right"
end

--- @param self TPGui
function tp_tab_shape.hide(self)
    local tdata = self.tabs["shape"] --[[@as ShapeTabData]]
    renderinglib.destroy_renders(tdata)
end

--- @param self TPGui
function tp_tab_shape.refresh(self)
    local tdata = self.tabs["shape"] --[[@as ShapeTabData]]
    if tdata.center ~= nil and tdata.vertex ~= nil then
        renderinglib.draw_prospective_polygon(tdata, self.player)
    end
end

--- @param self TPGui
--- @param tdata ShapeTabData
function tp_tab_shape.on_next_setting(self, tdata)
    tdata.nsides = tdata.nsides + 1
    if tdata.nsides > MAX_NSIDES then
        tdata.nsides = MIN_NSIDES
    end
    self.elems.tp_nsides_slider.slider_value = tdata.nsides
    self.elems.tp_nsides_text.text = tostring(tdata.nsides)
    on_nsides_changed(self, tdata)
end

--- @param self TPGui
--- @param tdata ShapeTabData
function tp_tab_shape.on_previous_setting(self, tdata)
    tdata.nsides = tdata.nsides - 1
    if tdata.nsides < MIN_NSIDES then
        tdata.nsides = MAX_NSIDES
    end
    self.elems.tp_nsides_slider.slider_value = tdata.nsides
    self.elems.tp_nsides_text.text = tostring(tdata.nsides)
    on_nsides_changed(self, tdata)
end

flib_gui.add_handlers({
    on_shape_mode_switch = on_shape_mode_switch,
    on_nsides_text_changed = on_nsides_text_changed,
    on_nsides_slider_changed = on_nsides_slider_changed,
    on_shape_tile_select = on_shape_tile_select,
    on_confirm_click = on_confirm_click,
    on_show_vertex_state_canged = on_show_vertex_state_canged,
    on_show_center_state_canged = on_show_center_state_canged,
    on_show_radius_state_canged = on_show_radius_state_canged,
    on_show_box_state_canged = on_show_box_state_canged,
    on_show_angle_degrees_click = on_show_angle_degrees_changed,
    on_show_angle_radians_click = on_show_angle_radians_changed,
    on_shape_angle_switch = on_shape_angle_switch,
    on_shape_reset_click = on_shape_reset_click,
    on_show_tiles_state_canged = on_show_tiles_state_canged,
    on_angle_text_changed = on_angle_text_changed,
    on_radius_text_changed = on_radius_text_changed,
}, templates.tab_wrapper("shape"))

return tp_tab_shape
