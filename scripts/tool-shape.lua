local flib_position = require("__flib__.position")

local gui = require("scripts.gui.tab-shape")

local function center_on_tile(position)
    return flib_position.add(flib_position.to_tile(position), { 0.5, 0.5 })
end

--- @param e EventData.CustomInputEvent
local function handle_fill_shape_click(e, isRight, isForced)
    local player = game.get_player(e.player_index)
    if player == nil then
        return
    end
    local cursor_stack = player.cursor_stack
    if cursor_stack == nil or not cursor_stack.valid_for_read or cursor_stack.name ~= "tp-tool-shape" then
        return
    end
    local self = storage.gui[e.player_index]
    if self == nil then
        return
    end
    if self.mode ~= "shape" or not self.elems.tp_main_window.visible then
        return
    end

    local tdata = self.tabs["shape"]
    if tdata == nil then
        return
    end

    local position = flib_position.ensure_explicit(e.cursor_position)
    if not isForced then
        position = center_on_tile(position)
    end
    local surface = game.get_player(e.player_index).surface.index
    gui.on_position_changed(self, position, surface, isRight)
end

--- @param e EventData.CustomInputEvent
local function on_left_click(e)
    handle_fill_shape_click(e, false, false)
end

--- @param e EventData.CustomInputEvent
local function on_right_click(e)
    handle_fill_shape_click(e, true, false)
end

--- @param e EventData.CustomInputEvent
local function on_left_click_forced(e)
    handle_fill_shape_click(e, false, true)
end

--- @param e EventData.CustomInputEvent
local function on_right_click_forced(e)
    handle_fill_shape_click(e, true, true)
end

--- @class ToolShape
local tool = {}

tool.events = {
    ["tp-fill-shape-left-click"] = on_left_click,
    ["tp-fill-shape-right-click"] = on_right_click,
    ["tp-fill-shape-left-click-forced"] = on_left_click_forced,
    ["tp-fill-shape-right-click-forced"] = on_right_click_forced,
}

return tool
