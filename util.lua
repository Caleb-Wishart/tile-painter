--- @class tile_painter_util
local tp_util = {}

--- Print a message to the console.
--  Pass an object to print it as a JSON string.
--- @param msg string
--- @param obj table
--- @noreturn
function tp_util.print(msg, obj)
    if settings.global["tp-debug-mode"].value == false then
        return
    end
    if obj == nil then
        game.print(msg)
    else
        game.print(msg .. helpers.table_to_json(obj or {}))
    end
end

function tp_util.get_player_settings(player_index, setting)
    return settings.get_player_settings(player_index)["tp-" .. setting].value
end

return tp_util
