local flib_gui = require("__flib__.gui-lite")
local flib_boundingBox = require("__flib__.bounding-box")
local position = require("__flib__.position")

local templates = require("scripts.gui.templates")

local renderinglib = require("scripts.rendering")
local surfacelib = require("scripts.surface")
local polygon = require("scripts.polygon")
local bounding_box = require("scripts.bounding-box")

local tp_tab_shape = {}

--- @param self Gui
--- @param tdata ShapeTabData
local function on_nsides_changed(self, tdata)
    if tdata.centre ~= nil and tdata.vertex ~= nil then
        renderinglib.draw_prospective_polygon(tdata, self.player)
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
    local name = polygons[tdata.nsides]
    self.elems.tp_heading_shape.caption = name
end

--- @param e EventData.on_gui_value_changed
--- @param self Gui
--- @param tdata ShapeTabData
local function on_nsides_slider_changed(e, self, tdata)
    tdata.nsides = e.element.slider_value
    self.elems.tp_nsides_text.text = tostring(tdata.nsides)

    on_nsides_changed(self, tdata)
end

--- @param e EventData.on_gui_text_changed
--- @param self Gui
--- @param tdata ShapeTabData
local function on_nsides_text_changed(e, self, tdata)
    local nsides = tonumber(e.element.text) or -1 -- -1 is an invalid value
    if nsides > 9 or nsides < 1 then
        return
    end
    e.element.text = tostring(tdata.nsides)
    tdata.nsides = nsides

    on_nsides_changed(self, tdata)
end

--- @param e EventData.on_gui_elem_changed
--- @param self Gui
--- @param tdata ShapeTabData
local function on_shape_tile_select(e, self, tdata)
    local tile = e.element.elem_value --- @cast tile -SignalID
    tdata.tile_type = tile
end

--- @param e defines.events.on_gui_click
--- @param self Gui
--- @param tdata ShapeTabData
local function on_confirm_click(e, self, tdata)
    if tdata.centre == nil or tdata.vertex == nil then
        return
    end
    local n = tdata.nsides
    local r = position.distance(tdata.centre, tdata.vertex)
    local theta = polygon.angle(tdata.centre, tdata.vertex)
    local bb = {
        left_top = position.add(tdata.centre, { x = -r, y = -r }),
        right_bottom = position.add(tdata.centre, { x = r, y = r }),
    }
    local surface = game.surfaces[tdata.surface]
    local tiles = surfacelib.find_tiles_filtered(surface, { area = bb })
    if n == 0 then


    else
        local vertices = polygon.polygon_vertices(n, r, tdata.centre, theta)
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
            surfacelib.create_tile_ghost(surface, tdata.tile_type, tile.position, self.player.force)
        end
    end
    renderinglib.destroy_renders(tdata)
    tdata.centre                         = nil
    tdata.vertex                         = nil
    tdata.surface                        = nil
    self.elems.tp_centre_text.text       = ""
    self.elems.tp_vertex_text.text       = ""
    self.elems.tp_confirm_button.enabled = false
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
    contents = {
        {
            type = "flow",
            direction = "horizontal",
            {
                type = "label",
                caption = { "gui.tp-tile" },
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
                caption = { "gui.tp-center" },
                tooltip = { "gui.tp-tooltip-position-center" },
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
                caption = { "gui.tp-vertex" },
                tooltip = { "gui.tp-tooltip-position-vertex" },
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
                caption = { "gui.tp-confirm" },
                handler = { [defines.events.on_gui_click] = on_confirm_click },
                enabled = false,
            },
            {
                type = "empty-widget",
                style = "flib_horizontal_pusher",
            },
        },
    },

}

tp_tab_shape.def = templates.tab_heading(tab_def)

--- @class ShapeTabData
--- @field centre MapPosition|nil
--- @field vertex MapPosition|nil
--- @field nsides integer
--- @field tile_type string|nil
--- @field surface uint|nil
--- @field renders {["box"|"polygon"|"centre"|"vertex"]: uint64|nil}

function tp_tab_shape.init(self)
    local tab = {
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
    } --[[@as ShapeTabData]]
    self.tabs["shape"] = tab
end

function tp_tab_shape.hide(self)
    local tdata = self.tabs["shape"] --[[@as ShapeTabData]]
    renderinglib.destroy_renders(tdata)
end

function tp_tab_shape.refresh(self)
    local tdata = self.tabs["shape"] --[[@as ShapeTabData]]
    if tdata.centre ~= nil and tdata.vertex ~= nil then
        renderinglib.draw_prospective_polygon(tdata, self.player)
    end
end

flib_gui.add_handlers({
    on_nsides_text_changed = on_nsides_text_changed,
    on_nsides_slider_changed = on_nsides_slider_changed,
    on_shape_tile_select = on_shape_tile_select,
    on_confirm_click = on_confirm_click,
}, templates.tab_wrapper("shape"))

return tp_tab_shape
