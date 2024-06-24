local position = require("__flib__.position")
local polygon = require("scripts.polygon")

--- @class tp_rendering
local tp_rendering = {}

local function angle(p1, p2)
    return math.atan2(p2.y - p1.y, p2.x - p1.x)
end

local function convertMapPositionToVertexTarget(vertices)
    local targets = {}
    for i = 1, #vertices do
        targets[i] = { target = vertices[i] }
    end
    return targets
end

-- Rerender the prototype polygon with the given centre and vertex
---@param self ShapeGui
function tp_rendering.draw_prospective_polygon(self)
    local n = self.nsides
    tp_rendering.destroy_renders(self)
    local r = position.distance(self.centre, self.vertex)
    local theta = angle(self.centre, self.vertex)
    if n == 0 then
        self.renders.polygon = rendering.draw_circle({
            radius = r,
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            width = 1,
            filled = false,
            target = self.centre,
            surface = self.surface,
            players = { self.player.index },
        })
    elseif n >= 2 then
        local vertices = convertMapPositionToVertexTarget(polygon.polygon_vertices(n, r, self.centre, theta))
        self.renders.polygon = rendering.draw_polygon({
            vertices = vertices,
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            surface = self.surface,
            players = { self.player.index },
        })
    end
    self.renders.box = rendering.draw_rectangle({
        left_top = position.add(self.centre, { x = -r, y = -r }),
        right_bottom = position.add(self.centre, { x = r, y = r }),
        color = { r = 1, g = 0.5, b = 0.31, a = 0.25 }, -- Coral
        surface = self.surface,
        players = { self.player.index },
        filled = false,
    })
end

---@param self ShapeGui
function tp_rendering.destroy_renders(self)
    if self.renders.polygon ~= nil then
        rendering.destroy(self.renders.polygon)
    end
    if self.renders.box ~= nil then
        rendering.destroy(self.renders.box)
    end
end

return tp_rendering
