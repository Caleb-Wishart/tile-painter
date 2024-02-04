local flib_boundingBox = require("__flib__/bounding-box")
local flib_position = require("__flib__/position")
local util = require("__tile-painter__/util")

local print = util.print

--- Find if a line intersects a rectangle.
-- Based on:
-- https://2dengine.com/doc/intersections.html#Segment_vs_rectangle
--- @param pos1 MapPosition start of the line
--- @param pos2 MapPosition end of the line
--- @param box BoundingBox to represent the rectangle
function lineIntersectRect(pos1, pos2, box)
  local pos1, pos2 = flib_position.ensure_explicit(pos1), flib_position.ensure_explicit(pos2)
  local box = ensure_explicit(box)
  local l, t, r, b = box.left_top.x, box.left_top.y, box.right_bottom.x, box.right_bottom.y
  local x1, y1, x2, y2 = pos1.x, pos1.y, pos2.x, pos2.y
  -- normalize segment
  local dx, dy = x2 - x1, y2 - y1
  local d = math.sqrt(dx * dx + dy * dy)
  if d == 0 then
    return false
  end
  local nx, ny = dx / d, dy / d
  -- minimum and maximum intersection values
  local tmin, tmax = 0, d
  -- x-axis check
  if nx == 0 then
    if x1 < l or x1 > r then
      return false
    end
  else
    local t1, t2 = (l - x1) / nx, (r - x1) / nx
    if t1 > t2 then
      t1, t2 = t2, t1
    end
    tmin = math.max(tmin, t1)
    tmax = math.min(tmax, t2)
    if tmin > tmax then
      return false
    end
  end
  -- y-axis check
  if ny == 0 then
    if y1 < t or y1 > b then
      return false
    end
  else
    local t1, t2 = (t - y1) / ny, (b - y1) / ny
    if t1 > t2 then
      t1, t2 = t2, t1
    end
    tmin = math.max(tmin, t1)
    tmax = math.min(tmax, t2)
    if tmin > tmax then
      return false
    end
  end
  return true
end

function resize(area, delta)
  local box = ensure_explicit(area)
  if box.left_top then
    return {
      left_top = { x = box.left_top.x - delta, y = box.left_top.y - delta },
      right_bottom = { x = box.right_bottom.x + delta, y = box.right_bottom.y + delta },
    }
  else
    return {
      { box[1][1] - delta, box[1][2] - delta },
      { box[2][1] + delta, box[2][2] + delta },
      box[3]
    }
  end
end

