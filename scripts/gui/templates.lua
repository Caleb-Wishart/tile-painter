local tp_gui_template = {}

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler function
function tp_gui_template.frame_action_button(name, sprite, tooltip, handler)
    return {
        type = "sprite-button",
        name = name,
        style = "frame_action_button",
        sprite = sprite,
        tooltip = tooltip,
        handler = handler,
    }
end

--- @class TitleBarOpts
--- @field on_close_handler function?
--- @field on_pin_handler function?
--- @field on_titlebar_click_handler function?

--- @param caption LocalisedString
--- @param target string
--- @param opts TitleBarOpts?
function tp_gui_template.titlebar(caption, target, opts)
    local elems = {
        type = "flow",
        style = "flib_titlebar_flow",
        drag_target = target,
        {
            type = "label",
            style = "flib_frame_title",
            caption = caption,
            ignored_by_interaction = true,
        },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
    }
    if opts then
        if opts.on_close_handler then
            table.insert(
                elems,
                #elems + 1,
                tp_gui_template.frame_action_button(
                    "close_button",
                    "utility/close",
                    { "gui.close-instruction" },
                    opts.on_close_handler
                )
            )
        end
        if opts.on_pin_handler then
            table.insert(
                elems,
                #elems + 1,
                tp_gui_template.frame_action_button(
                    "pin_button",
                    "flib_pin_white",
                    { "gui.flib-keep-open" },
                    opts.on_pin_handler
                )
            )
        end
        if opts.on_titlebar_click_handler then
            elems.handler = {
                [defines.events.on_gui_click] = opts.on_titlebar_click_handler,
            }
        end
    end
    return elems
end

--- @class TabHeadingOpts
--- @field name string Name of the tab
--- @field subheading GuiElemDef|GuiElemDef[] Subheading of the tab
--- @field contents GuiElemDef|GuiElemDef[] Contents of the tab

--- @param opts TabHeadingOpts
function tp_gui_template.tab_heading(opts)
    if type(opts.name) ~= "string" then
        error("Name must be a string")
    end
    if type(opts.subheading) ~= "table" then
        error("Subheading must be a table")
    end
    if type(opts.contents) ~= "table" then
        error("Contents must be a table")
    end
    return {
        tab = {
            type = "tab",
            name = "tp_tab_" .. opts.name,
            style = "tp_header_tab",
            caption = { "gui.tp-" .. opts.name },
            tags = { mod = "tile-painter", name = opts.name },
        },
        content = {
            type = "frame",
            direction = "vertical",
            style = "invisible_frame",
            {
                type = "frame",
                direction = "horizontal",
                style = "subheader_frame",
                style_mods = {
                    horizontally_stretchable = true,
                    horizontally_squashable = true,
                },
                table.unpack(opts.subheading),
            },
            {
                type = "frame",
                direction = "vertical",
                style = "tp_tab_inside_shallow_frame",
                table.unpack(opts.contents),
            },
        },
    }
end

function tp_gui_template.tab_wrapper(name)
    --- @param e {player_index: uint}
    local function wrapper(e, handler)
        local self = storage.gui[e.player_index]
        if self == nil then
            return
        end
        local tdata = self.tabs[name]
        if tdata == nil then
            return
        end
        handler(e, self, tdata)
    end
    return wrapper
end

return tp_gui_template
