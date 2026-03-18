local Flib_position = require("__flib__.position")
local Flib_table = require("__flib__.table")

local Painter = require("scripts.painter")

local Rail = require("scripts.util.rail_mask")
local RailTab = require("scripts.gui.tab.rail")

local TileLib = require("scripts.tile")
local BoundingBox = require("scripts.bounding-box")

local Color = require("scripts.util.color")
local Directions = defines.direction


local function clamp_direction(direction)
    if direction == Directions.northnortheast then
        return Directions.northeast
    elseif direction == Directions.eastnortheast then
        return Directions.northeast
    elseif direction == Directions.eastsoutheast then
        return Directions.southeast
    elseif direction == Directions.southsoutheast then
        return Directions.southeast
    elseif direction == Directions.southsouthwest then
        return Directions.southwest
    elseif direction == Directions.westsouthwest then
        return Directions.southwest
    elseif direction == Directions.westnorthwest then
        return Directions.northwest
    elseif direction == Directions.northnorthwest then
        return Directions.northwest
    end
    return direction
end



local debug_renders = {}

local function clear_debug_renders()
    if #debug_renders == 0 then
        rendering.clear()
    end
    for _, render in pairs(debug_renders) do
        render.destroy()
    end
    debug_renders = {}
end

local function add_debug_render(surface, position, color, player_index)
    debug_renders[#debug_renders + 1] = rendering.draw_circle({
        target = position,
        radius = 0.5,
        filled = true,
        color = color,
        surface = surface,
        players = { player_index },
        draw_on_ground = true,
    })
end

local TRAVEL_DIRECTIONS = {
    normal = 1,      -- e.g. South->North Track
    reverse = 2,     -- e.g. North->South Track
    omni = 3,        -- Bi-directional track, e.g. North->South and South->North
    impossible = -1, -- Conflicting signals
}

local SIGNAL_STATE = {
    normal = 1,     -- Signal Right Side Direction of Travel
    reverse = 2,    -- Signal Left Side Direction of Travel
    omni = 3,       -- Signals on Both Sides of the Track
    no_signals = 4, -- No Signals on the Track
}



local function get_front_signal_state(rail)
    local direction = defines.rail_direction.front

    local in_signal = rail.get_rail_segment_signal(direction, true)
    local out_signal = rail.get_rail_segment_signal(direction, false)

    local is_in_signal = in_signal ~= nil and in_signal.valid
    local is_out_signal = out_signal ~= nil and out_signal.valid

    if is_in_signal then
        add_debug_render(rail.surface, in_signal.position, Color.debian_red(0.5), 1)
    end
    if is_out_signal then
        add_debug_render(rail.surface, out_signal.position, Color.orange(0.5), 1)
    end

    if is_in_signal and is_out_signal then
        return SIGNAL_STATE.omni
    elseif is_in_signal then
        return SIGNAL_STATE.normal
    elseif is_out_signal then
        return SIGNAL_STATE.reverse
    end
    return SIGNAL_STATE.no_signals
end

local function get_back_signal_state(rail)
    local direction = defines.rail_direction.back

    local in_signal = rail.get_rail_segment_signal(direction, true)
    local out_signal = rail.get_rail_segment_signal(direction, false)

    local is_in_signal = in_signal ~= nil and in_signal.valid
    local is_out_signal = out_signal ~= nil and out_signal.valid

    if is_in_signal then
        add_debug_render(rail.surface, in_signal.position, Color.emerald(0.5), 1)
    end
    if is_out_signal then
        add_debug_render(rail.surface, out_signal.position, Color.azure(0.5), 1)
    end

    if is_in_signal and is_out_signal then
        return SIGNAL_STATE.omni
    elseif is_out_signal then
        return SIGNAL_STATE.normal
    elseif is_in_signal then
        return SIGNAL_STATE.reverse
    end
    return SIGNAL_STATE.no_signals
end


local segment_cache = {}

local function cache_key(front, back)
    return "F" .. front.unit_number .. "B" .. back.unit_number
end

local function fetch_cache(front, back)
    local key = cache_key(front, back)
    if segment_cache[key] then
        return segment_cache[key]
    end
    -- Segment is the sma
    key = cache_key(back, front)
    if segment_cache[key] then
        return segment_cache[key]
    end
    return nil
end