---@param entity LuaEntity
local function paint_concrete_tiles(entity)
  local surface = entity.surface
  local force = entity.force

  -- Bounding Box functions
  ---@param param LuaSurface.find_tiles_filtered_param
  ---@return (LuaTile)[]
  local function find_tiles_filtered(param)
    local area = param.area
    -- If no area is specified
    if area == nil then
      return surface.find_tiles_filtered(param)
    end
    area = ensure_explicit(area)
    -- if no orientation is specified or is specified but has no effect
    if area.orientation == nil or area.orientation == 0 or area.orientation == 1 or area.orientation == 0.5 then
      return surface.find_tiles_filtered(param)
    end
    -- If the orientation is 0.25 or 0.75, (90/270 degree rotation) we can just rotate the area normally
    if area.orientation == 0.25 or area.orientation == 0.75 then
      param.area = flib_boundingBox.rotate(area)
      return surface.find_tiles_filtered(param)
    end
    -- Else we need to do some math :)
    -- Calculate the center of the area
    local midpoint = flib_boundingBox.center(area)

    -- Calculate utility values
    local angle = area.orientation * 2 * math.pi
    local sin = math.sin(angle)
    local cos = math.cos(angle)
    local tan = math.tan(angle)
    local tan90 = math.tan(angle - math.pi / 2)
    -- Center the corners around the midpoint to apply orientation to center of the area
    local centre_box = flib_boundingBox.recenter_on(area, { x = 0, y = 0 })

    local cen_lt = centre_box.left_top
    local cen_br = centre_box.right_bottom
    -- Calculate position of the corners after rotation
    -- Positions are based on transformation of a rotation matrix
    -- top_left in this context refers to top_left in initial box and may may not be the top_left in the rotated box
    -- https://en.wikipedia.org/wiki/Rotation_matrix
    local rotated_area = {
      top_left = flib_position.add({ x = cen_lt.x * cos - cen_lt.y * sin, y = cen_lt.x * sin + cen_lt.y * cos },
        midpoint),
      top_right = flib_position.add({ x = cen_br.x * cos - cen_lt.y * sin, y = cen_br.x * sin + cen_lt.y * cos },
        midpoint),
      bottom_left = flib_position.add({ x = cen_lt.x * cos - cen_br.y * sin, y = cen_lt.x * sin + cen_br.y * cos },
        midpoint),
      bottom_right = flib_position.add({ x = cen_br.x * cos - cen_br.y * sin, y = cen_br.x * sin + cen_br.y * cos },
        midpoint),
    }


    --      |        |
    --  -,- | +,-    |
    --   -------     | y positive
    --  -,+ | +,+    |
    --      |       \/
    --  ----------->
    --      x positive

    local box = {}
    for _, point in pairs(rotated_area) do
      if box.lowest_point == nil or point.y > box.lowest_point.y then
        box.lowest_point = point
      end
      if box.highest_point == nil or point.y < box.highest_point.y then
        box.highest_point = point
      end
      if box.leftmost_point == nil or point.x < box.leftmost_point.x then
        box.leftmost_point = point
      end
      if box.rightmost_point == nil or point.x > box.rightmost_point.x then
        box.rightmost_point = point
      end
    end

    -- The following functions correspond the the areas above / below the edge of the box
    -- Example at 45 degree rotation but a will always be the bottom right edge
    -- i.e the array a will contain all tiles that are above the gradient line of that edge of the box
    -- By removing tiles that do not fit we can find the tiles that are within the rotated area
    --
    -- c /\ b
    --  /  \
    --  \  /
    -- d \/ a

    local afunc = function(x) return tan * x + (box.lowest_point.y - tan * box.lowest_point.x) end
    local bfunc = function(x) return tan90 * x + (box.highest_point.y - tan90 * box.highest_point.x) end
    local cfunc = function(x) return tan * x + (box.highest_point.y - tan90 * box.highest_point.x) end
    local dfunc = function(x) return tan90 * x + (box.lowest_point.y - tan90 * box.lowest_point.x) end
    local result = {}

    -- Find tiles within the area
    -- print("Rotated Area", box)
    local search_area = { left_top = { x = box.leftmost_point.x, y = box.highest_point.y }, right_bottom = { x = box.rightmost_point.x, y = box.lowest_point.y } }
    param.area = search_area
    local search_tiles = surface.find_tiles_filtered(param)
    -- print("Search Tiles", search_tiles)
    for i = #search_tiles, 1, -1 do
      local tile = search_tiles[i]
      local tile_box = ensure_super_explicit(flib_boundingBox.from_position(tile.position, true))

      -- If the tile intersects the line of the edge of the box
      if lineIntersectRect(rotated_area.top_left, rotated_area.top_right, tile_box)
          or lineIntersectRect(rotated_area.top_right, rotated_area.bottom_right, tile_box)
          or lineIntersectRect(rotated_area.bottom_right, rotated_area.bottom_left, tile_box)
          or lineIntersectRect(rotated_area.bottom_left, rotated_area.top_left, tile_box) then
        table.insert(result, tile)
        -- If the tile is within the area
      elseif afunc(tile_box.left_top.x) < tile_box.left_top.y
          and bfunc(tile_box.left_bottom.x) > tile_box.left_bottom.y
          and cfunc(tile_box.right_bottom.x) > tile_box.right_bottom.y
          and dfunc(tile_box.right_top.x) < tile_box.right_top.y then
        table.insert(result, tile)
      end
    end
    return result
  end;
  -- print("Position", entity.position)
  -- print("bounding_box", entity.bounding_box)
  -- print("secondary_bounding_box", entity.secondary_bounding_box)
  -- https://wiki.factorio.com/Data.raw#tile
  local search_boxes = { { area = entity.bounding_box, tile_type = "stone-path" } }
  if entity.secondary_bounding_box ~= nil then
    table.insert(search_boxes, { area = entity.secondary_bounding_box, tile_type = "stone-path" })
  end
  table.insert(search_boxes, { area = resize(entity.bounding_box, 1), tile_type = "concrete" })
  if entity.secondary_bounding_box ~= nil then
    table.insert(search_boxes,
      { area = resize(entity.secondary_bounding_box, 1), tile_type = "concrete" })
  end

  for i = 1, #search_boxes do
    local search_box = search_boxes[i].area
    local tile_type = search_boxes[i].tile_type
    local available_tiles = find_tiles_filtered { has_hidden_tile = false, area = search_box } -- , has_tile_ghost = false, force = force
    for j = #available_tiles, 1, -1 do
      util.create_tile_ghost(surface, tile_type, available_tiles[j].position, force)
    end
  end
end

--- Return the box in explicit form.
--- Use this function instead of builtin flib as flib doesn't support orientation.
--- @param box BoundingBox
--- @return BoundingBox
function ensure_explicit(box)
  return {
    left_top = flib_position.ensure_explicit(box.left_top or box[1]),
    right_bottom = flib_position.ensure_explicit(box.right_bottom or box[2]),
    orientation = box.orientation or box[3] or 0
  }
end

--- Return the box in super explicit form.
--- @param box BoundingBox
function ensure_super_explicit(box)
  return {
    left_top = flib_position.ensure_explicit(box.left_top or box[1]),
    right_bottom = flib_position.ensure_explicit(box.right_bottom or box[2]),
    right_top = { x = box.right_bottom.x or box[2][1], y = box.left_top.y or box[1][2] },
    left_bottom = { x = box.left_top.x or box[1][1], y = box.right_bottom.y or box[2][2] },
    orientation = box.orientation or box[3] or 0
  }
end

--- comment
---@param event EventData
local function on_player_selected_area(event)
  if event.item == "tile-painter" then
    for k, entity in pairs(event.entities) do
      paint_concrete_tiles(entity)
    end
  end
end
script.on_event(defines.events.on_player_selected_area, on_player_selected_area)
