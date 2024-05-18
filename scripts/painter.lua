local bounding_box = require("__tile-painter__/scripts/bounding-box")
local surfacelib = require("__tile-painter__/scripts/surface")

local util = require("__tile-painter__/util")

--- @class tile_painter_painter
local tile_painter_painter = {}

--- TODO
---@param force LuaForce the force to ghost the tiles for
---@param entity LuaEntity reference entity
-- TODO convert to object param
function tile_painter_painter.paint_tiles_under_entity(force, entity, tile_type, delta)
    local surface = entity.surface
    local box = entity.bounding_box
    local search_boxes = { box }
    if entity.secondary_bounding_box ~= nil then
        table.insert(search_boxes, entity.secondary_bounding_box)
    end
    for i = 1, #search_boxes do
        local area = bounding_box.resize(search_boxes[i], delta)
        local search_param = { has_hidden_tile = false, area = area }
        local available_tiles = surfacelib.find_tiles_filtered(surface, search_param)
        for j = #available_tiles, 1, -1 do
            surfacelib.create_tile_ghost(surface, tile_type, available_tiles[j].position, force)
        end
    end
end

return tile_painter_painter
