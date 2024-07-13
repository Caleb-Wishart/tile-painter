local flib_position = require("__flib__.position")

--- @class tp_polygon
local tp_polygon = {}

--- @param vertices MapPosition[]
--- @return ScriptRenderVertexTarget[]
local function position_to_vertex_target(vertices)
    local targets = {}
    for i = 1, #vertices do
        targets[i] = { target = vertices[i] }
    end
    return targets
end

-- reorders the given array to result in: last, first, second last, second, etc...
-- more visually: 1, 2, 3, 4, 5, 6, 7, 8 -> 8, 1, 7, 2, 6, 3, 5, 4
-- translates a shape into a strip used for draw_polygon
-- @jansharp factorio discord
function tp_polygon.shape_to_strip(shape)
    local strip = {}
    local shape_length = #shape
    local next_index = shape_length
    for i = 1, shape_length do
        strip[i] = shape[next_index]
        next_index = (shape_length - next_index) + (i % 2)
    end
    return strip
end

-- Return the vertices of a polygon with n sides and a radius of r, centred about the given position, rotation of theta
--- @param n integer
--- @param r integer
--- @param centre MapPosition the centre of the polygon
--- @param theta number the rotation of the polygon
function tp_polygon.polygon_targets(n, r, centre, theta)
    return position_to_vertex_target(tp_polygon.polygon_vertices(n, r, centre, theta))
end

-- Return the vertices of a polygon with n sides and a radius of r, centred about the given position, rotation of theta
--- @param n integer
--- @param r integer
--- @param centre MapPosition the centre of the polygon
--- @param theta number the rotation of the polygon
--- @return MapPosition[]
function tp_polygon.polygon_vertices(n, r, centre, theta)
    local step = 2 * math.pi / n

    local rotation = 0
    local vertices = {}
    for i = 1, n do
        local x = r * math.cos(theta + rotation)
        local y = r * math.sin(theta + rotation)
        vertices[i] = flib_position.add(centre, { x = x, y = y })
        rotation = rotation + step
    end
    return vertices
end

function tp_polygon.point_in_polygon(p, n, poly)
    p = flib_position.ensure_explicit(p)
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

function tp_polygon.angle(p1, p2)
    return math.atan2(p2.y - p1.y, p2.x - p1.x)
end

return tp_polygon
