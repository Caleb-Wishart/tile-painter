local gui_entity = require("scripts.gui-entity")
local gui_shape = require("scripts.gui-shape")

local gui_config = {
    entity =
    {
        name = "entity",
        cls = gui_entity,
        show_on_open = false,
    },
    shape = {
        name = "shape",
        cls = gui_shape,
        show_on_open = true,
    },
}

--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_shortcut(e)
    local name = e.input_name or e.prototype_name
    local gui = nil
    if name == "tp-get-entity-tool" then
        gui = gui_config.entity
    elseif name == "tp-get-shape-tool" then
        gui = gui_config.shape
    else
        -- not one of our tools
        return
    end
    local player = game.get_player(e.player_index)
    if not player then
        return
    end

    local tool = "tp-" .. gui.name .. "-tool"
    local self = global["gui_" .. gui.name][e.player_index]
    -- if self == nil then
    self = gui.cls.build_gui(player)
    -- end
    if self.elems["tp_" .. gui.name .. "_window"].valid and gui.show_on_open then
        gui.cls.show(self)
    end
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not player.clear_cursor() then
        return
    end
    cursor_stack.set_stack({ name = tool, count = 1 })
end

local shortcut = {}

shortcut.events = {
    [defines.events.on_lua_shortcut] = on_shortcut,
    ["tp-get-entity-tool"] = on_shortcut,
    ["tp-get-shape-tool"] = on_shortcut,
}

return shortcut
