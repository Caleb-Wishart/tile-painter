local bounding_box = require("__tile-painter__/scripts/bounding-box")
local surfacelib = require("__tile-painter__/scripts/surface")
local flib_position = require("__flib__/position")

--- @class tile_painter_painter
local tile_painter_tile = {}

---@param tiles LuaTile[] tiles to get adjacent tiles for
function tile_painter_tile.get_adjacent_tiles(tiles)
    local function hash(position)
        local a = position.x
        local b = position.y
        return 0.5 * (a + b) * (a + b + 1) + b
    end
    local surface = nil
    local positions = {}
    for i = 1, #tiles do
        if surface == nil then
            -- Always use the first surface, as all tiles should be on the same surface
            surface = tiles[i].surface
        end
        local tile = tiles[i]
        local position = flib_position.ensure_explicit(tile.position)
        positions[hash(position)] = position
    end

    local adjacent = {}
    for _, position in pairs(positions) do
        local offsets = { -1, 0, 1 }
        for _, x in pairs(offsets) do
            for _, y in pairs(offsets) do
                if not (x == 0 and y == 0) then
                    local new_position = { x = position.x + x, y = position.y + y }
                    if positions[hash(new_position)] == nil then
                        adjacent[#adjacent + 1] = surface.get_tile(new_position.x, new_position.y)
                    end
                end
            end
        end
    end
    return adjacent
end

return tile_painter_tile
