local flib_math = require("__flib__.math")

local position = require("__flib__.position")

local renderinglib = require("scripts.rendering")

--- @param e EventData.CustomInputEvent
local function handle_fill_shape_click(e, isRight)
    local player = game.get_player(e.player_index)
    if player == nil or (player.cursor_stack.valid_for_read and player.cursor_stack.name ~= "tp-tool-shape") then
        return
    end
    local self = global.gui[e.player_index]
    if self == nil then return end
    if self.mode ~= "shape" or not self.elems.tp_main_window.visible then return end

    local tdata = self.tabs["shape"]
    if tdata == nil then return end

    local position = position.ensure_explicit(e.cursor_position)
    local surface = game.get_player(e.player_index).surface.index
    -- ensure that the position is on the same surface
    if surface ~= tdata.surface then
        tdata.centre = nil
        tdata.vertex = nil
        tdata.surface = surface
    end
    local location = "(" .. flib_math.round_to(position.x, 2) .. "," .. flib_math.round_to(position.y, 2) .. ")"
    if isRight then
        tdata.centre = position
        self.elems.tp_centre_text.text = location
    else
        tdata.vertex = position
        self.elems.tp_vertex_text.text = location
    end
    if tdata.centre ~= nil and tdata.vertex ~= nil then
        self.elems.tp_confirm_button.enabled = tdata.tile_type ~= nil
        renderinglib.draw_prospective_polygon(tdata, self.player)
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
