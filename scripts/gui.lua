local util = require("__tile-painter__/util")
local mod_prefix = util.defines.mod_prefix

-- Max number of config rows
MAX_CONFIG_ROWS = 6
MAX_CONFIG_COLS = 2

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

local function build_config_row(parent, row, col, player_global)
    if row > MAX_CONFIG_ROWS then return end
    if player_global.config == nil then player_global.config = {} end
    local index = (col - 1) * MAX_CONFIG_ROWS + row
    if player_global.config[index] == nil then
        player_global.config[index] = {
            entity = nil,
            tile_0 = nil,
            tile_1 = nil,
            tile_2 = nil,
        }
    end
    local config = player_global.config[index]
    parent.add {
        type = "choose-elem-button",
        elem_type = "entity",
        style = "slot_button",
        entity = config.entity,

        elem_filters = {
            { filter = "blueprintable", mode = "and" },
            { filter = "rolling-stock", mode = "and", invert = true },
            { filter = "hidden",        mode = "and", invert = true },
            { filter = "flag",          mode = "and", invert = true, flag = "placeable-off-grid" },
            -- Other / Hidden / Cheat Entities
            { filter = "name",          mode = "and", invert = true, name = "infinity-chest" },
            { filter = "name",          mode = "and", invert = true, name = "infinity-pipe" },
            { filter = "name",          mode = "and", invert = true, name = "simple-entity-with-force" },
            { filter = "name",          mode = "and", invert = true, name = "simple-entity-with-owner" },
            { filter = "name",          mode = "and", invert = true, name = "linked-chest" },
            { filter = "name",          mode = "and", invert = true, name = "linked-belt" },
            { filter = "name",          mode = "and", invert = true, name = "burner-generator" },
            { filter = "name",          mode = "and", invert = true, name = "electric-energy-interface" },
            { filter = "name",          mode = "and", invert = true, name = "heat-interface" },
        },
        -- elem_filters = { { filter = "hidden", invert = true, mode = "and" } }
        -- TODO fun hidden setting to enable placing on enemy spawners
        tags = { action = "tp_config_select", type = "entity", index = index },
    }
    parent.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = "on"
    local filter = { { filter = "blueprintable", mode = "and" } }
    parent.add {
        type = "choose-elem-button",
        elem_type = "tile",
        style = "slot_button",
        tile = config.tile_0,
        elem_filters = filter,
        -- TODO
        tags = { action = "tp_config_select", type = "tile_0", index = index },
    }
    parent.add {
        type = "choose-elem-button",
        elem_type = "tile",
        style = "slot_button",
        tile = config.tile_1,
        elem_filters = filter,
        tags = { action = "tp_config_select", type = "tile_1", index = index },
    }
    parent.add {
        type = "choose-elem-button",
        elem_type = "tile",
        style = "slot_button",
        tile = config.tile_2,
        elem_filters = filter,
        tags = { action = "tp_config_select", type = "tile_2", index = index },
    }
end

local function build_config_interface(parent, player_global)
    local config_window = parent.add { type = "frame", name = (mod_prefix .. "_tile_painter_window"), style = "inner_frame_in_outer_frame", direction = "vertical" }
    -- config_window.style.size = { 448, 372 }
    build_titlebar(config_window, { "tile_painter_gui.tile_painter_title" }, parent, true)

    local config_window_frame = config_window.add({
        type = "frame",
        style = "inside_shallow_frame",
    })

    local frame2 = config_window_frame.add({
        type = "frame",
        style = "deep_frame_in_shallow_frame",
    })

    local config_flow = frame2.add {
        type = "flow",
        direction = "horizontal",
    }
    config_flow.add {
        type = "empty-widget",
    }.style.horizontally_stretchable = "on"

    for col = 1, MAX_CONFIG_COLS do
        local config_table = config_flow.add {
            type = "table",
            column_count = 6,
            style = "slot_table",
        }
        if col == 2 then
            config_table.add {
                type = "empty-widget",
            }.style.horizontally_stretchable = "on"
        end
        config_table.add {
            type = "label",
            caption = { "tile_painter_gui.entity_caption" },
            tooltip = { "tile_painter_gui.entity_caption_tt" },
            style = "caption_label",
        }
        config_table.add {
            type = "empty-widget",
        }.style.horizontally_stretchable = "on"
        config_table.add {
            type = "label",
            caption = { "tile_painter_gui.tile_caption_0" },
            tooltip = { "tile_painter_gui.tile_caption_0_tt" },
            style = "caption_label",
        }
        config_table.add {
            type = "label",
            caption = { "tile_painter_gui.tile_caption_1" },
            tooltip = { "tile_painter_gui.tile_caption_1_tt" },
            style = "caption_label",
        }
        config_table.add {
            type = "label",
            caption = { "tile_painter_gui.tile_caption_2" },
            tooltip = { "tile_painter_gui.tile_caption_2_tt" },
            style = "caption_label",
        }
        if col == 1 then
            config_table.add {
                type = "empty-widget",
            }.style.horizontally_stretchable = "on"
        end
        for row = 1, MAX_CONFIG_ROWS * MAX_CONFIG_COLS do
            if col == 2 then
                config_table.add {
                    type = "empty-widget",
                }.style.horizontally_stretchable = "on"
            end
            build_config_row(config_table, row, col, player_global)
            if col == 1 then
                config_table.add {
                    type = "empty-widget",
                }.style.horizontally_stretchable = "on"
            end
        end
        config_flow.add {
            type = "empty-widget",
        }.style.horizontally_stretchable = "on"
    end
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
