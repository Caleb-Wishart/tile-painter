local flib_gui = require("__flib__.gui-lite")
local flib_position = require("__flib__.position")

local tabs = {
    entity = require("scripts.gui.tab-entity"),
    shape = require("scripts.gui.tab-shape"),
    -- fill = require("scripts.gui.tab-fill"),
}

local templates = require("scripts.gui.templates")

--- @class Gui
--- @field elems table<string, LuaGuiElement>
--- @field pinned boolean
--- @field player LuaPlayer
--- @field inventory_selected string|nil
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
local function on_pin_button_click(e, self)
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

-- Thx Raiguard
--- @type GuiLocation
local top_left_location = { x = 15, y = 58 + 15 }

--- @param self Gui
local function reset_location(self)
    local value = self.player.mod_settings["tp-default-gui-location"].value
    local window = self.elems.tp_main_window
    if value == "top-left" then
        local scale = self.player.display_scale
        window.location = flib_position.mul(top_left_location, { scale, scale })
    else
        window.auto_center = true
    end
end

--- @param e EventData.on_gui_click
local function on_titlebar_click(e, self)
    if e.button ~= defines.mouse_button_type.middle then
        return
    end
    reset_location(self)
end

--- @param e EventData.on_gui_click
local function on_close_button_click(e, self)
    gui.hide(self)
end

--- @param e EventData.on_gui_closed
local function on_main_window_closed(e, self)
    if self.pinned then
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
        style_mods = { width = 448 },
        handler = { [defines.events.on_gui_closed] = on_main_window_closed },
        -- Children
        -- Configuration Frame
        {
            type = "frame",
            direction = "vertical",
            name = "tp_config_window",
            style = "inner_frame_in_outer_frame",
            templates.titlebar({ "gui.tp-title-main-window" }, "tp_main_window",
                {
                    on_close_handler = on_close_button_click,
                    on_pin_handler = on_pin_button_click,
                    on_titlebar_click_handler =
                        on_titlebar_click
                }),
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

    reset_location(self)

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
    if self.player.opened == self.elems.tp_main_window then
        self.player.opened = nil
    end
    if self.player.cursor_stack.valid_for_read and self.player.cursor_stack.name:sub(1, 8) == "tp-tool-" then
        self.player.clear_cursor()
    end
end

--- @param self Gui
function gui.show(self)
    self.elems.tp_main_window.visible = true
    self.player.opened = self.elems.tp_main_window
    local tab = tabs[self.mode]
    if tab.refresh then
        tab.refresh(self)
    end
end

--- @param e EventData.on_player_removed
local function on_player_removed(e)
    global.gui[e.player_index] = nil
end

--- @param e EventData.on_player_cursor_stack_changed
local function on_player_cursor_stack_changed(e)
    local self = global.gui[e.player_index]
    if not self then
        return
    end
    local cursor_stack = self.player.cursor_stack --[[@as LuaItemStack]]
    local last_stack = self.inventory_selected
    if last_stack == nil then last_stack = "" end
    if cursor_stack.valid_for_read then
        self.inventory_selected = cursor_stack.name
        if cursor_stack.name ~= last_stack
            and last_stack:sub(1, 8) == "tp-tool-"
            and cursor_stack.name:sub(1, 8) ~= "tp-tool-"
        then
            gui.hide(self)
        end
    end
end

--- @param e EventData.on_gui_selected_tab_changed
local function on_header_tab_selected(e)
    local self = global.gui[e.player_index]
    if self == nil then return end
    -- try and filter out if this is not our tab
    local tabAndContent = e.element.tabs[e.element.selected_tab_index]
    local tags = tabAndContent.tab.tags
    if tags == nil or tags.mod ~= "tile-painter" then return end
    local tab = tabs[self.mode]
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

--- @param e {player_index: uint}
local function wrapper(e, handler)
    local self = global.gui[e.player_index]
    if self == nil then return end
    handler(e, self)
end

--- @param e EventData.CustomInputEvent
local function on_next_tool(e)
    local self = global.gui[e.player_index]
    if self == nil then return end
    local tab_elems = self.elems.tp_header_tabs
    local selected = tab_elems.selected_tab_index or 1
    if selected == #tab_elems.tabs then
        selected = 1
    else
        selected = selected + 1
    end
    tab_elems.selected_tab_index = selected
    ---@diagnostic disable-next-line: missing-fields
    on_header_tab_selected({ player_index = e.player_index, element = tab_elems })
end

--- @param e EventData.CustomInputEvent
local function on_previous_tool(e)
    local self = global.gui[e.player_index]
    if self == nil then return end
    local tab_elems = self.elems.tp_header_tabs
    local selected = tab_elems.selected_tab_index or 1
    if selected == 1 then
        selected = #tab_elems.tabs
    else
        selected = selected - 1
    end
    tab_elems.selected_tab_index = selected
    ---@diagnostic disable-next-line: missing-fields
    on_header_tab_selected({ player_index = e.player_index, element = tab_elems })
end

--- @param e EventData.CustomInputEvent
local function on_next_setting(e)
    local self = global.gui[e.player_index]
    if self == nil then return end
    local tab = tabs[self.mode]
    if tab.on_next_setting then
        ---@diagnostic disable-next-line: param-type-mismatch
        -- Disable to match for any tab type
        tab.on_next_setting(self, self.tabs[self.mode])
    end
end

--- @param e EventData.CustomInputEvent
local function on_previous_setting(e)
    local self = global.gui[e.player_index]
    if self == nil then return end
    local tab = tabs[self.mode]
    if tab.on_previous_setting then
        ---@diagnostic disable-next-line: param-type-mismatch
        -- Disable to match for any tab type
        tab.on_previous_setting(self, self.tabs[self.mode])
    end
end

flib_gui.add_handlers({
    on_pin_button_click = on_pin_button_click,
    on_close_button_click = on_close_button_click,
    on_entity_window_closed = on_main_window_closed,
    on_titlebar_click = on_titlebar_click,
}, wrapper)

gui.events = {
    [defines.events.on_player_removed] = on_player_removed,
    [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
    [defines.events.on_gui_selected_tab_changed] = on_header_tab_selected,
    ["tp-next-tool"] = on_next_tool,
    ["tp-previous-tool"] = on_previous_tool,
    ["tp-next-tool-setting"] = on_next_setting,
    ["tp-previous-tool-setting"] = on_previous_setting,
}

return gui
