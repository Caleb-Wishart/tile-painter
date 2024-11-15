local flib_position = require("__flib__.position")
-- note that these functions will destroy any Orientation data passed in
local flib_boundingBox = require("__flib__.bounding-box")

---Four positions, specifying the top-left, top-right, bottom-left bottom-right corner of the box respectively.
---It is used as the result of applying the Orientation of a BoundingBox to the corners of the box.
---
--- left_top in this context refers to left_top in initial box and may may not be the left_top in the rotated box
---
---[View BoundingBox Documentation](https://lua-api.factorio.com/latest/concepts.html#BoundingBox)
---
do
    ---@class OrientedBoundingBox
    ---@field left_top MapPosition
    ---@field right_top MapPosition
    ---@field left_bottom MapPosition
    ---@field right_bottom MapPosition
    local OrientedBoundingBox = {
    }
end

---A subclass of BoundingBox that specifies all four positions top-left, top-right, bottom-left, bottom-right as well as orientation.
---
---[View BoundingBox Documentation](https://lua-api.factorio.com/latest/concepts.html#BoundingBox)
---
do
    ---@class BoundingBox4
    ---@field left_top MapPosition
    ---@field right_top MapPosition
    ---@field left_bottom MapPosition
    ---@field right_bottom MapPosition
    ---@field orientation RealOrientation
    local BoundingBox4 = {
    }
end



--- @class tp_bounding_box
local tp_bounding_box = {}


--- Multiply by orientation to covert to radians.
--- ```lua
--- local angle = area.orientation * orientation_to_rad
--- ```
tp_bounding_box.orientation_to_rad = 2 * math.pi --- @type number


--- Return the box in explicit form.
--- Function is identical to flib_boundingBox.ensure_explicit except
--- that is preserves orientation.
--- @param box BoundingBox
--- @return BoundingBox
function tp_bounding_box.ensure_explicit(box)
    return {
        left_top = flib_position.ensure_explicit(box.left_top or box[1]),
        right_bottom = flib_position.ensure_explicit(box.right_bottom or box[2]),
        orientation = box.orientation or box[3] or 0
    }
end

--- Return the box with additional properties left_bottom, right_top.
--- @param box BoundingBox
--- @return BoundingBox4
function tp_bounding_box.convert_to_BB4(box)
    return {
        left_top = flib_position.ensure_explicit(box.left_top or box[1]),
        right_bottom = flib_position.ensure_explicit(box.right_bottom or box[2]),
        right_top = { x = box.right_bottom.x or box[2][1], y = box.left_top.y or box[1][2] },
        left_bottom = { x = box.left_top.x or box[1][1], y = box.right_bottom.y or box[2][2] },
        orientation = box.orientation or box[3] or 0
    }
end

--- Return a new box grown or shrunk by the given delta.
--- A positive delta will grow the box, a negative delta will
--- shrink it.
--- @param box BoundingBox
--- @param delta number
--- @return BoundingBox
function tp_bounding_box.resize(box, delta)
    local ebox = tp_bounding_box.ensure_explicit(box)
    return {
        left_top = { x = ebox.left_top.x - delta, y = ebox.left_top.y - delta },
        right_bottom = { x = ebox.right_bottom.x + delta, y = ebox.right_bottom.y + delta },
        orientation = ebox.orientation or 0
    }
end

--- Check in see if a line (pos1->pos2) insersects with the given bounding box.
--  The box must be an Axis Aligned Bounding Box
--- @param pos1 MapPosition start of the line
--- @param pos2 MapPosition end of the line
--- @param box BoundingBox The bounding box or rectangle
function tp_bounding_box.line_intersect_AABB(pos1, pos2, box)
    local pos1, pos2 = flib_position.ensure_explicit(pos1), flib_position.ensure_explicit(pos2)
    local area = tp_bounding_box.ensure_explicit(box)

    local l, t, r, b = area.left_top.x, area.left_top.y, area.right_bottom.x, area.right_bottom.y
    local x1, y1, x2, y2 = pos1.x, pos1.y, pos2.x, pos2.y
    -- normalize segment
    local dx, dy = x2 - x1, y2 - y1
    local d = math.sqrt(dx * dx + dy * dy) -- sqrt(Dot(v))
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

return tp_bounding_box
