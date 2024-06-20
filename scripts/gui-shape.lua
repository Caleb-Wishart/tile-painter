local flib_gui = require("__flib__.gui-lite")
local renderinglib = require("scripts.rendering")

--- @class ShapeGui
--- @field elems table<string, LuaGuiElement>
--- @field player LuaPlayer
--- @field centre MapPosition
--- @field vertex MapPosition
--- @field nsides integer
--- @field surface uint
--- @field renders table<string, uint64>
local gui = {}

function gui.on_init()
    --- @type table<integer, ShapeGui>
    global.polygon = {}
end

--- @param self ShapeGui
function gui.hide(self)
    self.elems.tp_window.visible = false
end

--- @param e EventData.on_gui_closed
local function on_window_closed(e)
    local self = global.polygon[e.player_index]
    gui.hide(self)
end

--- @param e EventData.on_gui_text_changed
local function on_nsides_text_changed(e)
    local self = global.polygon[e.player_index]
    local nsides = tonumber(e.element.text) or 3
    if nsides > 30 or (nsides < 2 and nsides ~= 0) then
        nsides = 3
    end
    e.element.text = tostring(self.nsides)
    self.nsides = nsides
    if self.centre ~= nil and self.vertex ~= nil then
        renderinglib.draw_prospective_polygon(self)
    end

    local polygons = {
        [0] = "Circle",
        [2] = "Line",
        [3] = "Triangle",
        [4] = "Square",
        [5] = "Pentagon",
        [6] = "Hexagon",
        [7] = "Heptagon",
        [8] = "Octagon",
        [9] = "Nonagon",
        [10] = "Decagon",
        [11] = "Hendecagon",
        [12] = "Dodecagon",
        [13] = "Tridecagon",
        [14] = "Tetradecagon",
        [15] = "Pentadecagon",
        [16] = "Hexadecagon",
        [17] = "Heptadecagon",
        [18] = "Octadecagon",
        [19] = "Enneadecagon",
        [20] = "Icosagon",
        [21] = "Icosikaihenagon",
        [22] = "Icosikaidigon",
        [23] = "Icosikaitrigon",
        [24] = "Icosikaitetragon",
        [25] = "Icosikaipentagon",
        [26] = "Icosikaihexagon",
        [27] = "Icosikaiheptagon",
        [28] = "Icosikaioctagon",
        [29] = "Icosikaienneagon",
        [30] = "Triacontagon",
    }
    local name = polygons[nsides]
    self.elems.tp_polygon_text.text = name
end

--- @param player LuaPlayer
function gui.destroy_gui(player)
    local self = global.polygon[player.index]
    if not self then
        return
    end
    global.polygon[player.index] = nil
    local window = self.elems.tp_window
    if not window.valid then
        return
    end
    window.destroy()
end

--- @param player LuaPlayer
--- @return ShapeGui
function gui.build_gui(player)
    gui.destroy_gui(player)

    local elems = flib_gui.add(player.gui.screen, {
        type = "frame",
        name = "tp_shape_window",
        direction = "vertical",
        style = "inner_frame_in_outer_frame",
        --- @diagnostic disable-next-line: missing-fields
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = on_window_closed },
        -- Children
        -- Configuration Frame
        {
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "tp_shape_window",
            {
                type = "label",
                style = "frame_title",
                caption = "Polygon Configuration",
                ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        },
        {
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical",
            {
                type = "frame",
                style = "deep_frame_in_shallow_frame",
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { 'tile_painter_gui.polygon_select' },
                        tooltip = { 'tile_painter_gui.polygon_select_tt' },
                    },
                    {
                        type = "textfield",
                        name = "tp_nsides_text",
                        text = "3",
                        style = "short_number_textfield",
                        numeric = true,
                        allow_decimal = false,
                        allow_negative = false,
                        looe_focus_on_confirm = true,
                        clear_and_focus_on_right_click = true,
                        handlers = { [defines.events.on_gui_text_changed] = on_nsides_text_changed }

                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        {
                            type = "label",
                            caption = { 'tile_painter_gui.polygon_name' },
                            tooltip = { 'tile_painter_gui.polygon_name_tt' },
                        },
                        {
                            type = "textfield",
                            name = "tp_polygon_text",
                            text = "",
                            enabled = false,

                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        {
                            type = "label",
                            caption = { 'tile_painter_gui.position_centre' },
                            tooltip = { 'tile_painter_gui.position_centre_tt' },
                        },
                        {
                            type = "textfield",
                            name = "tp_centre_text",
                            text = "",
                            style = "short_number_textfield",
                            enabled = false,

                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        {
                            type = "label",
                            caption = { 'tile_painter_gui.position_vertex' },
                            tooltip = { 'tile_painter_gui.position_vertex_tt' },
                        },
                        {
                            type = "textfield",
                            name = "tp_vertex_text",
                            text = "",
                            style = "short_number_textfield",
                            enabled = false,

                        },
                    },

                }
            },
        },
    })

    local self = {
        elems = elems,
        player = player,
        centre = nil,
        vertex = nil,
        surface = nil,
        nsides = 3,
        renders = {
            box = nil,
            polygon = nil,
        }
    }
    global.polygon[player.index] = self

    return self
end

local function on_polygon_options_changed(e)
end

gui.events = {
    [defines.events.on_polygon_options_changed] = on_polygon_options_changed,
}

return gui
