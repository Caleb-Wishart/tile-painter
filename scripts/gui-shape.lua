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

--- @param self ShapeGui
function gui.show(self)
    self.elems.tp_window.visible = true
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

local function angle(p1, p2)
    return math.atan2(p2.y - p1.y, p2.x - p1.x)
end
-- TODO Resolve duplicate code

--- @param e defines.events.on_gui_click
local function on_confirm_click(e)
    local self = global.polygon[e.player_index]
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
    local tiles = surfacelib.find_tiles_filtered(game.surfaces[self.surface], { area = bb })
    if n == 0 then


    else
        local vertices = polygon.polygon_vertices(n, r, self.centre, theta)

        local res = {}
        for _, tile in pairs(tiles) do
            if polygon.point_in_polygon(tile.position, n, vertices) then
                table.insert(res, tile)
            end
            for i = 1, n + 1 do
                local p1 = vertices[i]
                local p2 = vertices[i % n + 1]
                if bounding_box.line_intersect_AABB(p1, p2, flib_boundingBox.from_position(tile.position, true)) then
                    table.insert(res, tile)
                    break
                end
            end
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
                            caption = { 'tile_painter_gui.confirm' },
                            handler = { [defines.events.on_gui_click] = on_confirm_click },
                            enabled = false,
                        },
                        {
                            type = "empty-widget",
                            style = "flib_horizontal_pusher",
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

return gui