local function get_rail_travel_direction(entity, pindex, r)
    if r == nil then
        clear_debug_renders()
    end

    add_debug_render(entity.surface, entity.position, Color.gray(0.1), pindex)

    local front_state = get_front_signal_state(entity)
    local back_state = get_back_signal_state(entity)

    if front_state == SIGNAL_STATE.no_signals then
        -- No Signals Found
        -- There situations where signals are not detected as they are placed
        -- at the edge of a rail entity. We check the next rail segment (if it exists)
        -- to see if it has signals and if so, we return the state of that rail segment.
        local rail_direction = defines.rail_direction.front
        local rail_end, out_direction = entity.get_rail_segment_end(rail_direction)
        add_debug_render(rail_end.surface, rail_end.position, Color.cyan(0.5), pindex)
        local connections = {}
        for _, connection_direction in pairs({
            defines.rail_connection_direction.left,
            defines.rail_connection_direction.straight,
            defines.rail_connection_direction.right,
            -- None causes an error for 'entity.get_connected_rail'
        }) do
            local next_rail = rail_end.get_connected_rail { rail_direction = out_direction, rail_connection_direction = connection_direction }
            if next_rail ~= nil then
                game.print("Next rail found for " .. rail_end.unit_number .. ": " .. next_rail.unit_number ..
                    ", Direction: " .. tostring(out_direction) ..
                    ", Connection Direction: " .. tostring(connection_direction))
                connections[connection_direction + 1] = get_rail_travel_direction(next_rail, pindex, true)
                -- We can return the first found signal state as even if there are multiple
                -- rails connected the signals would all have to be at the same place.
            end
        end
        for _, state in pairs(connections) do
            if front_state == SIGNAL_STATE.no_signals then
                front_state = state
            end
            if front_state == SIGNAL_STATE.normal and state == SIGNAL_STATE.reverse
                or front_state == SIGNAL_STATE.reverse and state == SIGNAL_STATE.normal
                or state == SIGNAL_STATE.omni
            then
                -- If we have a normal and reverse signal state, we assume the rail is bi-directional
                front_state = SIGNAL_STATE.omni
                break
            end
        end

        -- game.print(entity.unit_number .. " | Front State: " .. tostring(front_state) ..
        --     ", Back State: " .. tostring(back_state))
        -- if not is_entry_blocked
    end
    -- game.print(helpers.table_to_json(signal_states))
end


local function direction_to_string(direction)
    if direction == defines.direction.north then
        return "North"
    elseif direction == defines.direction.northnortheast then
        return "North-Northeast"
    elseif direction == defines.direction.northeast then
        return "Northeast"
    elseif direction == defines.direction.eastnortheast then
        return "East-Northeast"
    elseif direction == defines.direction.east then
        return "East"
    elseif direction == defines.direction.eastsoutheast then
        return "East-Southeast"
    elseif direction == defines.direction.southeast then
        return "Southeast"
    elseif direction == defines.direction.southsoutheast then
        return "South-Southeast"
    elseif direction == defines.direction.south then
        return "South"
    elseif direction == defines.direction.southsouthwest then
        return "South-Southwest"
    elseif direction == defines.direction.southwest then
        return "Southwest"
    elseif direction == defines.direction.westsouthwest then
        return "West-Southwest"
    elseif direction == defines.direction.west then
        return "West"
    elseif direction == defines.direction.westnorthwest then
        return "West-Northwest"
    elseif direction == defines.direction.northwest then
        return "Northwest"
    elseif direction == defines.direction.northnorthwest then
        return "North-Northwest"
    else
        return "Unknown Direction"
    end
end

local TOTAL_DIRECTIONS = 16

