local painter = require("scripts/painter")

local util = require("util")

--- @param e EventData.on_player_selected_area
local function on_player_selected_area(e)
    if e.item ~= util.defines.item_name then return end
    local p = game.get_player(e.player_index) ---@cast p -nil
    local player_global = global.players[p.index]
    if player_global == nil then return end

    local config = player_global.config
    if config == nil then return end

    -- Iterate last to first
    -- The first settings will have highest priority with tiles
    local tiles = { "tile_0", "tile_1", "tile_2" }
    for i = 0, 2 do -- 0, 1, 2
        local tile = tiles[i + 1]
        for j = #config, 1, -1 do
            local setting = config[j]

            local entities = nil
            if setting.entity == nil then
                entities = e.entities
            else -- if entity is set, get all entities of that type in the area
                entities = {}
                local count = 1
                for _, entity in pairs(e.entities) do
                    if entity.name == setting.entity then
                        entities[count] = entity
                        count = count + 1
                    end
                end
            end
            if setting[tile] then
                for _, entity in pairs(entities) do
                    painter.paint_entity(p, entity, setting[tile], i)
                end
            end
        end
    end
end

local function on_player_dropped_item(e)
    if e.entity and e.entity.name == util.defines.item_name then
        e.entity.destroy()
    end
end

--- @class Tool
local tool = {}

tool.events = {
    [defines.events.on_player_selected_area] = on_player_selected_area,
    [defines.events.on_player_dropped_item] = on_player_dropped_item,
}

return tool
