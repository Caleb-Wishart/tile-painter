local util = require("__tile-painter__/util")
local mod_prefix = util.defines.mod_prefix

--- @class tile_painter_gui
local tile_painter_gui = {}

local function build_titlebar(parent, caption, target, close)
    local titlebar = parent.add {
        type = "flow",
        direction = "horizontal",
        style = "tp_flow_titlebar",
    }
    titlebar.drag_target = target

    local title = titlebar.add({
        type = "label",
        caption = caption,
        style = "tp_titlebar_label",
    })
    title.drag_target = target

    local handle = titlebar.add({
        type = "empty-widget",
        style = "tp_titlebar_handle",
    })
    handle.drag_target = target
    if close then
        titlebar.add {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            hovered_sprite = "utility/close_black",
            clicked_sprite = "utility/close_black",
            mouse_button_filter = { "left" },
            tags = { action = "tp_gui_close" },
        }
    end
end

function tile_painter_gui.build_character_inventory(player, player_data)
    local character_inventory_table = player_data.elements.character_inventory_table
    character_inventory_table.clear()
    -- TODO: remove debug
    util.print("building character inventory", nil)

    -- copy the table so we can correctly place the hand icone
    local inventory = player.get_main_inventory()
    -- quickly flash insert the cursor stack to get the correct inventory contents
    inventory.insert(player.cursor_stack)
    local contents = inventory.get_contents()
    inventory.remove(player.cursor_stack)
    -- TODO: Filter based on buildable items
    for item, count in pairs(contents) do
        local sprite = nil
        if player_data.inventory_selected == item then
            sprite = "utility/hand"
            count = nil
        else
            sprite = "item/" .. item
        end
        local tags = {
            item = item,
            number = count,
            action = "tp_picker_item",
        }
        character_inventory_table.add({
            type = "sprite-button",
            sprite = sprite,
            number = count,
            style = "slot_button",
            tags = tags,
        })
    end
end

local function build_character_interface(parent, player, player_global)
    local character_window = parent.add { type = "frame", name = (mod_prefix .. "_character_window"), style = "tp_character_frame", direction = "vertical" }
    -- character_window.style.size = { 448, 558 }
    build_titlebar(character_window, { "tile_painter_gui.character_title" }, parent, false)


    local character_inventory_frame = character_window.add({
        type = "frame",
        name = (mod_prefix .. "_character_inventory_frame"),
        style = "inventory_frame",
    })

    local character_inventory = character_inventory_frame.add({
        type = "scroll-pane",
        direction = "vertical",
        style = "tp_character_inventory_scroll_pane",
    })

    local character_inventory_table = character_inventory.add({
        type = "table",
        name = (mod_prefix .. "_character_inventory_table"),
        column_count = 10,
        style = "slot_table",
    })
    player_global.elements.character_inventory_table = character_inventory_table
    tile_painter_gui.build_character_inventory(player, player_global)
end

local function build_config_interface(parent, player_global)
    local config_window = parent.add { type = "frame", name = (mod_prefix .. "_tile_painter_window"), style = "inner_frame_in_outer_frame", direction = "vertical" }
    -- config_window.style.size = { 448, 372 }
    build_titlebar(config_window, { "tile_painter_gui.tile_painter_title" }, parent, true)

    config_window.add({
        type = "label",
        name = (mod_prefix .. "_config_label"),
        caption = "test",
        style = "frame_title",
    })
end

local function build_interface(index)
    local player = game.get_player(index)
    if player == nil then return end

    local player_global = global.players[index]
    local screen_element = player.gui.screen

    local main_frame = screen_element.add { type = "frame", name = (mod_prefix .. "_main_frame"), style = "invisible_frame", direction = "vertical" }

    main_frame.auto_center = true

    player.opened = main_frame
    player_global.elements.main_frame = main_frame

    build_config_interface(main_frame, player_global)
    build_character_interface(main_frame, player, player_global)
end

function tile_painter_gui.toggle_interface(index)
    local player_global = global.players[index]
    local main_frame = player_global.elements.main_frame

    if main_frame == nil then
        build_interface(index)
    else
        main_frame.destroy()
        player_global.elements = {}
    end
end

return tile_painter_gui
