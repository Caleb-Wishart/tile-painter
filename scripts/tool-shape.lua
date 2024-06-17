--- @param e EventData.CustomInputEvent
local function handle_fill_shape_click(e, isRight)
    local player_global = global.players[e.player_index]
    if player_global == nil then return end
    if player_global.inventory_selected ~= item_name or player_global.mode ~= "fill-shape" then return end
    local position = e.cursor_position
    local surface = game.get_player(e.player_index).surface.name
    local shape_fill = player_global.shape_fill
    -- ensure that the position is on the same surface
    if surface ~= shape_fill.surface then
        shape_fill.centre = nil
        shape_fill.vertex = nil
        shape_fill.surface = surface
    end
    if isRight then
        shape_fill.centre = position
    else
        shape_fill.vertex = position
    end
end

--- @param e EventData.CustomInputEvent
local function on_left_click(e)
    handle_fill_shape_click(e, false)
end

--- @param e EventData.CustomInputEvent
local function on_right_click(e)
    handle_fill_shape_click(e, true)
end

--- @class Tool
local tool = {}

tool.events = {
    ["tile-painter-fill-shape-left-click"] = on_left_click,
    ["tile-painter-fill-shape-right-click"] = on_right_click,
}

return tool
