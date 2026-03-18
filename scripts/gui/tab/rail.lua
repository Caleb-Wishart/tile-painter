local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local templates = require("scripts.gui.templates")

local rail_mask = require("scripts.util.rail_mask")

local base64 = require("lib.base64")

local MAX_PRESETS = 3

local preset_list = {}
for i = 1, MAX_PRESETS do
    preset_list[i] = tostring(i)
end


local function default_name(i)
    if i == nil then
        return "<Unnamed Rail Preset>"
    end
    return "<Unnamed Rail Preset " .. i .. ">"
end

local tp_tab_rail = {}


local function set_tab_caption(self, tdata, pdata)
    if pdata.apply_entity then
        self.elems.tp_tab_rail.caption = { "", "< ", { "gui.tp-rail" } }
    else
        self.elems.tp_tab_rail.caption = { "gui.tp-rail" }
    end
end

--- @param e EventData.on_gui_switch_state_changed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_apply_entity_switch(e, self, tdata, pdata)
    pdata.apply_entity = e.element.switch_state == "left"
    set_tab_caption(self, tdata, pdata)
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_smooth_curve_changed(e, self, tdata, pdata)
    pdata.smooth_curve = e.element.state
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_group_rail_changed(e, self, tdata, pdata)
    pdata.group_rail = e.element.state
    if pdata.group_rail then
        self.elems.tp_group_rail_ramp_checkbox.enabled = true
    else
        self.elems.tp_group_rail_ramp_checkbox.enabled = false
    end
    tp_tab_rail.populate_scroll_pane(self)
end

--- @param e EventData.on_gui_checked_state_changed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_group_rail_ramp_changed(e, self, tdata, pdata)
    pdata.group_rail_ramp = e.element.state
    tp_tab_rail.populate_scroll_pane(self)
end

--- @param e EventData.on_gui_elem_changed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_config_select(e, self, tdata, pdata)
    local config = nil
    if pdata.group_rail then
        config = pdata.group_config
    else
        config = pdata.config
    end
    config = config[e.element.tags.index]
    if config == nil then
        return
    end
    config[e.element.tags.type] = e.element.elem_value
    if e.element.tags.type == "rail" then
        tp_tab_rail.populate_scroll_pane(self)
    end
end

--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_delete_config_click(e, self, tdata, pdata)
    local index = e.element.tags.index
    if index == nil then
        return
    end
    local config = pdata.config[index]
    if config == nil then
        return
    end
    table.remove(pdata.config, index)
    tp_tab_rail.populate_scroll_pane(self)
end

--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
--- @param isEdit boolean
local function label_edit_mode(self, tdata, pdata, isEdit)
    local name_label = self.elems.tp_rail_preset_name_label
    local name_textfield = self.elems.tp_rail_preset_name_textfield
    local edit_button = self.elems.tp_rail_rename_button
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
    self.elems.tp_mode_switch.switch_state = pdata.apply_entity and "left" or "right"
    self.elems.tp_smooth_curve_checkbox.state = pdata.smooth_curve
    self.elems.tp_group_rail_checkbox.state = pdata.group_rail
    self.elems.tp_group_rail_ramp_checkbox.state = pdata.group_rail_ramp
    self.elems.tp_group_rail_ramp_checkbox.enabled = pdata.group_rail

    self.elems.tp_rail_preset_dropdown.selected_index = tdata.preset
    tp_tab_rail.populate_scroll_pane(self)

    self.elems.tp_rail_preset_name_label.visible = true
    self.elems.tp_rail_preset_name_textfield.visible = false
    set_tab_caption(self, tdata, pdata)
end

local function destroy_import_export_dialog(self)
    if self.elems.tp_export_window == nil then
        return
    end
    self.elems.tp_export_window.destroy()
    self.elems.tp_export_window = nil
    self.elems.tp_export_text = nil
end

--- @param e EventData.on_gui_closed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_import_export_dialog_closed(e, self, tdata, pdata)
    destroy_import_export_dialog(self)
end