--- @param e EventData.on_player_selected_area | EventData.on_player_reverse_selected_area
local function on_selected_area(e, func)
    local p = game.get_player(e.player_index) ---@cast p -nil
    local self = storage.gui[p.index]
    if self == nil then
        return
    end
    local tdata = self.tabs["rail"]
    if tdata == nil then
        return
    end
    local pdata = tdata.presets[tdata.preset]

    local config = RailTab.get_config(pdata)
    if config == nil then
        return
    end
    local tiles = RailTab.tile_options
    for c = 1, #config do
        local rail_config = config[c]
        for _, entity in pairs(e.entities) do
            if Rail.base_rails[rail_config.rail][entity.name] then
                local cached = tdata.cache[entity.name]
                if cached == nil then
                    cached = {}
                    tdata.cache[entity.name] = cached
                end
                local direction_of_travel = get_rail_travel_direction(entity, p)
                local type = entity.prototype.type
                for i = 1, #tiles do
                    local direction = entity.direction
                    local tile = tiles[i]
                    if rail_config[tile] then
                        local t = {}
                        local delta = tonumber(tile:sub(-1)) --- @cast delta -nil
                        local side = tile:sub(1, 1)
                        local cache_key = tonumber(direction) * 3 + delta * 17 + (side == "L" and 1 or 0) * 31 +
                            direction_of_travel * 63
                        -- Check cache
                        -- if cached[cache_key] then
                        --     t = Flib_table.deep_copy(cached[cache_key])
                        --     for j = 1, #t do
                        --         -- Adjust the position relative to the entity position
                        --         t[j] = e.surface.get_tile(Flib_position.add(entity.position, t[j]))
                        --     end
                        --     goto cache_hit
                        -- end
                        if direction_of_travel == 1 then
                            side = side == "L" and "R" or "L"
                        end
                        -- Do we need to smooth a curve?
                        if pdata.smooth_curve and Rail.curved_rails[type] then
                            -- Filter for curved rails
                            -- if direction_of_travel == 0 and (direction == Directions.northeast or
                            --         direction == Directions.south or
                            --         direction == Directions.southeast
                            --         or direction == Directions.west) then
                            --     if side == "L" then
                            --         side = "R"
                            --     elseif side == "R" then
                            --         side = "L"
                            --     end
                            -- end
                            local mask = Rail.curved_rail_mask(type, direction, delta, side)
                            for _, position in pairs(mask) do
                                t[#t + 1] = e.surface.get_tile(Flib_position.add(entity.position, position))
                            end
                            game.print("direction: " .. direction_to_string(direction) ..
                                ", Travel direction: " .. direction_of_travel ..
                                ", side: " .. side ..
                                ", delta: " .. delta)
                        else
                            t = Painter.get_entity_tiles(entity)
                            -- Get tiles or adjacent tiles
                            local ad = 17
                            if direction == Directions.north or
                                direction == Directions.south or
                                direction == Directions.east or
                                direction == Directions.west then
                                if entity.name:find("half-diagonal-rail", 1, true) ~= nil then
                                    -- For half-diagonal rails we adjust the direction to make the adjacent tiles nicer
                                    -- Adjust be half a cardinal direction
                                    direction = (direction - 2) % TOTAL_DIRECTIONS
                                end
                            end
                            -- There are 16 possible directions
                            if side == "L" then
                                ad = (clamp_direction(direction) + Directions.west) % TOTAL_DIRECTIONS
                            elseif side == "R" then
                                ad = (clamp_direction(direction) + Directions.east) % TOTAL_DIRECTIONS
                            end
                            game.print("direction: " .. direction_to_string(direction) ..
                                ", Travel direction: " .. direction_of_travel ..
                                ", side: " .. side ..
                                ", ad: " .. direction_to_string(ad) ..
                                ", delta: " .. delta)
                            if delta > 0 then
                                t = TileLib.get_adjacent_tiles(t, ad, delta)
                            end
                        end
                        -- Cache the result
                        -- We need to convert Tile to it's position and
                        -- adjust relative to the entity position
                        cached[cache_key] = Flib_table.deep_copy(t)
                        for j = 1, #cached[cache_key] do
                            cached[cache_key][j] = Flib_position.sub(cached[cache_key][j].position, entity.position)
                        end
                        ::cache_hit::
                        func(t, e.surface, rail_config[tile], p)
                    end
                end
            end
        end
    end
end

--- @param e EventData.on_player_alt_selected_area
local function on_player_alt_selected_area(e)
    if e.item ~= "tp-tool-rail" then
        return
    end
    on_selected_area(e, Painter.remove_tiles)
end

--- @class ToolEntity
local tool = {}

--- @param e EventData.on_player_selected_area
function tool.on_player_selected_area(e)
    if e.item ~= "tp-tool-rail" then
        return
    end
    on_selected_area(e, Painter.paint_tiles)
end

tool.events = {
    [defines.events.on_player_selected_area] = tool.on_player_selected_area,
    [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
}

return tool
