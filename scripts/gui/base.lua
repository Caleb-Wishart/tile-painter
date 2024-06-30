local flib_gui = require("__flib__.gui-lite")

local tab_entity = require("scripts.gui.tab-entity")
local tab_shape = require("scripts.gui.tab-shape")
local tab_fill = require("scripts.gui.tab-fill")

local tabs = {
    entity = tab_entity,
    shape = tab_shape,
    fill = tab_fill,
}

local templates = require("scripts.gui.templates")

--- @class Gui
--- @field elems table<string, LuaGuiElement>
--- @field pinned boolean
--- @field player LuaPlayer
--- @field inventory_selected string | nil
--- @field mode string
--- @field tabs { entity: EntityTabData, shape: ShapeTabData, fill: FillTabData }
local gui = {}

function gui.on_init()
    --- @type table<integer, Gui>
    global.gui = {}
end

function gui.on_configuration_changed()
    for _, player in pairs(game.players) do
        gui.destroy_gui(player)
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
        self.player.opened = self.elems.tp_main_window
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
    if self.player.opened == self.elems.tp_main_window then
        self.player.opened = nil
    end

    self.player.clear_cursor()
end

--- @param e EventData.on_gui_closed
local function on_entity_window_closed(e)
    local self = global.gui[e.player_index]
    if not self or self.pinned then
        return
    end
    gui.hide(self)
end

--- @param player LuaPlayer
function gui.destroy_gui(player)
    if global.gui == nil then
        return
    end
    local self = global.gui[player.index]
    if not self then
        return
    end
    global.gui[player.index] = nil
    local window = self.elems.tp_main_window
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
        name = "tp_main_window",
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
            templates.titlebar({ "gui.tp-title-main-window" }, "tp_main_window",
                { on_close_handler = on_close_button_click, on_pin_handler = on_pin_button_click }),
            {
                type = "frame",
                style = "tp_inside_frame",
                direction = "vertical",
                {
                    type = "tabbed-pane",
                    name = "tp_header_tabs",
                    style = "tp_tabbed_pane",
                    -- Tabs are added below
                },
            },
        },
        -- Player Inventory Frame
        {
            type = "frame",
            direction = "vertical",
            name = "to_inventory_window",
            style = "tp_inventory_frame",
            templates.titlebar({ "gui.tp-title-inventory-window" }, "tp_main_window"),
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

    for _, tab in pairs(tabs) do
        flib_gui.add(elems.tp_header_tabs, tab.def, elems)
    end

    local self = {
        elems = elems,
        pinned = false,
        player = player,
        inventory_selected = nil,
        mode = "entity",
        tabs = {},
    }
    global.gui[player.index] = self

    for _, tab in pairs(tabs) do
        tab.init(self)
    end

    return self
end

-- GUI Build Utilities

--- @param self Gui
function gui.hide(self)
    self.elems.tp_main_window.visible = false
    local tab = tabs[self.mode]
    if tab.hide then
        tab.hide(self)
    end
end

--- @param self Gui
function gui.show(self)
    self.elems.tp_main_window.visible = true
    self.player.opened = self.elems.tp_main_window
    gui.populate_inventory_table(self)
    local tab = tabs[self.mode]
    if tab.refresh then
        tab.refresh(self)
    end
end

--- @param e EventData.on_gui_click
local function on_inventory_selection(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local inventory = player.get_main_inventory()
    if inventory == nil then return end

    local item = e.element.tags.item --[[@as string]]
    player.clear_cursor()
    if item ~= nil then
        local stack, _ = inventory.find_item_stack(item)
        if stack ~= nil then
            player.cursor_stack.transfer_stack(stack)
        end
    end
end

--- @param self Gui
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
    if e.item.name == "tp-tool-entity" then
        local player = game.get_player(e.player_index)
        if player == nil then return end
        -- local self = global.gui[player.index]
        -- if not self then
        local self = gui.build_gui(player)
        -- end
        gui.show(self)
    end
end

--- @param e EventData.on_player_removed
local function on_player_removed(e)
    global.gui[e.player_index] = nil
end

local function on_player_cursor_stack_changed(e)
    local player = game.get_player(e.player_index)
    if player == nil then return end

    local self = global.gui[e.player_index]
    if not self or self.pinned then
        return
    end

    self.inventory_selected = player.cursor_stack.valid_for_read and player.cursor_stack.name or nil

    if self.player.opened == self.elems.tp_main_window then
        gui.populate_inventory_table(self)
    end
end

--- @param e EventData.on_gui_selected_tab_changed
local function on_header_tab_selected(e)
    local self = global.gui[e.player_index]
    if self == nil then return end
    -- try and filter out if this is not our tab
    local tabAndContent = e.element.tabs[e.element.selected_tab_index]
    local tags = tabAndContent.tab.tags
    if tags == nil or tags.mod ~= "TilePainter" then return end
    local tab = tabs[self.mode]
    game.print("Selected tab: " .. tags.name .. " was " .. self.mode)
    if tab.hide then
        tab.hide(self)
    end
    self.mode = tags.name --[[@as string]]
    tab = tabs[self.mode]
    if tab.refresh then
        tab.refresh(self)
    end
    local cursor_stack = self.player.cursor_stack
    if not cursor_stack or not self.player.clear_cursor() then
        return
    end
    local tool = "tp-tool-" .. self.mode
    cursor_stack.set_stack({ name = tool, count = 1 })
end

flib_gui.add_handlers({
    on_pin_button_click = on_pin_button_click,
    on_close_button_click = on_close_button_click,
    on_entity_window_closed = on_entity_window_closed,
    on_inventory_selection = on_inventory_selection,
})

gui.events = {
    [defines.events.on_mod_item_opened] = on_mod_item_opened,
    [defines.events.on_player_removed] = on_player_removed,
    [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
    [defines.events.on_gui_selected_tab_changed] = on_header_tab_selected,
}

return gui