local function create_import_export_dialog(self, caption, button_def)
    flib_gui.add(self.player.gui.screen, {
        type = "frame",
        name = "tp_export_window",
        direction = "vertical",
        style_mods = { maximal_height = 930 },
        elem_mods = { auto_center = true },
        handler = { [defines.events.on_gui_closed] = on_rail_import_export_dialog_closed },
        -- Children
        templates.titlebar(caption, "tp_export_window", { on_close_handler = on_rail_import_export_dialog_closed }),
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
            button_def,
        },
    }, self.elems)
end


--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_export_click(e, self, tdata, pdata)
    create_import_export_dialog(self, { "gui.tp-export-rail" }, {
        type = "button",
        style = "dialog_button",
        caption = { "gui.ok" },
        handler = { [defines.events.on_gui_click] = on_rail_import_export_dialog_closed },
    })
    local text = base64.encode(helpers.table_to_json(pdata)) --[[@as string]]
    self.elems.tp_export_text.text = text
end



--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_import_confirm_click(e, self, tdata, pdata)
    local function create_error_text(message)
        self.player.create_local_flying_text({
            text = message,
            create_at_cursor = true,
        })
        destroy_import_export_dialog(self)
    end
    -- TODO: Update to use the new format
    local text = self.elems.tp_export_text.text
    local success, import = pcall(helpers.json_to_table, base64.decode(text))
    import = import --[[@as RailPresetData]]
    local config = {}

    if not success or import == nil then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    if import.apply_entity == nil or import.smooth_curve == nil
        or import.group_rail == nil or import.group_rail_ramp == nil
        or import.name == nil or import.config == nil then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    if type(import.apply_entity) ~= "boolean" or type(import.smooth_curve) ~= "boolean"
        or type(import.group_rail) ~= "boolean" or type(import.group_rail_ramp) ~= "boolean"
        or type(import.name) ~= "string" or type(import.config) ~= "table" then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    -- TODO
    local c = 0
    for _, setting in pairs(import.config) do
        if c == 0 and setting.rail ~= "signal-everything" then
            create_error_text({ "failed-to-import-string", "Invalid Config" })
            return
        end
        if c == 1 and setting.rail ~= "signal-anything" then
            create_error_text({ "failed-to-import-string", "Invalid Config" })
            return
        end
        if setting.rail ~= nil and setting.rail ~= "signal-everything" and setting.rail ~= "signal-anything" then
            local rail = prototypes.rail[setting.rail]
            if rail == nil then
                create_error_text({ "failed-to-import-string", "Invalid Rail in Config" })
                return
            end
        end
        for i = 0, 2 do
            if setting["tile_" .. i] ~= nil then
                local tile = prototypes.tile[setting["tile_" .. i]]
                if tile == nil then
                    create_error_text({ "failed-to-import-string", "Invalid Tile in Config" })
                    return
                end
            end
        end
        c = c + 1
        config[c] = {
            rail = setting.rail,
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
    pdata.apply_entity = import.apply_entity
    pdata.smooth_curve = import.smooth_curve
    pdata.group_rail = import.group_rail
    pdata.group_rail_ramp = import.group_rail_ramp
    pdata.name = import.name
    load_preset(self, tdata, pdata)
    destroy_import_export_dialog(self)
end

--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_import_click(e, self, tdata, pdata)
    create_import_export_dialog(self, { "gui-blueprint-library.import-string" }, {
        type = "button",
        style = "dialog_button",
        caption = { "gui-blueprint-library.import" },
        handler = { [defines.events.on_gui_click] = on_rail_import_confirm_click },
    })
end

--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_reset_click(e, self, tdata, pdata)
    pdata.config = {}
    local name = default_name(tdata.preset)
    pdata.name = name
    self.elems.tp_rail_preset_name_label.caption = name
    pdata.apply_entity = false
    pdata.smooth_curve = true
    pdata.group_rail = true
    pdata.group_rail_ramp = true
    self.elems.tp_apply_entity_switch.switch_state = "right"
    self.elems.tp_smooth_curve_checkbox.state = true
    self.elems.tp_group_rail_checkbox.state = true
    self.elems.tp_group_rail_ramp_checkbox.state = true
    tp_tab_rail.populate_scroll_pane(self)
end

--- @param e EventData.on_gui_confirmed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_preset_name_text_changed(e, self, tdata, pdata)
    pdata.name = e.element.text
    label_edit_mode(self, tdata, pdata, false)
end

--- @param e EventData.on_gui_click
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_rename_click(e, self, tdata, pdata)
    local isEditMode = self.elems.tp_rail_preset_name_textfield.visible
    label_edit_mode(self, tdata, pdata, not isEditMode)
end

--- @param e EventData.on_gui_selection_state_changed
--- @param self TPGui
--- @param tdata RailTabData
--- @param pdata RailPresetData
local function on_rail_preset_select(e, self, tdata, pdata)
    tdata.preset = e.element.selected_index
    pdata = tdata.presets[tdata.preset]
    load_preset(self, tdata, pdata)
end

local tab_def = {
    name = "rail",
    subheading = {
        {
            type = "label",
            name = "tp_rail_preset_name_label",
            caption = default_name(1),
            style_mods = { maximal_width = 230 },
            style = "subheader_caption_label",
        },
        {
            type = "textfield",
            name = "tp_rail_preset_name_textfield",
            text = default_name(1),
            looe_focus_on_confirm = true,
            clear_and_focus_on_right_click = true,
            visible = false,
            handler = { [defines.events.on_gui_confirmed] = on_rail_preset_name_text_changed },
        },
        {
            type = "sprite-button",
            name = "tp_rail_rename_button",
            style = "mini_button_aligned_to_text_vertically_when_centered",
            sprite = "utility/rename_icon",
            tooltip = { "gui-edit-label.edit-label" },
            handler = { [defines.events.on_gui_click] = on_rail_rename_click },
        },
        {
            type = "empty-widget",
            style = "flib_horizontal_pusher",
        },
        {
            type = "drop-down",
            style = "dropdown",
            style_mods = { maximal_width = 60 },
            name = "tp_rail_preset_dropdown",
            items = preset_list,
            selected_index = 1,
            handler = { [defines.events.on_gui_selection_state_changed] = on_rail_preset_select },
        },
        {
            type = "sprite-button",
            style = "tool_button",
            sprite = "utility/import_slot",
            tooltip = { "gui.tp-tooltip-import" },
            handler = { [defines.events.on_gui_click] = on_rail_import_click },
        },
        {
            type = "sprite-button",
            style = "tool_button",
            sprite = "utility/export_slot",
            tooltip = { "gui.tp-tooltip-export" },
            handler = { [defines.events.on_gui_click] = on_rail_export_click },
        },
        {
            type = "sprite-button",
            style = "tool_button_red",
            sprite = "utility/reset",
            tooltip = { "gui.tp-tooltip-reset" },
            handler = { [defines.events.on_gui_click] = on_rail_reset_click },
        },
    },
    contents = {
        {
            type = "frame",
            direction = "vertical",
            style = "bordered_frame",
            style_mods = { horizontally_stretchable = true, top_margin = 8 },
            {
                type = "label",
                style = "caption_label",
                caption = { "gui-blueprint.settings" },
            },
            {
                type = "flow",
                direction = "vertical",
                {
                    type = "flow",
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = { "gui.tp-label-apply-to-entity" },
                        style = "heading_2_label",
                    },
                    {
                        type = "empty-widget",
                        style = "flib_horizontal_pusher",
                    },
                    {
                        type = "switch",
                        name = "tp_apply_entity_switch",
                        switch_state = "right",
                        left_label_caption = { "gui.tp-true" },
                        left_label_tooltip = { "gui.tp-tooltip-rail-apply-true" },
                        right_label_caption = { "gui.tp-false" },
                        right_label_tooltip = { "gui.tp-tooltip-rail-apply-false" },
                        handler = { [defines.events.on_gui_switch_state_changed] = on_apply_entity_switch },
                    },
                },
                {
                    type = "checkbox",
                    style = "caption_checkbox",
                    caption = { "gui.tp-label-smooth-curve" },
                    tooltip = { "gui.tp-tooltip-smooth-curved-rail" },
                    name = "tp_smooth_curve_checkbox",
                    state = true,
                    handler = { [defines.events.on_gui_checked_state_changed] = on_smooth_curve_changed },
                },
                {
                    type = "checkbox",
                    style = "caption_checkbox",
                    caption = { "gui.tp-label-group-rail" },
                    tooltip = { "gui.tp-tooltip-group-rail" },
                    name = "tp_group_rail_checkbox",
                    state = true,
                    handler = { [defines.events.on_gui_checked_state_changed] = on_group_rail_changed },
                },
                {
                    type = "checkbox",
                    style = "caption_checkbox",
                    caption = { "gui.tp-label-group-rail-ramp" },
                    tooltip = { "gui.tp-tooltip-group-rail-ramp" },
                    name = "tp_group_rail_ramp_checkbox",
                    state = true,
                    handler = { [defines.events.on_gui_checked_state_changed] = on_group_rail_ramp_changed },
                    enabled = true,
                },
            },
        },
        {
            type = "frame",
            style = "deep_frame_in_shallow_frame",
            direction = "vertical",
            style_mods = { top_margin = 8 },
            {
                type = "scroll-pane",
                direction = "vertical",
                name = "tp_rail_scroll_pane",
                style = "scroll_pane",
                vertical_scroll_policy = "auto-and-reserve-space",
            },
        },

    },
}

