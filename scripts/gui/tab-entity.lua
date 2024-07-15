local flib_gui = require("__flib__.gui-lite")

local templates = require("scripts.gui.templates")

local base64 = require("lib.base64")

local MAX_CONFIG_ROWS = 7
local CONFIG_ATTRS = 4
local TABLE_COLS = 11
local TABLE_ROWS = MAX_CONFIG_ROWS * math.floor(TABLE_COLS / CONFIG_ATTRS)
local MAX_PRESETS = 10

local preset_list = {}
for i = 1, MAX_PRESETS do
    preset_list[i] = tostring(i)
end

local function default_name(i)
    if i == nil then return "<Unnamed Preset>" end
    return "<Unnamed Preset " .. i .. ">"
end

local tp_tab_entity = {}


--- @param e EventData.on_gui_switch_state_changed
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_mode_switch(e, self, tdata, pdata)
    pdata.whitelist = e.element.switch_state == "left"
    tp_tab_entity.populate_config_table(self)
end

--- @param e EventData.on_gui_elem_changed
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_config_select(e, self, tdata, pdata)
    local config = pdata.config[e.element.tags.index]
    if config == nil then return end
    config[e.element.tags.type] = e.element.elem_value
end

--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
--- @param isEdit boolean
local function label_edit_mode(self, tdata, pdata, isEdit)
    local name_label = self.elems.tp_entity_preset_name_label
    local name_textfield = self.elems.tp_entity_preset_name_textfield
    local edit_button = self.elems.tp_entity_rename_button
    name_label.visible = not isEdit
    name_textfield.visible = isEdit
    if isEdit then
        name_textfield.text = pdata.name
        name_textfield.focus()
        edit_button.tooltip = { "gui-edit-label.save-label" }
    else
        name_label.caption = pdata.name
        name_label.tooltip = pdata.name
        edit_button.tooltip = { "gui-edit-label.edit-label" }
    end
end

local function load_preset(self, tdata, pdata)
    label_edit_mode(self, tdata, pdata, false)
    self.elems.tp_mode_switch.switch_state = pdata.whitelist and "left" or "right"
    self.elems.tp_entity_preset_dropdown.selected_index = tdata.preset
    tp_tab_entity.populate_config_table(self)

    self.elems.tp_entity_preset_name_label.visible = true
    self.elems.tp_entity_preset_name_textfield.visible = false
end

local function destroy_import_export_dialog(self)
    if self.elems.tp_export_window == nil then return end
    self.elems.tp_export_window.destroy()
    self.elems.tp_export_window = nil
    self.elems.tp_export_text = nil
end

--- @param e EventData.on_gui_closed
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_import_export_dialog_closed(e, self, tdata, pdata)
    destroy_import_export_dialog(self)
end

local function create_import_export_dialog(self, caption, button_def)
    flib_gui.add(self.player.gui.screen, {
        type = "frame",
        name = "tp_export_window",
        direction = "vertical",
        style_mods = { maximal_height = 930, },
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = on_import_export_dialog_closed },
        -- Children
        templates.titlebar(
            caption,
            "tp_export_window",
            { on_close_handler = on_import_export_dialog_closed }
        ),
        {
            type = "text-box",
            name = "tp_export_text",
            elem_mods = { word_wrap = true },
            style_mods = { width = 400, height = 250 },
            text = "",
        },
        {
            type = "flow",
            direction = "horizontal",
            {
                type = "empty-widget",
                style = "flib_horizontal_pusher",
            },
            button_def
        },
    }, self.elems)
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_export_click(e, self, tdata, pdata)
    create_import_export_dialog(self, { "gui.tp-export-entity" }, {
        type = "button",
        style = "dialog_button",
        caption = { "gui.ok" },
        handler = { [defines.events.on_gui_click] = on_import_export_dialog_closed }
    })
    local text = base64.encode(game.table_to_json(pdata)) --[[@as string]]
    self.elems.tp_export_text.text = text
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_import_confirm_click(e, self, tdata, pdata)
    local function create_error_text(message)
        self.player.surface.create_entity({
            name = "flying-text",
            position = self.player.position,
            text = message,
        })
        destroy_import_export_dialog(self)
    end
    local text = self.elems.tp_export_text.text
    local success, import = pcall(game.json_to_table, base64.decode(text))
    import = import --[[@as EntityPresetData]]
    local config = {}

    if not success or import == nil then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    if import.whitelist == nil or import.name == nil or import.config == nil then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    if type(import.whitelist) ~= "boolean" or type(import.name) ~= "string" or type(import.config) ~= "table" then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    local c = 0
    for _, setting in pairs(import.config) do
        if c == 0 and setting.entity ~= "signal-anything" then
            create_error_text({ "failed-to-import-string", "Invalid Config" })
            return
        end
        if setting.entity ~= nil and setting.entity ~= "signal-anything" then
            local entity = game.entity_prototypes[setting.entity]
            if entity == nil then
                create_error_text({ "failed-to-import-string", "Invalid Entity in Config" })
                return
            end
        end
        for i = 0, 2 do
            if setting["tile_" .. i] ~= nil then
                local tile = game.tile_prototypes[setting["tile_" .. i]]
                if tile == nil then
                    create_error_text({ "failed-to-import-string", "Invalid Tile in Config" })
                    return
                end
            end
        end
        c = c + 1
        config[c] = {
            entity = setting.entity,
            tile_0 = setting.tile_0,
            tile_1 = setting.tile_1,
            tile_2 = setting.tile_2,
        }
    end
    if c ~= TABLE_ROWS then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    pdata.config = config
    pdata.whitelist = import.whitelist
    pdata.name = import.name
    load_preset(self, tdata, pdata)
    destroy_import_export_dialog(self)
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_import_click(e, self, tdata, pdata)
    create_import_export_dialog(self, { "gui-blueprint-library.import-string" }, {
        type = "button",
        style = "dialog_button",
        caption = { "gui-blueprint-library.import" },
        handler = { [defines.events.on_gui_click] = on_import_confirm_click }
    })
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_entity_reset_click(e, self, tdata, pdata)
    pdata.config = {}
    local name = default_name(tdata.preset)
    pdata.name = name
    self.elems.tp_entity_preset_name_label.caption = name
    pdata.whitelist = true
    self.elems.tp_mode_switch.switch_state = "left"
    tp_tab_entity.populate_config_table(self)
