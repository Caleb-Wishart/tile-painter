local flib_orientation = require("__flib__.orientation")
local flib_position = require("__flib__.position")
local flib_boundingBox = require("__flib__.bounding-box")

local bounding_box = require("scripts.bounding-box")
local surfacelib = require("scripts.surface")
local tilelib = require("scripts.tile")
local polygon = require("scripts.polygon")

local curved_rail_mask = require("scripts.curved-rail")
local get_player_settings = require("util").get_player_settings


--- @class tp_painter
local tp_painter = {}

local function get_entity_tiles(player, entity, delta)
    local surface = entity.surface
    local box = bounding_box.ensure_explicit(entity.bounding_box)
    local search_boxes = { box }
    if get_player_settings(player.index, "entity-smooth-curved-rail") and entity.name == "curved-rail" then
        -- Use a special mapping
        local tiles = {}
        for _, position in pairs(curved_rail_mask(entity.direction, delta)) do
            local pos = flib_position.add(entity.position, position)
            local tile = surface.get_tile(pos)
            tiles[#tiles + 1] = tile
        end
        return tiles
    end

    if entity.secondary_bounding_box ~= nil then
        table.insert(search_boxes, bounding_box.ensure_explicit(entity.secondary_bounding_box))
    end
    local tiles = {}
    for i = 1, #search_boxes do
        local sbox = search_boxes[i]
        local temp_tiles = nil
        if sbox.orientation ~= flib_orientation.north
            and sbox.orientation ~= flib_orientation.east
            and sbox.orientation ~= flib_orientation.south
            and sbox.orientation ~= flib_orientation.west then
            -- If the bounding box has an orientation and isn't a simple rectangle,
            -- we can't safely resize it and have to get adjacent tiles
            local area = sbox
            local search_param = { area = area }
            temp_tiles = surfacelib.find_tiles_filtered(surface, search_param)
            for _ = 1, delta do
                local adj_tiles = tilelib.get_adjacent_tiles(temp_tiles)
                for j = 1, #adj_tiles do
                    temp_tiles[#temp_tiles + 1] = adj_tiles[j]
                end
            end
        else
            -- It is more efficient to resize the bounding box and get all tiles in the area
            local area = bounding_box.resize(sbox, delta)
            local search_param = { area = area }
            temp_tiles = surfacelib.find_tiles_filtered(surface, search_param)
        end
        for j = 1, #temp_tiles do
            tiles[#tiles + 1] = temp_tiles[j]
        end
    end
    return tiles
end

--- @param player LuaPlayer the player to paint the tiles for
--- @param entity LuaEntity reference entity
--- @param tile_type string the tile to ghost
--- @param delta number the delta to grow the bounding box(es) by
--- @param whatIf boolean? if true, don't create tile ghosts and return the tiles
function tp_painter.paint_entity(player, entity, tile_type, delta, whatIf)
    local tiles = get_entity_tiles(player, entity, delta)
    if whatIf then
        return tiles
    end
    local force = player.force ---@cast force LuaForce
    tp_painter.paint_tiles(tiles, entity.surface, tile_type, force)
end

--- @param player LuaPlayer the player to remove the tiles for
--- @param entity LuaEntity reference entity
--- @param tile_type string the tile to remove
--- @param delta number the delta to grow the bounding box(es) by
--- @param whatIf boolean? if true, don't create tile ghosts and return the tiles
function tp_painter.remove_paint_entity(player, entity, tile_type, delta, whatIf)
    local tiles = get_entity_tiles(player, entity, delta)
    if whatIf then
        return tiles
    end
    tp_painter.remove_tiles(tiles, entity.surface, tile_type, player)
end

--- @param player LuaPlayer the player to paint the tiles for
--- @param tdata ShapeTabData
--- @param whatIf boolean? if true, don't create tile ghosts and return the tiles
function tp_painter.paint_polygon(player, tdata, whatIf)
    local n = tdata.nsides
    local r = tdata.radius ---@cast r -nil
    local theta = tdata.theta ---@cast theta -nil
    local bb = {
        left_top = flib_position.add(tdata.center, { x = -r, y = -r }),
        right_bottom = flib_position.add(tdata.center, { x = r, y = r }),
    }
    local surface = game.surfaces[tdata.surface]
    local area = surfacelib.find_tiles_filtered(surface, { area = bb })
    local tiles = {}
    if n == 1 then
        local c = tdata.center ---@cast c -nil
        local delta = math.sqrt(2) / 2
        for _, tile in pairs(area) do
            local pos = flib_position.ensure_explicit(tile.position)
            pos = flib_position.add(pos, { 0.5, 0.5 })
            local d = math.sqrt(math.pow(pos.x - c.x, 2) + math.pow(pos.y - c.y, 2))
            if tdata.fill and d <= r or math.abs(d - r) < delta then
                table.insert(tiles, tile)
            end
        end
    elseif n == 2 then
        local p1 = tdata.center ---@cast p1 -nil
        local p2 = tdata.vertex ---@cast p2 -nil
        for _, tile in pairs(area) do
            if bounding_box.line_intersect_AABB(p1, p2, flib_boundingBox.from_position(tile.position, true)) then
                table.insert(tiles, tile)
            end
        end
    elseif n > 2 then
        -- TODO: find inner BB and exclude from search area to reduce number of tiles to check
        local vertices = polygon.polygon_vertices(n, r, tdata.center, theta)
        for _, tile in pairs(area) do
            local insert = false
            if n ~= 2 and tdata.fill and polygon.point_in_polygon(tile.position, n, vertices) then
                insert = true
            end
            for i = 1, n do
                local p1 = vertices[i]
                local p2 = vertices[i % #vertices + 1]
                if bounding_box.line_intersect_AABB(p1, p2, flib_boundingBox.from_position(tile.position, true)) then
                    insert = true
                    break
                end
            end
            if insert then
                table.insert(tiles, tile)
            end
        end
    end
    if whatIf then
        return tiles
    end
    tp_painter.paint_tiles(tiles, surface, tdata.tile_type, player.force)
end

--- @param tiles LuaTile[]
local function flood_fill(tiles)
    -- Templating
end


--- @param tiles LuaTile[]
--- @param boundary string
local function boundary_fill(tiles, boundary)
    -- Templating
end

-- Paints tiles around the selected point.
-- Combination of settings in player settings and the UI
--- @param player LuaPlayer the player to paint the tiles for
--- @param tile_type string the tile to ghost
function tp_painter.paint_fill_tool(player, surface, position, tile_type, border)
    --  Use a setting here to restrict to only admins to prevent griefing
    local max_radius = get_player_settings(player.index, "fill-max-distance")
    local search_param = { has_hidden_tile = false, position = position, radius = max_radius }
    local tiles = surfacelib.find_tiles_filtered(surface, search_param)
    -- Templating
end

function tp_painter.paint_tiles(tiles, surface, tile_type, force)
    for i = 1, #tiles do
        surfacelib.create_tile_ghost(surface, tile_type, tiles[i].position, force)
    end
end

function tp_painter.remove_tiles(tiles, surface, tile_type, player)
    for i = 1, #tiles do
        surfacelib.remove_tile(surface, tile_type, tiles[i].position, player)
    end
end

return tp_painter
