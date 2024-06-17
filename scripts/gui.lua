local flib_gui = require("__flib__.gui-lite")
local util = require("util")

-- Max number of config rows
local MAX_CONFIG_ROWS = 6
local CONFIG_ATTRS = 4


local function initialize_player(player)
    local function init_attr(tbl, attr_name, default)
        if tbl[attr_name] == nil then
            tbl[attr_name] = default
        end
    end
    if global.players[player.index] == nil then
        global.players[player.index] = {}
    end
    local player_data = global.players[player.index]
    init_attr(player_data, "inventory_selected", nil)
    init_attr(player_data, "elements", {})
    init_attr(player_data, "config", {})
    init_attr(player_data, "mode", "entity")
    init_attr(player_data, "shape_fill", {})
    init_attr(player_data.shape_fill, "centre", nil)
    init_attr(player_data.shape_fill, "vertex", nil)
    init_attr(player_data.shape_fill, "surface", nil)
end

--- @class Gui
--- @field elems table<string, LuaGuiElement>
--- @field pinned boolean
--- @field player LuaPlayer
local gui = {}

function gui.on_init()
    --- @type table<integer, Gui>
    global.gui = {}

    if global.players == nil then
        global.players = {}
    end
    for _, player in pairs(game.players) do
        initialize_player(player)
    end
end

--- @param e EventData.on_gui_click
local function on_pin_button_click(e)
    local self = global.gui[e.player_index]
    if not self then
        return
    end
    local pinned = not self.pinned
    e.element.sprite = pinned and "flib_pin_black" or "flib_pin_white"
    e.element.style = pinned and "flib_selected_frame_action_button" or "frame_action_button"
    self.pinned = pinned
    if pinned then
        self.player.opened = nil
        self.elems.close_button.tooltip = { "gui.close" }
    else
        self.player.opened = self.elems.tp_window
        self.elems.close_button.tooltip = { "gui.close-instruction" }
    end
end

--- @param e EventData.on_gui_click
local function on_close_button_click(e)
    local self = global.gui[e.player_index]
    if not self then
        return
    end
    gui.hide(self)
    if self.player.opened == self.elems.tp_window then
        self.player.opened = nil
    end
end

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler function
local function frame_action_button(name, sprite, tooltip, handler)
    return {
        type = "sprite-button",
        name = name,
        style = "frame_action_button",
        sprite = sprite .. "_white",
        hovered_sprite = sprite .. "_black",
        clicked_sprite = sprite .. "_black",
        tooltip = tooltip,
        handler = handler,
    }
end

--- @param caption LocalisedString
---@param target string
---@param close boolean
local function titlebar(caption, target, close)
    local elems = {
        type = "flow",
        style = "flib_titlebar_flow",
        drag_target = target,
        {
            type = "label",
            style = "frame_title",
            caption = caption,
            ignored_by_interaction = true,
        },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
    }

    if close then
        table.insert(elems,
            frame_action_button("pin_button", "flib_pin", { 'gui.flib-keep-open' }, on_pin_button_click))
        table.insert(elems,
            frame_action_button("close_button", "utility/close", { "gui.close-instruction" },
                on_close_button_click))
    end

    return elems
end

--- @param e EventData.on_gui_closed
local function on_window_closed(e)
    local self = global.gui[e.player_index]
    if not self or self.pinned then
        return
    end
    gui.hide(self)
end

--- @param player LuaPlayer
function gui.destroy_gui(player)
    local self = global.gui[player.index]
    if not self then
        return
    end
    global.gui[player.index] = nil
    local window = self.elems.tp_window
    if not window.valid then
        return
    end
    window.destroy()
end

--- @param player LuaPlayer
--- @return Gui
function gui.build_gui(player)
    gui.destroy_gui(player)

    local elems = flib_gui.add(player.gui.screen, {
        type = "frame",
        name = "tp_window",
        visible = false,
        direction = "vertical",
        style = "invisible_frame",
        --- @diagnostic disable-next-line: missing-fields
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = on_window_closed },
        -- Children
        -- Configuration Frame
        {
            type = "frame",
            direction = "vertical",
            name = "tp_config_window",
            style = "inner_frame_in_outer_frame",
            {
                titlebar({ "tile_painter_gui.tile_painter_title" }, "tp_window", true),
                {
                    type = "frame",
                    style = "inside_shallow_frame",
                    direction = "vertical",
                    {
                        type = "frame",
                        style = "deep_frame_in_shallow_frame",
                        {
                            type = "flow",
                            direction = "horizontal",
                            {
                                type = "table",
                                name = "tp_config_table",
                                style = "slot_table",
                                column_count = 9,
                            }
                        }
                    }
                }
            }
        },
        -- Player Inventory Frame
        {
            type = "frame",
            direction = "vertical",
            name = "to_inventory_window",
            style = "tp_inventory_frame",
            {
                titlebar({ "tile_painter_gui.inventory_title" }, "tp_window", false),
                {
                    type = "frame",
                    style = "inventory_frame",
                    {
                        type = "scroll-pane",
                        direction = "vertical",
                        style = "tp_inventory_scroll_pane",
                        {
                            type = "table",
                            name = "tp_inventory_table",
                            style = "slot_table",
                            column_count = 10,
                        }
                    }
                }
            }
        },
    })

    local self = {
        elems = elems,
        pinned = false,
        player = player,
    }
    global.gui[player.index] = self

    return self
