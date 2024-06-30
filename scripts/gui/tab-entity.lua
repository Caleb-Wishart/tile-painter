local flib_gui = require("__flib__.gui-lite")

local templates = require("scripts.gui.templates")

local MAX_CONFIG_ROWS = 6
local CONFIG_ATTRS = 4
local TABLE_COLS = 11

local tp_tab_entity = {}


--- @param e EventData.on_gui_switch_state_changed
--- @param self Gui
--- @param tdata EntityTabData
local function on_mode_switch(e, self, tdata)
    tdata.whitelist = e.element.switch_state == "left"
    tp_tab_entity.populate_config_table(self)
end

--- @param e EventData.on_gui_elem_changed
--- @param self Gui
--- @param tdata EntityTabData
local function on_config_select(e, self, tdata)
    local config = tdata.config[e.element.tags.index]
    if config == nil then return end
    config[e.element.tags.type] = e.element.elem_value
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
local function on_export_click(e, self, tdata)
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
local function on_import_click(e, self, tdata)
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
local function on_reset_click(e, self, tdata)
end

local tab_def = {
    name = "entity",
    subheading = {
        {
            type = "label",
            caption = "Default Name",
            style = "heading_2_label",
        },
        {
            type = "empty-widget",
            style = "flib_horizontal_pusher",
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
            style = "tool_button",
            sprite = "utility/import_slot",
            tooltip = { "gui.tp-tooltip-import" },
            handler = { [defines.events.on_gui_click] = on_import_click },
        },
        {
            type = "sprite-button",
            style = "tool_button_red",
            sprite = "utility/reset",
            tooltip = { "gui.tp-tooltip-reset" },
            handler = { [defines.events.on_gui_click] = on_reset_click },
        }
    },
    contents = {
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { top_padding = 4, bottom_padding = 4 },
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
            {
                type = "empty-widget",
                style = "flib_horizontal_pusher",
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
        local config_data = tdata.config
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
        for i = 1, #tiles do
            flib_gui.add(tbl, {
                type = "choose-elem-button",
                style = "slot_button",
                elem_type = "tile",
                enabled = tdata.whitelist or row == 1,
                tile = tdata.whitelist and config[tiles[i]] or nil,
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

--- @class EntityTabData
--- @field config table<number, table<string, string|nil>>
--- @field whitelist boolean

function tp_tab_entity.init(self)
    local tab = {
        config = {},
        whitelist = true,
    } --[[@as EntityTabData]]
    self.tabs["entity"] = tab
end

function tp_tab_entity.refresh(self)
    tp_tab_entity.populate_config_table(self)
end

flib_gui.add_handlers({
    on_mode_switch = on_mode_switch,
    on_config_select = on_config_select,
    on_export_click = on_export_click,
    on_import_click = on_import_click,
    on_reset_click = on_reset_click,
}, templates.tab_wrapper("entity"))

return tp_tab_entity
