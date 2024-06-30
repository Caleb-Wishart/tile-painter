local position = require("__flib__.position")

local polygon = require("scripts.polygon")

--- @class tp_rendering
local tp_rendering = {}

-- Rerender the prototype polygon with the given centre and vertex
---@param tdata ShapeTabData
---@param player LuaPlayer
function tp_rendering.draw_prospective_polygon(tdata, player)
    local n = tdata.nsides
    tp_rendering.destroy_renders(tdata)
    local r = position.distance(tdata.centre, tdata.vertex)
    local theta = polygon.angle(tdata.centre, tdata.vertex)
    if n == 1 then
        tdata.renders.polygon = rendering.draw_circle({
            radius = r,
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            width = 1,
            filled = false,
            target = tdata.centre,
            surface = tdata.surface,
            players = { player.index },
        })
    elseif n == 2 then
        tdata.renders.polygon = rendering.draw_line({
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            width = 1,
            from = tdata.centre,
            to = tdata.vertex,
            surface = tdata.surface,
            players = { player.index },
        })
    elseif n > 2 then
        local vertices = polygon.polygon_vertex_targets(n, r, tdata.centre, theta)
        tdata.renders.polygon = rendering.draw_polygon {
            vertices = vertices,
            color = { r = 1, g = 0.5, b = 0.31, a = 0.5 }, -- Coral
            surface = tdata.surface,
            players = { player.index },
        }
    end
    tdata.renders.box = rendering.draw_rectangle({
        left_top = position.add(tdata.centre, { x = -r, y = -r }),
        right_bottom = position.add(tdata.centre, { x = r, y = r }),
        color = { r = 1, g = 0.5, b = 0.31, a = 0.25 }, -- Coral
        surface = tdata.surface,
        players = { player.index },
        filled = false,
    })
    tdata.renders.centre = rendering.draw_circle({
        radius = 0.1,
        color = { r = 0, g = 1, b = 1, a = 0.25 }, -- Cyan
        width = 1,
        filled = true,
        target = tdata.centre,
        surface = tdata.surface,
        players = { player.index },
    })
    tdata.renders.vertex = rendering.draw_circle({
        radius = 0.1,
        color = { r = 0.6, g = 0.2, b = 0.8, a = 0.25 }, -- Dark Orchid
        width = 1,
        filled = true,
        target = tdata.vertex,
        surface = tdata.surface,
        players = { player.index },
    })
end

---@param tdata ShapeTabData
function tp_rendering.destroy_renders(tdata)
    if tdata.renders.polygon ~= nil then
        rendering.destroy(tdata.renders.polygon)
    end
    if tdata.renders.box ~= nil then
        rendering.destroy(tdata.renders.box)
    end
    if tdata.renders.centre ~= nil then
        rendering.destroy(tdata.renders.centre)
    end
    if tdata.renders.vertex ~= nil then
        rendering.destroy(tdata.renders.vertex)
    end
end

return tp_rendering
