local bounding_box = require("__tile-painter__/scripts/bounding-box")
local surfacelib = require("__tile-painter__/scripts/surface")
local tilelib = require("__tile-painter__/scripts/tile")

local getCurveTiles = require("__tile-painter__/scripts/curved-rail")

local orientation = require("__flib__/orientation")

local mod_name = require("__tile-painter__/util").defines.mod_name


--- @class tile_painter_painter
local tile_painter_painter = {}

---@param player LuaPlayer the player to paint the tiles for
---@param entity LuaEntity reference entity
---@param tile_type string the tile to ghost
---@param delta number the delta to grow the bounding box(es) by
function tile_painter_painter.paint_tiles_entity(player, entity, tile_type, delta)
    local surface = entity.surface
    local box = bounding_box.ensure_explicit(entity.bounding_box)
    local search_boxes = { box }

    local force = player.force ---@cast force LuaForce

    if settings.get_player_settings(player.index)[mod_name .. "-smooth-curved-rail"].value and entity.name == "curved-rail" then
        -- Use a special mapping
        local tiles = getCurveTiles(entity.direction, delta)
        local pos = entity.position
        for i = #tiles, 1, -1 do
            local position = {
                x = pos.x + tiles[i].x,
                y = pos.y + tiles[i].y,
            }
            surfacelib.create_tile_ghost(surface, tile_type, position, force)
        end
        return
    end

    if entity.secondary_bounding_box ~= nil then
        table.insert(search_boxes, bounding_box.ensure_explicit(entity.secondary_bounding_box))
    end
    for i = 1, #search_boxes do
        local sbox = search_boxes[i]
        local tiles = nil
        if sbox.orientation ~= orientation.north
            and sbox.orientation ~= orientation.east
            and sbox.orientation ~= orientation.south
            and sbox.orientation ~= orientation.west then
            -- If the bounding box has an orientation and isn't a simple rectangle,
            -- we can't safely resize it and have to get adjacent tiles
            local area = sbox
            local search_param = { has_hidden_tile = false, area = area }
            tiles = surfacelib.find_tiles_filtered(surface, search_param)
            for _ = 1, delta do
                local adj_tiles = tilelib.get_adjacent_tiles(tiles)
                for j = 1, #adj_tiles do
                    tiles[#tiles + 1] = adj_tiles[j]
                end
            end
        else
            -- It is more efficient to resize the bounding box and get all tiles in the area
            local area = bounding_box.resize(sbox, delta)
            local search_param = { has_hidden_tile = false, area = area }
            tiles = surfacelib.find_tiles_filtered(surface, search_param)
        end
        for j = #tiles, 1, -1 do
            surfacelib.create_tile_ghost(surface, tile_type, tiles[j].position, force)
        end
    end
end

return tile_painter_painter
