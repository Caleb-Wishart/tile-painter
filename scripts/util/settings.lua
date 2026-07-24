---@class tile_painter_util_settings
local tp_util_settings = {}

function tp_util_settings.get_player_settings(player_index, setting)
    return settings.get_player_settings(player_index)["tp-" .. setting].value
end

return tp_util_settings