end

--- @param e EventData.on_gui_confirmed
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_preset_name_text_changed(e, self, tdata, pdata)
    pdata.name = e.element.text
    label_edit_mode(self, tdata, pdata, false)
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_rename_click(e, self, tdata, pdata)
    local isEditMode = self.elems.tp_entity_preset_name_textfield.visible
    label_edit_mode(self, tdata, pdata, not isEditMode)
end

--- @param e EventData.on_gui_selection_state_changed
--- @param self Gui
--- @param tdata EntityTabData
--- @param pdata EntityPresetData
local function on_preset_select(e, self, tdata, pdata)
    tdata.preset = e.element.selected_index
    pdata = tdata.presets[tdata.preset]
    load_preset(self, tdata, pdata)
end

local tab_def = {
    name = "entity",
    subheading = {
        {
            type = "label",
            name = "tp_entity_preset_name_label",
            caption = default_name(1),
            style_mods = { maximal_width = 230 },
            style = "subheader_caption_label",
        },
        {
            type = "textfield",
            name = "tp_entity_preset_name_textfield",
            text = default_name(1),
            looe_focus_on_confirm = true,
            clear_and_focus_on_right_click = true,
            visible = false,
            handler = { [defines.events.on_gui_confirmed] = on_preset_name_text_changed }
        },
        {
            type = "sprite-button",
            name = "tp_entity_rename_button",
            style = "mini_button_aligned_to_text_vertically_when_centered",
            sprite = "utility/rename_icon_small_black",
            tooltip = { "gui-edit-label.edit-label" },
            handler = { [defines.events.on_gui_click] = on_rename_click },
        },
        {
            type = "empty-widget",
            style = "flib_horizontal_pusher",
        },
        {
            type = "drop-down",
            style = "dropdown",
            style_mods = { maximal_width = 60 },
            name = "tp_entity_preset_dropdown",
            items = preset_list,
            selected_index = 1,
            handler = { [defines.events.on_gui_selection_state_changed] = on_preset_select },
        },
        {
            type = "sprite-button",
            style = "tool_button",
            sprite = "utility/import_slot",
            tooltip = { "gui.tp-tooltip-import" },
            handler = { [defines.events.on_gui_click] = on_import_click },
        },
        {
            type = "sprite-button",
            style = "tool_button",
            sprite = "utility/export_slot",
            tooltip = { "gui.tp-tooltip-export" },
            handler = { [defines.events.on_gui_click] = on_export_click },
        },
        {
            type = "sprite-button",
            style = "tool_button_red",
            sprite = "utility/reset",
            tooltip = { "gui.tp-tooltip-reset" },
            handler = { [defines.events.on_gui_click] = on_entity_reset_click },
        }
    },
    contents = {
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { top_padding = 4, bottom_padding = 4, },
            {
                type = "label",
                caption = "Filters",
                style = "heading_2_label",
            },
            {
                type = "empty-widget",
                style = "flib_horizontal_pusher",
            },
            {
                type = "switch",
                name = "tp_mode_switch",
                switch_state = "left",
                left_label_caption = { "gui.tp-whitelist" },
                left_label_tooltip = { "gui.tp-tooltip-entity-whitelist" },
                right_label_caption = { "gui.tp-blacklist" },
                right_label_tooltip = { "gui.tp-tooltip-entity-blacklist" },
                handler = { [defines.events.on_gui_switch_state_changed] = on_mode_switch },
            },
        },
        {
            type = "frame",
            style = "deep_frame_in_shallow_frame",
            direction = "horizontal",
            {
                type = "table",
                name = "tp_config_table",
                style = "slot_table",
                column_count = TABLE_COLS,
            },
        },
    },
}

