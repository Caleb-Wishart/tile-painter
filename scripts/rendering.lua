local position = require("__flib__.position")
local polygon = require("scripts.polygon")

--- @class tp_rendering
local tp_rendering = {}

-- Rerender the prototype polygon with the new vertices
---@param player_global CustomTable the player global
function tp_rendering.handle_fill_shape_change(player_global)
    -- local vertices = polygon.polygon_vertices()
end

return tp_rendering
