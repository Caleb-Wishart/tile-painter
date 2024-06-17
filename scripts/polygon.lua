local position = require("__flib__.position")

--- @class tp_polygon
local tp_polygon = {}

-- Return the vertices of a polygon with n sides and a radius of r, centred about the given position, rotation of theta
--- @param n integer
---@param r integer
---@param centre LuaPosition the centre of the polygon
---@param theta number the rotation of the polygon
function tp_polygon.polygon_vertices(n, r, centre, theta)
    if n < 3 then return end
    local step = 2 * math.pi / n

    local rotation = math.pi / 2 - step
    local vertices = {}
    for i = 1, n do
        local x = r * math.cos(theta + step)
        local y = r * math.sin(theta + step)
        vertices[i] = position.add(centre, { x = x, y = y })
        rotation = rotation + step
    end
    return vertices
end

function tp_polygon.point_in_polygon(p, n, poly)
    p = position.ensure_explicit(p)
    local j = n
    local inside = false
    for i = 1, n do
        if ((poly[i].y > p.y) ~= (poly[j].y > p.y) and p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x) then
            inside = not inside
        end
        j = i
    end
    return inside
end

return tp_polygon
