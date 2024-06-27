local flib_gui = require("__flib__.gui-lite")
local flib_boundingBox = require("__flib__.bounding-box")
local position = require("__flib__.position")

local renderinglib = require("scripts.rendering")
local surfacelib = require("scripts.surface")
local polygon = require("scripts.polygon")
local bounding_box = require("scripts.bounding-box")

--- @class ShapeGui
--- @field elems table<string, LuaGuiElement>
--- @field player LuaPlayer
--- @field centre MapPosition
--- @field vertex MapPosition
--- @field nsides integer
--- @field tile_type string
--- @field surface uint
--- @field renders table<string, uint64>
local gui = {}

-- Thx Raiguard ;)
-- https://github.com/raiguard/RateCalculator/blob/master/scripts/gui.lua#L24
local top_left_location = { x = 15, y = 58 + 15 }

function gui.on_init()
    --- @type table<integer, ShapeGui>
    global.gui_shape = {}
end

--- @param self ShapeGui
function gui.hide(self)
    self.elems.tp_shape_window.visible = false
    renderinglib.destroy_renders(self)
end

--- @param self ShapeGui
function gui.show(self)
    self.elems.tp_shape_window.visible = true
    self.player.opened = self.elems.tp_shape_window
    if self.centre ~= nil and self.vertex ~= nil then
        renderinglib.draw_prospective_polygon(self)
    end
end

--- @param e EventData.on_gui_closed
local function on_shape_window_closed(e)
    local self = global.gui_shape[e.player_index]
    gui.hide(self)
end

--- @param self ShapeGui
local function reset_location(self)
    local window = self.elems.tp_shape_window
    local scale = self.player.display_scale
    window.location = position.mul(top_left_location, { scale, scale })
end

--- @param e EventData.on_gui_click
local function on_titlebar_click(e)
    local self = global.gui_shape[e.player_index]
    if not self or e.button ~= defines.mouse_button_type.middle then
        return
    end
    reset_location(self)
end

local function on_nsides_changed(self)
    if self.centre ~= nil and self.vertex ~= nil then
        renderinglib.draw_prospective_polygon(self)
    end

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
    local name = polygons[self.nsides]
    self.elems.tp_polygon_text.text = name
end

--- @param e EventData.on_gui_value_changed
local function on_nsides_slider_changed(e)
    local self = global.gui_shape[e.player_index]
    self.nsides = e.element.slider_value
    self.elems.tp_nsides_text.text = tostring(self.nsides)

    on_nsides_changed(self)
end

--- @param e EventData.on_gui_text_changed
local function on_nsides_text_changed(e)
    local self = global.gui_shape[e.player_index]
    local nsides = tonumber(e.element.text) or -1 -- -1 is an invalid value
    if nsides > 9 or nsides < 1 then
        return
    end
    e.element.text = tostring(self.nsides)
    self.nsides = nsides

    on_nsides_changed(self)
end

--- @param player LuaPlayer
function gui.destroy_gui(player)
    local self = global.gui_shape[player.index]
    if not self then
        return
    end
    global.gui_shape[player.index] = nil
    local window = self.elems.tp_shape_window
    if not window.valid then
        return
    end
    window.destroy()
end

local function angle(p1, p2)
    return math.atan2(p2.y - p1.y, p2.x - p1.x)
end
-- TODO Resolve duplicate code

--- @param e EventData.on_gui_elem_changed
local function on_shape_tile_select(e)
    local self = global.gui_shape[e.player_index]
    if self == nil then return end

    self.tile_type = e.element.elem_value
end

