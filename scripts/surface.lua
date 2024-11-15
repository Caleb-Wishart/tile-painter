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

return tp_surface