tp_tab_entity.def = templates.tab_heading(tab_def)

--- @param self Gui
function tp_tab_entity.populate_config_table(self)
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
                caption = { "gui.tp-entity" },
                tooltip = { "gui.tp-tooltip-entity-entity" },
            })
            for i = 0, 2 do
                flib_gui.add(tbl, {
                    type = "label",
                    style = "caption_label",
                    caption = { "gui.tp-label-tiles", i },
                    tooltip = { "gui.tp-tooltip-entity-tile", i },
                })
            end
            flib_gui.add(tbl, {
                type = "empty-widget",
                style_mods = { horizontally_stretchable = "on" }
            })
        end
    end

    --- @param self Gui
    local function build_row(self, tbl, row)
        local tdata = self.tabs["entity"]
        local pdata = tdata.presets[tdata.preset]
        local config_data = pdata.config
        if config_data[row] == nil then
            config_data[row] = {
                entity = row == 1 and "signal-anything" or nil,
                tile_0 = nil,
                tile_1 = nil,
                tile_2 = nil,
            }
        end

        local config = config_data[row]

        if row == 1 then
            flib_gui.add(tbl, {
                type = "choose-elem-button",
                style = "slot_button",
                elem_type = "signal",
                signal = { type = "virtual", name = "signal-anything" },
                tags = { type = "signal", index = row },
                tooltip = { "gui.tp-tooltip-entity-anything" },
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
        local enabled = pdata.whitelist or row == 1
        for i = 1, #tiles do
            flib_gui.add(tbl, {
                type = "choose-elem-button",
                style = "slot_button",
                elem_type = "tile",
                enabled = enabled,
                tile = enabled and config[tiles[i]] or nil,
                elem_filters = filter,
                tags = { type = tiles[i], index = row },
                handler = { [defines.events.on_gui_elem_changed] = on_config_select }
            })
        end
    end

    local config_table = self.elems.tp_config_table
    if config_table == nil then return end
    -- Kind of redundant to set this every time, but it's not a big deal
    for i = 1, TABLE_COLS do
        config_table.style.column_alignments[i] = "center"
    end
    config_table.clear()
    build_heading(config_table)
    -- for row = 1, MAX_CONFIG_ROWS do
    --     build_row(self, config_table, row)
    -- end
    for row = 1, TABLE_ROWS do
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

--- @class EntityPresetData
--- @field config table<number, table<string, string|nil>>
--- @field whitelist boolean
--- @field name string

--- @class EntityTabData
--- @field preset number
--- @field presets table<number, EntityPresetData>

function tp_tab_entity.init(self)
    local tab = {
        preset = 1,
        presets = {},
    }
    for i = 1, MAX_PRESETS do
        tab.presets[i] = {
            config = {},
            whitelist = true,
            name = default_name(i),
        } --[[@as EntityPresetData]]
    end
    self.tabs["entity"] = tab
end

function tp_tab_entity.refresh(self)
    tp_tab_entity.populate_config_table(self)
end

function tp_tab_entity.hide(self)
    destroy_import_export_dialog(self)
end

--- @param self Gui
--- @param tdata EntityTabData
function tp_tab_entity.on_next_setting(self, tdata)
    tdata.preset = tdata.preset + 1
    if tdata.preset > MAX_PRESETS then
        tdata.preset = 1
    end
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then return end
    load_preset(self, tdata, pdata)
end

--- @param self Gui
--- @param tdata EntityTabData
function tp_tab_entity.on_previous_setting(self, tdata)
    tdata.preset = tdata.preset - 1
    if tdata.preset < 1 then
        tdata.preset = MAX_PRESETS
    end
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then return end
    load_preset(self, tdata, pdata)
end

--- @param e {player_index: uint}
local function wrapper(e, handler)
    local self = global.gui[e.player_index]
    if self == nil then return end
    local tdata = self.tabs["entity"]
    if tdata == nil then return end
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then return end
    handler(e, self, tdata, pdata)
end

flib_gui.add_handlers({
    on_mode_switch = on_mode_switch,
    on_config_select = on_config_select,
    on_export_click = on_export_click,
    on_import_click = on_import_click,
    on_import_confirm_click = on_import_confirm_click,
    on_reset_click = on_entity_reset_click,
    on_export_window_closed = on_import_export_dialog_closed,
    on_preset_name_text_changed = on_preset_name_text_changed,
    on_rename_click = on_rename_click,
    on_preset_select = on_preset_select,
}, wrapper)

return tp_tab_entity
