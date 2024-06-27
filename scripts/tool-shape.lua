local position = require("__flib__.position")

local renderinglib = require("scripts.rendering")

--- @param e EventData.CustomInputEvent
local function handle_fill_shape_click(e, isRight)
    local player = game.get_player(e.player_index)
    if player == nil or player.cursor_stack.valid_for_read and player.cursor_stack.name ~= "tp-shape-tool" then
        return
    end
    local self = global.gui_shape[e.player_index]
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
        self.elems.tp_confirm_button.enabled = self.tile_type ~= nil
        renderinglib.draw_prospective_polygon(self)
    else
        self.elems.tp_confirm_button.enabled = false
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
    ["tp-fill-shape-left-click"] = on_left_click,
    ["tp-fill-shape-right-click"] = on_right_click,
}

return tool
