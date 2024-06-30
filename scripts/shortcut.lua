local gui = require("scripts.gui.base")

--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_shortcut(e)
    local name = e.input_name or e.prototype_name
    if name ~= "tp-get-tool" then
        -- not one of our tools
        return
    end
    local player = game.get_player(e.player_index)
    if not player then
        return
    end

    local self = global.gui[e.player_index]
    if self == nil then
        self = gui.build_gui(player)
    end
    if self.elems["tp_main_window"].valid then
        gui.show(self)
    end
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not player.clear_cursor() then
        return
    end
    local tool = "tp-tool-" .. self.mode
    cursor_stack.set_stack({ name = tool, count = 1 })
end

local shortcut = {}

shortcut.events = {
    [defines.events.on_lua_shortcut] = on_shortcut,
    ["tp-get-tool"] = on_shortcut,
}

return shortcut
