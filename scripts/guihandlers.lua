local gui = require("__tile-painter__/scripts/gui")

--- @class tile_painter_gui
local tile_painter_gui = {}

local tile_painter_gui_handlers = {}

function tile_painter_gui_handlers.tp_picker_item(event)
    local player = game.get_player(event.player_index)
    if player == nil then return end

    local inventory = player.get_main_inventory()
    if inventory == nil then return end

    local item = event.element.tags.item
    player.clear_cursor()
    if item ~= nil then
        local stack, _ = inventory.find_item_stack(item)
        if stack ~= nil then
            player.cursor_stack.transfer_stack(stack)
        end
    end

    -- gui rebuild handled in on_player_cursor_stack_changed
end

function tile_painter_gui_handlers.tp_config_select(event)
    -- TODO: make sure this is only called once by improving listeners calling
    local player = game.get_player(event.player_index)
    if player == nil then return end

    local player_global = global.players[player.index]
    if player_global == nil then return end

    local config = player_global.config[event.element.tags.index]
    if config == nil then return end
    config[event.element.tags.type] = event.element.elem_value
end

function tile_painter_gui_handlers.tp_gui_close(event)
    gui.toggle_interface(event.player_index)
end

return tile_painter_gui_handlers
