local flib_boundingBox = require("__flib__.bounding-box")
local flib_orientation = require("__flib__.orientation")

local bounding_box = require("scripts.bounding-box")

--- @class tp_surface
local tp_surface = {}

--- Build a tile ghost on the map.
--- @param surface LuaSurface the surface to build the tile on
--- @param tile_type string which tile to build
--- @param position TilePosition where to build the tile
--- @param force string|integer|LuaForce the force to build the tile for
function tp_surface.create_tile_ghost(surface, tile_type, position, force)
    -- TilePosition should be interchangeable with MapPosition
    ---@diagnostic disable-next-line: cast-type-mismatch
    local pos = position ---@cast pos MapPosition
    -- Using Alternative Function Signature
    ---@diagnostic disable-next-line: missing-parameter
    local tile = surface.get_tile(position)
    if tile.has_tile_ghost(force) then
        -- Docs are wrong, this returns a table of LuaEntites
        local ghosts = tile.get_tile_ghosts(force) ---@cast ghosts LuaEntity[]
        for _, ghost in pairs(ghosts) do
            if ghost.type == "tile-ghost" and ghost.ghost_name ~= tile_type then
                ghost.destroy()
            end
        end
    end
    if surface.can_place_entity { name = "tile-ghost", position = pos, inner_name = tile_type, force = force } then
        surface.create_entity { name = "tile-ghost", position = pos, inner_name = tile_type, force = force, expires = false }
    end
end

--- Build a tile ghost on the map.
--- @param surface LuaSurface the surface to build the tile on
--- @param tile_type string which tile to build
--- @param position TilePosition where to build the tile
--- @param player LuaPlayer the palyer to build the tile for
function tp_surface.remove_tile(surface, tile_type, position, player)
    -- Using Alternative Function Signature
    ---@diagnostic disable-next-line: missing-parameter
    local tile = surface.get_tile(position)
    local force = player.force ---@cast force LuaForce
    -- local e = surface.find_entity(tile_type, position)
    if tile.name == tile_type and not tile.to_be_deconstructed() then
        tile.order_deconstruction(force, player)
    end
    if tile.has_tile_ghost(force) then
        -- Docs are wrong, this returns a table of LuaEntites
        local ghosts = tile.get_tile_ghosts(force) ---@cast ghosts LuaEntity[]
        for _, ghost in pairs(ghosts) do
            if ghost.type == "tile-ghost" and ghost.ghost_name == tile_type then
                ghost.destroy()
            end
        end
    end
end

--- Find all tiles of the given name in the given area.
---
--- If no filters are given, this returns all tiles in the search area.
---
--- If no `area` or `position` and `radius` is given, the entire surface is searched. If `position` and `radius` are given, only tiles within the radius of the position are included.
--- @param surface LuaSurface the surface to find tiles on
--- @param param TileSearchFilters
--- @return (LuaTile)[]
function tp_surface.find_tiles_filtered(surface, param)
    local area = param.area
    -- If no area is specified
    if area == nil then
        return surface.find_tiles_filtered(param)
    end
    area = bounding_box.ensure_explicit(area)
    -- if no orientation is specified or is specified but has no effect
    if area.orientation == nil or area.orientation == flib_orientation.north or area.orientation == flib_orientation.south then
        return surface.find_tiles_filtered(param)
    end
    -- If the orientation is east or west, (90/270 degree rotation) we can just rotate the area normally
    if area.orientation == flib_orientation.east or area.orientation == flib_orientation.west then
        param.area = flib_boundingBox.rotate(area)
        return surface.find_tiles_filtered(param)
    end
    -- Else we need to do some math

    local box = bounding_box.convert_to_OBB(area)

    local pts = {}
    for _, point in pairs(box) do
        if pts.top == nil or point.y < pts.top.y then
            pts.top = point
        end
        if pts.bottom == nil or point.y > pts.bottom.y then
            pts.bottom = point
        end
        if pts.left == nil or point.x < pts.left.x then
            pts.left = point
        end
        if pts.right == nil or point.x > pts.right.x then
            pts.right = point
        end
    end

    -- The following functions correspond the the areas above / below the edge of the box
    -- Example at 45 degree rotation but a will always be the bottom right edge when
    --- orientation not in [0, 0.25, 0.5, 0.75], N,S,E,W
    --
    -- c /\ b
    --  /  \
    --  \  /
    -- d \/ a
    local angle = area.orientation * bounding_box.orientation_to_rad
    local tan = math.tan(angle)
    local tan90 = math.tan(angle - math.pi / 2)

    local afunc = function(x) return tan * x + (pts.bottom.y - tan * pts.bottom.x) end
    local bfunc = function(x) return tan90 * x + (pts.top.y - tan90 * pts.top.x) end
    local cfunc = function(x) return tan * x + (pts.top.y - tan90 * pts.top.x) end
    local dfunc = function(x) return tan90 * x + (pts.bottom.y - tan90 * pts.bottom.x) end


    local res = {}

    -- Find tiles within the area
    param.area = {
        left_top = { x = pts.left.x, y = pts.top.y },
        right_bottom = { x = pts.right.x, y = pts.bottom.y },
    }
    local search_tiles = surface.find_tiles_filtered(param)
    for i = #search_tiles, 1, -1 do
        local tile = search_tiles[i]
        local tile_box = flib_boundingBox.from_position(tile.position, true)
        local tile_box4 = bounding_box.convert_to_BB4(tile_box)

        if bounding_box.line_intersect_AABB(box.left_top, box.right_top, tile_box)
            or bounding_box.line_intersect_AABB(box.right_top, box.right_bottom, tile_box)
            or bounding_box.line_intersect_AABB(box.right_bottom, box.left_bottom, tile_box)
            or bounding_box.line_intersect_AABB(box.left_bottom, box.left_top, tile_box) then
            -- If the tile intersects the line of the edge of the box
            table.insert(res, tile)
        elseif afunc(tile_box4.left_top.x) < tile_box4.left_top.y
            and bfunc(tile_box4.left_bottom.x) > tile_box4.left_bottom.y
            and cfunc(tile_box4.right_bottom.x) > tile_box4.right_bottom.y
            and dfunc(tile_box4.right_top.x) < tile_box4.right_top.y then
            -- If the tile is within the area
            table.insert(res, tile)
        end
    end
    return res
end;

return tp_surface
