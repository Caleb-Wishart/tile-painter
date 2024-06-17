local flib_position = require("__flib__.position")

--- @class tp_tile
local tp_tile = {}

---@param tiles LuaTile[] tiles to get adjacent tiles for
function tp_tile.get_adjacent_tiles(tiles)
    local function hash(position)
        -- https://forums.factorio.com/viewtopic.php?t=41879
        -- cantor pairing function v7
        local function NtoZ(x, y)
            return (x >= 0 and x or (-0.5 - x)), (y >= 0 and y or (-0.5 - y))
        end
        local x = position.x
        local y = position.y
        x, y = NtoZ(x, y)
        local s = x + y
        local h = s * (s + 0.5) + x
        return h + h
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

return tp_tile