--- @param e defines.events.on_gui_click
local function on_confirm_click(e)
    local self = global.gui_shape[e.player_index]
    if self.centre == nil or self.vertex == nil then
        return
    end
    local n = self.nsides
    local r = position.distance(self.centre, self.vertex)
    local theta = angle(self.centre, self.vertex)
    local bb = {
        left_top = position.add(self.centre, { x = -r, y = -r }),
        right_bottom = position.add(self.centre, { x = r, y = r }),
    }
    local surface = game.surfaces[self.surface]
    local tiles = surfacelib.find_tiles_filtered(surface, { area = bb })
    if n == 0 then


    else
        local vertices = polygon.polygon_vertices(n, r, self.centre, theta)
        game.print(serpent.line(vertices))
        local res = {}
        for _, tile in pairs(tiles) do
            if polygon.point_in_polygon(tile.position, n, vertices) then
                table.insert(res, tile)
            end
            for i = 1, n do
                local p1 = vertices[i]
                local p2 = vertices[(i + 1) % n + 1]
                game.print("p1: " .. serpent.line(p1) .. " p2: " .. serpent.line(p2) .. " i:" .. i)
                if bounding_box.line_intersect_AABB(p1, p2, flib_boundingBox.from_position(tile.position, true)) then
                    table.insert(res, tile)
                    break
                end
            end
        end
        for _, tile in pairs(res) do
            surfacelib.create_tile_ghost(surface, self.tile_type, tile.position, self.player.force)
        end
    end
    renderinglib.destroy_renders(self)
    self.centre                          = nil
    self.vertex                          = nil
    self.surface                         = nil
    self.elems.tp_centre_text.text       = ""
    self.elems.tp_vertex_text.text       = ""
    self.elems.tp_confirm_button.enabled = false
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
        handler = { [defines.events.on_gui_closed] = on_shape_window_closed },
        -- Children
        -- Configuration Frame
        {
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "tp_shape_window",
            handler = { [defines.events.on_gui_click] = on_titlebar_click },
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
                direction = "vertical",
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { 'gui.tp-caption-tile', 0 },
                    },
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
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { 'gui.tp-label-polygon-select' },
                        tooltip = { 'gui.tp-label-tt-polygon-select' },
                    },
                    {
                        type = "slider",
                        name = "tp_nsides_slider",
                        minimum_value = 1,
                        maximum_value = 9,
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
                        handler = { [defines.events.on_gui_text_changed] = on_nsides_text_changed }

                    },
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { 'gui.tp-label-polygon-name' },
                        tooltip = { 'gui.tp-label-tt-polygon-name' },
                    },
                    {
                        type = "textfield",
                        name = "tp_polygon_text",
                        text = "Triangle",
                        enabled = false,

                    },
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { 'gui.tp-label-position-centre' },
                        tooltip = { 'gui.tp-label-tt-position-centre' },
                    },
                    {
                        type = "textfield",
                        name = "tp_centre_text",
                        text = "",
                        -- style = "short_number_textfield",
                        enabled = false,

                    },
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { 'gui.tp-label-position-vertex' },
                        tooltip = { 'gui.tp-label-tt-position-vertex' },
                    },
                    {
                        type = "textfield",
                        name = "tp_vertex_text",
                        text = "",
                        -- style = "short_number_textfield",
                        enabled = false,

                    },
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "button",
                        name = "tp_confirm_button",
                        caption = { 'gui.tp-confirm' },
                        handler = { [defines.events.on_gui_click] = on_confirm_click },
                        enabled = false,
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                },
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
        tile_type = nil,
        renders = {
            box = nil,
            polygon = nil,
            centre = nil,
            vertex = nil,
        },
    }
    global.gui_shape[player.index] = self

    reset_location(self)

    return self
end

--- @param e EventData.on_player_removed
local function on_player_removed(e)
    global.gui_shape[e.player_index] = nil
end

local function on_player_cursor_stack_changed(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local self = global.gui_shape[e.player_index]
    if not self then
        return
    end

    if not player.cursor_stack.valid_for_read or player.cursor_stack.name ~= "tp-shape-tool" then
        gui.hide(self)
    end
end

flib_gui.add_handlers({
    on_titlebar_click = on_titlebar_click,
    on_shape_window_closed = on_shape_window_closed,
    on_nsides_text_changed = on_nsides_text_changed,
    on_nsides_slider_changed = on_nsides_slider_changed,
    on_shape_tile_select = on_shape_tile_select,
    on_confirm_click = on_confirm_click,
})

gui.events = {
    [defines.events.on_player_removed] = on_player_removed,
    [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
}

return gui
