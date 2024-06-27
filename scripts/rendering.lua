local position = require("__flib__.position")

local polygon = require("scripts.polygon")

--- @class tp_rendering
local tp_rendering = {}

local function angle(p1, p2)
    return math.atan2(p2.y - p1.y, p2.x - p1.x)
end

-- Rerender the prototype polygon with the given centre and vertex
---@param self ShapeGui
function tp_rendering.draw_prospective_polygon(self)
    local n = self.nsides
    tp_rendering.destroy_renders(self)
    local r = position.distance(self.centre, self.vertex)
    local theta = angle(self.centre, self.vertex)
    if n == 1 then
        self.renders.polygon = rendering.draw_circle({
            radius = r,
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            width = 1,
            filled = false,
            target = self.centre,
            surface = self.surface,
            players = { self.player.index },
        })
    elseif n == 2 then
        self.renders.polygon = rendering.draw_line({
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            width = 1,
            from = self.centre,
            to = self.vertex,
            surface = self.surface,
            players = { self.player.index },
        })
    elseif n > 2 then
        local vertices = polygon.polygon_vertex_targets(n, r, self.centre, theta)
        self.renders.polygon = rendering.draw_polygon {
            vertices = vertices,
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            surface = self.surface,
            players = { self.player.index },
        }
        game.print("render polygon: " .. self.renders.polygon)
    end
    self.renders.box = rendering.draw_rectangle({
        left_top = position.add(self.centre, { x = -r, y = -r }),
        right_bottom = position.add(self.centre, { x = r, y = r }),
        color = { r = 1, g = 0.5, b = 0.31, a = 0.25 }, -- Coral
        surface = self.surface,
        players = { self.player.index },
        filled = false,
    })
    self.renders.centre = rendering.draw_circle({
        radius = 0.1,
        color = { r = 0, g = 1, b = 1, a = 0.25 }, -- Cyan
        width = 1,
        filled = true,
        target = self.centre,
        surface = self.surface,
        players = { self.player.index },
    })
    self.renders.vertex = rendering.draw_circle({
        radius = 0.1,
        color = { r = 0.6, g = 0.2, b = 0.8, a = 0.25 }, -- Dark Orchid
        width = 1,
        filled = true,
        target = self.vertex,
        surface = self.surface,
        players = { self.player.index },
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
    if self.renders.centre ~= nil then
        rendering.destroy(self.renders.centre)
    end
    if self.renders.vertex ~= nil then
        rendering.destroy(self.renders.vertex)
    end
end

return tp_rendering
