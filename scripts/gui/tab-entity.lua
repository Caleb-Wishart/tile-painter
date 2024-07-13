local flib_gui = require("__flib__.gui-lite")

local templates = require("scripts.gui.templates")

local base64 = require("lib.base64")

local MAX_CONFIG_ROWS = 7
local CONFIG_ATTRS = 4
local TABLE_COLS = 11
local TABLE_ROWS = MAX_CONFIG_ROWS * math.floor(TABLE_COLS / CONFIG_ATTRS)

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

local function destroy_import_export_dialog(self)
    if self.elems.tp_export_window == nil then return end
    self.elems.tp_export_window.destroy()
    self.elems.tp_export_window = nil
    self.elems.tp_export_text = nil
end

--- @param e EventData.on_gui_closed
--- @param self Gui
--- @param tdata EntityTabData
local function on_import_export_dialog_closed(e, self, tdata)
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
local function on_export_click(e, self, tdata)
    create_import_export_dialog(self, { "gui.tp-export-entity" }, {
        type = "button",
        style = "dialog_button",
        caption = { "gui.ok" },
        handler = { [defines.events.on_gui_click] = on_import_export_dialog_closed }
    })
    local text = base64.encode(game.table_to_json(tdata.config)) --[[@as string]]
    self.elems.tp_export_text.text = text
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
local function on_import_confirm_click(e, self, tdata)
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
    import = import --[[@as table<number, table<string, string|nil>>]]
    local config = {}

    if not success or import == nil then
        create_error_text({ "failed-to-import-string", "Invalid Config" })
        return
    end
    local c = 0
    for _, setting in pairs(import) do
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
    tdata.config = config
    tp_tab_entity.populate_config_table(self)
    destroy_import_export_dialog(self)
end

--- @param e EventData.on_gui_click
--- @param self Gui
--- @param tdata EntityTabData
local function on_import_click(e, self, tdata)
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
local function on_entity_reset_click(e, self, tdata)
    tdata.config = {}
    tp_tab_entity.populate_config_table(self)
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
        local enabled = tdata.whitelist or row == 1
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

function tp_tab_entity.hide(self)
    destroy_import_export_dialog(self)
end

flib_gui.add_handlers({
    on_mode_switch = on_mode_switch,
    on_config_select = on_config_select,
    on_export_click = on_export_click,
    on_import_click = on_import_click,
    on_import_confirm_click = on_import_confirm_click,
    on_reset_click = on_entity_reset_click,
    on_export_window_closed = on_import_export_dialog_closed,
}, templates.tab_wrapper("entity"))

return tp_tab_entity