end

-- GUI Build Utilities

--- @param self Gui
function gui.hide(self)
    self.elems.tp_window.visible = false
end

--- @param e EventData.on_gui_click
local function on_inventory_selection(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local inventory = player.get_main_inventory()
    if inventory == nil then return end

    local item = e.element.tags.item
    player.clear_cursor()
    if item ~= nil then
        local stack, _ = inventory.find_item_stack(item)
        if stack ~= nil then
            player.cursor_stack.transfer_stack(stack)
        end
    end
end

--- @param e EventData.on_gui_elem_changed
local function on_config_select(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local player_global = global.players[player.index]
    if player_global == nil then return end

    local config = player_global.config[e.element.tags.index]
    if config == nil then return end
    config[e.element.tags.type] = e.element.elem_value
end

-- GUI Population

--- @param self Gui
--- @param player LuaPlayer
function gui.populate_config_table(self, player)
    local function build_heading(tbl)
        local headings = {
            "entity_caption",
            "tile_caption_0",
            "tile_caption_1",
            "tile_caption_2",
        }
        for i = 1, #headings do
            if i ~= 1 then
                tbl.add {
                    type = "empty-widget",
                }.style.horizontally_stretchable = "on"
            end
            tbl.add {
                type = "label",
                style = "caption_label",
                caption = { "tile_painter_gui." .. headings[i] },
                tooltip = { "tile_painter_gui." .. headings[i] .. "_tt" },
            }
        end
    end

    local function build_row(tbl, row, player_data)
        if row > MAX_CONFIG_ROWS then return end
        if player_data.config == nil then player_data.config = {} end
        local col = (CONFIG_ATTRS // 2) + 1
        local index = (col - 1) * MAX_CONFIG_ROWS + (row % CONFIG_ATTRS)
        if player_data.config[index] == nil then
            player_data.config[index] = {
                entity = nil,
                tile_0 = nil,
                tile_1 = nil,
                tile_2 = nil,
            }
        end

        local config = player_data.config[index]

        flib_gui.add(tbl, {
            type = "choose-elem-button",
            style = "slot_button",
            elem_type = "entity",
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
            tags = { type = "entity", index = index },
            handler = { [defines.events.on_gui_elem_changed] = on_config_select }
        })
        flib_gui.add(tbl, {
            type = "empty-widget",
            style_mods = { horizontally_stretchable = "on" }
        })
        local filter = { { filter = "blueprintable", mode = "and" } }
        local tiles = {
            "tile_0",
            "tile_1",
            "tile_2",
        }
        for i = 1, #tiles do
            flib_gui.add(tbl, {
                type = "choose-elem-button",
                style = "slot_button",
                elem_type = "tile",
                tile = config[tiles[i]],
                elem_filters = filter,
                tags = { type = tiles[i], index = index },
                handler = { [defines.events.on_gui_elem_changed] = on_config_select }
            })
        end
    end

    local player_data = global.players[player.index]
    local config_table = self.elems.tp_config_table
    config_table.clear()
    build_heading(config_table)
    for row = 1, MAX_CONFIG_ROWS do
        build_row(config_table, row, player_data)
    end
end

--- @param self Gui
--- @param player LuaPlayer
function gui.populate_inventory_table(self, player)
    local player_data = global.players[player.index]
    local inventory_table = self.elems.tp_inventory_table
    inventory_table.clear()

    local inventory = player.get_main_inventory()
    -- quickly flash insert the cursor stack to get the correct inventory contents
    inventory.insert(player.cursor_stack)
    local contents = inventory.get_contents()
    inventory.remove(player.cursor_stack)

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
        }
        flib_gui.add(inventory_table, {
            type = "sprite-button",
            sprite = sprite,
            number = count,
            style = "slot_button",
            tags = tags,
            handler = { [defines.events.on_gui_click] = gui.on_inventory_selection }
        })
    end
end

--- @param e EventData.on_mod_item_opened
local function on_mod_item_opened(e)
    if e.item.name == util.defines.item_name then
        gui.toggle_interface(e.player_index)
    end
end

--- @param e EventData.on_player_created
local function on_player_created(e)
    local player = game.get_player(e.player_index)
    initialize_player(player)
end

--- @param e EventData.on_player_removed
local function on_player_removed(e)
    global.players[e.player_index] = nil
end



local function on_player_cursor_stack_changed(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local self = global.gui[e.player_index]
    if not self or self.pinned then
        return
    end

    local player_global = global.players[player.index]
    if player_global == nil then return end

    player_global.inventory_selected = player.cursor_stack.valid_for_read and player.cursor_stack.name or nil

    if player_global.elements.main_frame ~= nil then
        gui.populate_inventory_table(self, player)
    end
end

flib_gui.add_handlers({
    on_pin_button_click = on_pin_button_click,
    on_close_button_click = on_close_button_click,
    on_window_closed = on_window_closed,
    on_inventory_selection = on_inventory_selection,
    on_config_select = on_config_select,
})

gui.events = {
    [defines.events.on_mod_item_opened] = on_mod_item_opened,
    [defines.events.on_player_created] = on_player_created,
    [defines.events.on_player_removed] = on_player_removed,
    [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
}



return gui
