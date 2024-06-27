local flib_gui = require("__flib__.gui-lite")

-- Max number of config rows
local MAX_CONFIG_ROWS = 6
local CONFIG_ATTRS = 4
local TABLE_COLS = 11

--- @class PainterGui
--- @field elems table<string, LuaGuiElement>
--- @field pinned boolean
--- @field player LuaPlayer
--- @field config table<integer, table>
--- @field inventory_selected string | nil
--- @field whitelist boolean
local gui = {}

function gui.on_init()
    --- @type table<integer, PainterGui>
    global.gui_entity = {}
end

function gui.on_configuration_changed()
    for _, player in pairs(game.players) do
        gui.destroy_gui(player)
    end
end

--- @param e EventData.on_gui_click
local function on_pin_button_click(e)
    local self = global.gui_entity[e.player_index]
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
        self.player.opened = self.elems.tp_entity_window
        self.elems.close_button.tooltip = { "gui.close-instruction" }
    end
end

--- @param e EventData.on_gui_switch_state_changed
local function on_mode_switch(e)
    local self = global.gui_entity[e.player_index]
    self.whitelist = e.element.switch_state == "left"
    gui.populate_config_table(self, game.get_player(e.player_index))
end

--- @param e EventData.on_gui_click
local function on_close_button_click(e)
    local self = global.gui_entity[e.player_index]
    if not self then
        return
    end
    gui.hide(self)
    if self.player.opened == self.elems.tp_entity_window then
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
        table.insert(elems, 3,
            frame_action_button("pin_button", "flib_pin", { 'gui.flib-keep-open' }, on_pin_button_click))
        table.insert(elems, 4,
            frame_action_button("close_button", "utility/close", { "gui.close-instruction" },
                on_close_button_click))
    end

    return elems
end

--- @param e EventData.on_gui_closed
local function on_entity_window_closed(e)
    local self = global.gui_entity[e.player_index]
    if not self or self.pinned then
        return
    end
    gui.hide(self)
end

--- @param player LuaPlayer
function gui.destroy_gui(player)
    if global.gui_entity == nil then
        return
    end
    local self = global.gui_entity[player.index]
    if not self then
        return
    end
    global.gui_entity[player.index] = nil
    local window = self.elems.tp_entity_window
    if not window.valid then
        return
    end
    window.destroy()
end

--- @param player LuaPlayer
--- @return PainterGui
function gui.build_gui(player)
    gui.destroy_gui(player)

    local elems = flib_gui.add(player.gui.screen, {
        type = "frame",
        name = "tp_entity_window",
        visible = false,
        direction = "vertical",
        style = "invisible_frame",
        --- @diagnostic disable-next-line: missing-fields
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = on_entity_window_closed },
        -- Children
        -- Configuration Frame
        {
            type = "frame",
            direction = "vertical",
            name = "tp_config_window",
            style = "inner_frame_in_outer_frame",
            titlebar({ "gui.tp-title-entity-window" }, "tp_entity_window", true),
            {
                type = "frame",
                style = "inside_shallow_frame",
                direction = "vertical",
                {
                    type = "frame",
                    style = "deep_frame_in_shallow_frame",
                    direction = "vertical",
                    {
                        type = "flow",
                        direction = "horizontal",
                        {
                            type = "empty-widget",
                            style = "flib_horizontal_pusher",
                        },
                        {
                            type = "switch",
                            name = "tp_mode_switch",
                            switch_state = "left",
                            left_label_caption = { "gui.whitelist" },
                            left_label_tooltip = { "gui.tp-whitelist-tt-entity" },
                            right_label_caption = { "gui.blacklist" },
                            right_label_tooltip = { "gui.tp-blacklist-tt-entity" },
                            handler = { [defines.events.on_gui_switch_state_changed] = on_mode_switch },
                        },
                        {
                            type = "empty-widget",
                            style = "flib_horizontal_pusher",
                        },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        {
                            type = "table",
                            name = "tp_config_table",
                            style = "slot_table",
                            column_count = TABLE_COLS,
                        },
                    },
                },
            },
        },
        -- Player Inventory Frame
        {
            type = "frame",
            direction = "vertical",
            name = "to_inventory_window",
            style = "tp_inventory_frame",
            titlebar({ "gui.tp-title-inventory-window" }, "tp_entity_window", false),
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
                    },
                },
            },
        },
    })

    local self = {
        elems = elems,
        pinned = false,
        player = player,
        inventory_selected = nil,
        config = {},
        whitelist = true,
    }
    global.gui_entity[player.index] = self

    return self
end

-- GUI Build Utilities

--- @param self PainterGui
function gui.hide(self)
    self.elems.tp_entity_window.visible = false
end

--- @param self PainterGui
function gui.show(self)
    self.elems.tp_entity_window.visible = true
    self.player.opened = self.elems.tp_entity_window
    gui.populate_config_table(self)
    gui.populate_inventory_table(self)
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

    local self = global.gui_entity[player.index]
    if self == nil then return end

    local config = self.config[e.element.tags.index]
    if config == nil then return end
    config[e.element.tags.type] = e.element.elem_value
