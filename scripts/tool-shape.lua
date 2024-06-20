local renderinglib = require("scripts.rendering")
local position = require("__flib__.position")
local gui = require("scripts.gui-shape")

--- @param e EventData.CustomInputEvent
local function handle_fill_shape_click(e, isRight)
    local player = game.get_player(e.player_index)
    if player == nil or player.cursor_stack.valid_for_read and player.cursor_stack.name ~= "tile-painter-polygon" then
        return
    end
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
        self.elems.tp_confirm_button.enabled = true
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

--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_shortcut(e)
    local name = e.input_name or e.prototype_name
    if name ~= "tile-painter-shape" then
        return
    end
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == "tile-painter-polygon" then
        local self = global.gui[e.player_index]
        if self == nil then
            self = gui.build_gui(player)
        end
        if self and self.elems.tp_shape_window.valid then
            gui.show(self)
        end
        return
    end
    if not cursor_stack or not player.clear_cursor() then
        return
    end
    cursor_stack.set_stack({ name = "tile-painter-polygon", count = 1 })
end

--- @class Tool
local tool = {}

tool.events = {
    ["tile-painter-fill-shape-left-click"] = on_left_click,
    ["tile-painter-fill-shape-right-click"] = on_right_click,
    ["tile-painter-shape"] = on_shortcut,
    [defines.events.on_lua_shortcut] = on_shortcut,

}

return tool
