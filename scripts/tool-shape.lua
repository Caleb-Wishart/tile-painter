local renderinglib = require("scripts.rendering")
local position = require("__flib__.position")

--- @param e EventData.CustomInputEvent
local function handle_fill_shape_click(e, isRight)
    if e.item ~= "tile-painter-polygon" then return end

    local self = global.shapes[e.player_index]
    if self == nil then return end
    local position = position.ensure_explicit(e.cursor_position)
    local surface = game.get_player(e.player_index).surface.index
    -- ensure that the position is on the same surface
    if surface ~= self.surface then
        self.centre = nil
        self.vertex = nil
        self.surface = surface
    end
    local location = "(" .. position.x .. "," .. position.y .. ")"
    if isRight then
        self.centre = position
        self.elems.tp_centre_text.text = location
    else
        self.vertex = position
        self.elems.tp_vertex_text.text = location
    end
    if self.centre ~= nil and self.vertex ~= nil then
        renderinglib.draw_prospective_polygon(self)
    end
end

--- @param e EventData.CustomInputEvent
local function on_left_click(e)
    handle_fill_shape_click(e, false)
end

--- @param e EventData.CustomInputEvent
local function on_right_click(e)
    handle_fill_shape_click(e, true)
end

--- @class Tool
local tool = {}

tool.events = {
    ["tile-painter-fill-shape-left-click"] = on_left_click,
    ["tile-painter-fill-shape-right-click"] = on_right_click,
}

return tool