end

-- GUI Population

--- @param self PainterGui
function gui.populate_config_table(self)
    local function build_heading(tbl)
        local col = math.floor(TABLE_COLS / CONFIG_ATTRS)
        flib_gui.add(tbl, {
            type = "empty-widget",
            style_mods = { horizontally_stretchable = "on" }
        })
        for _ = 1, col do
            flib_gui.add(tbl, {
                type = "label",
                style = "caption_label",
                caption = { "gui.tp-caption-entity" },
                tooltip = { "gui.tp-caption-tt-entity" },
            })
            for i = 0, 2 do
                flib_gui.add(tbl, {
                    type = "label",
                    style = "caption_label",
                    caption = { "gui.tp-caption-tile", i },
                    tooltip = { "gui.tp-caption-tt-tile", i },
                })
            end
            flib_gui.add(tbl, {
                type = "empty-widget",
                style_mods = { horizontally_stretchable = "on" }
            })
        end
    end

    local function build_row(self, tbl, row)
        if self.config[row] == nil then
            self.config[row] = {
                entity = row == 1 and "signal-anything" or nil,
                tile_0 = nil,
                tile_1 = nil,
                tile_2 = nil,
            }
        end

        local config = self.config[row]

        if row == 1 then
            flib_gui.add(tbl, {
                type = "choose-elem-button",
                style = "slot_button",
                elem_type = "signal",
                signal = { type = "virtual", name = "signal-anything" },
                tags = { type = "signal", index = row },
                tooltip = { "gui.tp-anything-tt" },
                enabled = false,
            })
        else
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
                tags = { type = "entity", index = row },
                handler = { [defines.events.on_gui_elem_changed] = on_config_select }
            })
        end

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
                enabled = self.whitelist or row == 1,
                tile = self.whitelist and config[tiles[i]] or nil,
                elem_filters = filter,
                tags = { type = tiles[i], index = row },
                handler = { [defines.events.on_gui_elem_changed] = on_config_select }
            })
        end
    end

    local config_table = self.elems.tp_config_table
    if config_table == nil then return end
    config_table.clear()
    build_heading(config_table)
    -- for row = 1, MAX_CONFIG_ROWS do
    --     build_row(self, config_table, row)
    -- end
    for row = 1, MAX_CONFIG_ROWS * math.floor(TABLE_COLS / CONFIG_ATTRS) do
        if row % 2 == 1 then
            flib_gui.add(config_table, {
                type = "empty-widget",
                style_mods = { horizontally_stretchable = "on" }
            })
        end
        build_row(self, config_table, row)
        flib_gui.add(config_table, {
            type = "empty-widget",
            style_mods = { horizontally_stretchable = "on" }
        })
    end
end

--- @param self PainterGui
function gui.populate_inventory_table(self)
    local player = self.player
    local inventory_table = self.elems.tp_inventory_table
    if inventory_table == nil then return end
    inventory_table.clear()

    local inventory = player.get_main_inventory()
    if inventory == nil then return end
    -- quickly flash insert the cursor stack to get the correct inventory contents
    inventory.insert(player.cursor_stack)
    local contents = inventory.get_contents()
    inventory.remove(player.cursor_stack)

    for item, count in pairs(contents) do
        local sprite = nil
        if self.inventory_selected == item then
            sprite = "utility/hand"
            ---@diagnostic disable-next-line: cast-local-type
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
            handler = { [defines.events.on_gui_click] = on_inventory_selection }
        })
    end
end

--- @param e EventData.on_mod_item_opened
local function on_mod_item_opened(e)
    if e.item.name == "tp-entity-tool" then
        local player = game.get_player(e.player_index)
        if player == nil then return end
        -- local self = global.gui_entity[player.index]
        -- if not self then
        local self = gui.build_gui(player)
        -- end
        gui.show(self)
    end
end

--- @param e EventData.on_player_removed
local function on_player_removed(e)
    global.gui_entity[e.player_index] = nil
end



local function on_player_cursor_stack_changed(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local self = global.gui_entity[e.player_index]
    if not self or self.pinned then
        return
    end

    self.inventory_selected = player.cursor_stack.valid_for_read and player.cursor_stack.name or nil

    if self.player.opened == self.elems.tp_entity_window then
        gui.populate_inventory_table(self)
    end
end

flib_gui.add_handlers({
    on_pin_button_click = on_pin_button_click,
    on_close_button_click = on_close_button_click,
    on_entity_window_closed = on_entity_window_closed,
    on_inventory_selection = on_inventory_selection,
    on_config_select = on_config_select,
    on_mode_switch = on_mode_switch,
})

gui.events = {
    [defines.events.on_mod_item_opened] = on_mod_item_opened,
    [defines.events.on_player_removed] = on_player_removed,
    [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
}



return gui