tp_tab_rail.def = templates.tab_heading(tab_def)

--- @param pdata RailPresetData
function tp_tab_rail.get_config(pdata)
    local cfg = pdata.config
    if pdata.group_rail then
        cfg = pdata.group_config
        -- Generate here in the event that a mod adds a new rail type
        for rail, _ in pairs(rail_mask.base_rails) do
            for _, data in pairs(cfg) do
                if data.rail == rail then
                    goto next
                end
            end
            cfg[#cfg + 1] = {
                rail = rail,
            }
            ::next::
        end
        if pdata.group_rail_ramp then
            cfg = flib_table.deep_copy(cfg)
            -- Remove the first one, which is the rail ramp
            table.remove(cfg, 1)
        end
    else
        if #cfg == 0 or cfg[#cfg].rail ~= nil then
            table.insert(cfg, {
                rail = nil,
            })
        end
    end
    return cfg
end

tp_tab_rail.tile_options = {
    "Ltile_3", "Ltile_2", "Ltile_1",
    "Utile_0",
    "Rtile_1", "Rtile_2", "Rtile_3",
}

--- @param self TPGui
function tp_tab_rail.populate_scroll_pane(self)
    --- @param self TPGui
    local function build_row(self, pane, row, data, pdata)
        local function build_buttons(row, data)
            local spacer = {
                type = "empty-widget",
                style = "flib_horizontal_pusher",
            }
            local tiles = tp_tab_rail.tile_options
            local buttons = {}
            table.insert(buttons, spacer)
            for i = 1, #tiles do
                local tile = tiles[i]
                table.insert(buttons, {
                    type = "choose-elem-button",
                    style = tile == "Utile_0" and "flib_slot_button_orange" or "slot_button",
                    elem_type = "tile",
                    elem_filters = { { filter = "blueprintable", mode = "and" } },
                    tile = data[tile],
                    tags = {
                        index = row,
                        type = tile,
                    },
                    tooltip = tile == "Utile_0" and { "gui.tp-tooltip-entity-tile", 0 } or nil,
                    handler = { [defines.events.on_gui_elem_changed] = on_rail_config_select },
                })
            end
            table.insert(buttons, spacer)
            return buttons
        end
        -- Skip if rail does not exist
        if data['rail'] ~= nil and prototypes.entity[data['rail']] == nil then
            return
        end
        flib_gui.add(pane, {
            type = "flow",
            direction = "vertical",
            style_mods = { top_margin = 4 },
            {
                type = "flow",
                direction = "horizontal",
                {
                    type = "choose-elem-button",
                    style = "slot_button",
                    elem_type = "entity",
                    entity = data['rail'],
                    enabled = not pdata.group_rail,
                    elem_filters = {
                        { filter = "rail" },
                    },
                    tags = {
                        index = row,
                        type = "rail",
                    },
                    handler = { [defines.events.on_gui_elem_changed] = on_rail_config_select },
                },
                {
                    type = "label",
                    caption = data['rail'],
                    style = "caption_label",
                },
                {
                    type = "empty-widget",
                    style = "flib_horizontal_pusher",
                },
                {
                    type = "sprite-button",
                    style = "tool_button_red",
                    sprite = "utility/trash",
                    handler = { [defines.events.on_gui_click] = on_rail_delete_config_click },
                    -- Only show if not group rail and more than 1 config
                    visible = not pdata.group_rail and not (row == #pdata.config and data['rail'] == nil),
                    tags = {
                        index = row,
                    },
                },
            },
            {
                type = "flow",
                direction = "horizontal",
                table.unpack(build_buttons(row, data)),
            },
        })
    end

    local pane = self.elems.tp_rail_scroll_pane
    if pane == nil then
        return
    end
    local tdata = self.tabs["rail"]
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then
        return
    end

    local cfg = tp_tab_rail.get_config(pdata) ---@cast cfg -nil
    pane.clear()
    for i, data in pairs(cfg) do
        if pdata.group_rail and pdata.group_rail_ramp then
            -- Adjust index for group config as get_config removed ramp
            i = i + 1
        end
        build_row(self, pane, i, data, pdata)
    end
end

--- @class RailPresetData
--- @field name string
--- @field config table<number, table<string, string|nil>>
--- @field group_config table<number, table<string, string|nil>>
--- @field apply_entity boolean
--- @field smooth_curve boolean
--- @field group_rail boolean
--- @field group_rail_ramp boolean

--- @class RailTabData
--- @field preset number
--- @field presets table<number, RailPresetData>
--- @field cache table<string, table<string, number>>

function tp_tab_rail.init(self)
    local tab = {
        preset = 1,
        presets = {},
        -- We cache the calculated positions for a rail to avoid recalculating them
        -- As intercardinal directions / orientations have additional calculations
        cache = {}, -- Used in Tool ONLY
    }
    for i = 1, MAX_PRESETS do
        tab.presets[i] = {
            name = default_name(i),
            config = {},
            group_config = {
            },
            apply_entity = false,
            smooth_curve = true,
            group_rail = true,
            group_rail_ramp = true,
        } --[[@as RailPresetData]]

        table.insert(tab.presets[i].group_config, {
            rail = "rail-ramp",
        })
    end


    self.tabs["rail"] = tab
    set_tab_caption(self, tab, tab.presets[tab.preset])
end

function tp_tab_rail.refresh(self)
    tp_tab_rail.populate_scroll_pane(self)
end

function tp_tab_rail.hide(self)
    destroy_import_export_dialog(self)
end

--- @param self TPGui
--- @param tdata RailTabData
function tp_tab_rail.on_next_setting(self, tdata)
    tdata.preset = tdata.preset + 1
    if tdata.preset > MAX_PRESETS then
        tdata.preset = 1
    end
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then
        return
    end
    load_preset(self, tdata, pdata)
end

--- @param self TPGui
--- @param tdata RailTabData
function tp_tab_rail.on_previous_setting(self, tdata)
    tdata.preset = tdata.preset - 1
    if tdata.preset < 1 then
        tdata.preset = MAX_PRESETS
    end
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then
        return
    end
    load_preset(self, tdata, pdata)
end

--- @param e {player_index: uint}
local function wrapper(e, handler)
    local self = storage.gui[e.player_index]
    if self == nil then
        return
    end
    local tdata = self.tabs["rail"]
    if tdata == nil then
        return
    end
    local pdata = tdata.presets[tdata.preset]
    if pdata == nil then
        return
    end
    handler(e, self, tdata, pdata)
end

flib_gui.add_handlers({
    on_rail_config_select = on_rail_config_select,
    on_rail_export_click = on_rail_export_click,
    on_rail_import_click = on_rail_import_click,
    on_rail_import_confirm_click = on_rail_import_confirm_click,
    on_rail_reset_click = on_rail_reset_click,
    on_rail_import_export_dialog_closed = on_rail_import_export_dialog_closed,
    on_rail_preset_name_text_changed = on_rail_preset_name_text_changed,
    on_rail_rename_click = on_rail_rename_click,
    on_rail_preset_select = on_rail_preset_select,
    on_apply_entity_switch = on_apply_entity_switch,
    on_smooth_curve_changed = on_smooth_curve_changed,
    on_group_rail_changed = on_group_rail_changed,
    on_group_rail_ramp_changed = on_group_rail_ramp_changed,
    on_rail_delete_config_click = on_rail_delete_config_click,
}, wrapper)

return tp_tab_rail
