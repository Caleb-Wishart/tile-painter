local flib_position = require("__flib__.position")

local polygon = require("scripts.polygon")
local color = require("scripts.color")

--- @class tp_rendering
local tp_rendering = {}

-- Render the polygon selected poitns
--- @param tdata ShapeTabData
--- @param player LuaPlayer
--- @param clear boolean?
function tp_rendering.draw_polygon_points(tdata, player, clear)
    if clear then
        tp_rendering.destroy_renders(tdata)
    end
    -- Draw the centre and vertex
    if tdata.settings.show_centre and tdata.centre then
        tdata.renders[#tdata.renders + 1] = rendering.draw_circle({
            radius = 0.2,
            color = color.cyan(0.5), -- Cyan
            width = 1,
            filled = true,
            target = tdata.centre,
            surface = tdata.surface,
            players = { player.index },
            draw_on_ground = true,
        })
    end
    if tdata.settings.show_vertex and tdata.vertex then
        tdata.renders[#tdata.renders + 1] = rendering.draw_circle({
            radius = 0.2,
            color = color.emerald(0.5),
            width = 1,
            filled = true,
            target = tdata.vertex,
            surface = tdata.surface,
            players = { player.index },
            draw_on_ground = true,
        })
    end
end

function tp_rendering.draw_polygon_tiles(tdata, player)
    for _, tile in pairs(tdata.tiles) do
        tdata.renders[#tdata.renders + 1] = rendering.draw_rectangle({
            left_top = tile.position,
            right_bottom = flib_position.add(tile.position, { x = 1, y = 1 }),
            color = color.gray(0.1),
            surface = tdata.surface,
            players = { player.index },
            filled = true,
            draw_on_ground = true,
        })
    end
end

-- Rerender the prototype polygon with the given centre and vertex
--- @param tdata ShapeTabData
--- @param player LuaPlayer
function tp_rendering.draw_prospective_polygon(tdata, player)
    tp_rendering.destroy_renders(tdata)
    local n = tdata.nsides
    local r = tdata.radius ---@cast r -nil
    local theta = tdata.theta ---@cast theta -nil
    -- Draw the bounding box
    if tdata.settings.show_bounding_box then
        tdata.renders[#tdata.renders + 1] = rendering.draw_rectangle({
            left_top = flib_position.add(tdata.centre, { x = -r, y = -r }),
            right_bottom = flib_position.add(tdata.centre, { x = r, y = r }),
            color = color.lavender_magenta(0.5),
            surface = tdata.surface,
            players = { player.index },
            filled = false,
            draw_on_ground = true,
        })
    end
    if tdata.settings.show_tiles then
        tp_rendering.draw_polygon_tiles(tdata, player)
    end
    if n == 1 then
        if tdata.fill and not tdata.settings.show_tiles then
            tdata.renders[#tdata.renders + 1] = rendering.draw_circle({
                radius = r,
                color = color.gray(0.1),
                width = 0,
                filled = tdata.fill,
                target = tdata.centre,
                surface = tdata.surface,
                players = { player.index },
                draw_on_ground = true,
            })
        end
        tdata.renders[#tdata.renders + 1] = rendering.draw_circle({
            radius = r,
            color = color.coral(),
            width = 2,
            filled = false,
            target = tdata.centre,
            surface = tdata.surface,
            players = { player.index },
            draw_on_ground = true,
        })
    elseif n == 2 then
        tdata.renders[#tdata.renders + 1] = rendering.draw_line({
            color = color.coral(),
            width = 1,
            from = tdata.centre,
            to = tdata.vertex,
            surface = tdata.surface,
            players = { player.index },
            draw_on_ground = true,
        })
    elseif n > 2 then
        local vertices = polygon.polygon_targets(n, r, tdata.centre, theta)
        if tdata.fill and not tdata.settings.show_tiles then
            tdata.renders[#tdata.renders + 1] = rendering.draw_polygon {
                vertices = polygon.shape_to_strip(vertices),
                color = color.gray(0.1),
                surface = tdata.surface,
                players = { player.index },
                draw_on_ground = true,
            }
        end
        for i = 1, #vertices do
            tdata.renders[#tdata.renders + 1] = rendering.draw_line({
                color = color.coral(),
                width = 2,
                from = vertices[i].target,
                to = vertices[i % #vertices + 1].target,
                surface = tdata.surface,
                players = { player.index },
                draw_on_ground = true,
            })
        end
    end
    if tdata.settings.show_radius and n ~= 2 then
        tdata.renders[#tdata.renders + 1] = rendering.draw_line({
            color = color.debian_red(0.5),
            width = 1,
            from = tdata.centre,
            to = tdata.vertex,
            surface = tdata.surface,
            players = { player.index },
            draw_on_ground = true,
        })
    end
    tp_rendering.draw_polygon_points(tdata, player)
end

--- @param tdata ShapeTabData
function tp_rendering.destroy_renders(tdata)
    for _, render in pairs(tdata.renders) do
        rendering.destroy(render)
    end
end

return tp_rendering
