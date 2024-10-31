local painter = require("scripts.painter")

--- @param e EventData.on_player_selected_area | EventData.on_player_reverse_selected_area
local function on_selected_area(e, func)
    if e.item ~= "tp-tool-entity" then return end
    local p = game.get_player(e.player_index) ---@cast p -nil
    local self = storage.gui[p.index]
    if self == nil then return end
    local tdata = self.tabs["entity"]
    if tdata == nil then return end
    local pdata = tdata.presets[tdata.preset]

    local config = pdata.config
    if config == nil then return end

    -- Iterate last to first
    -- The first settings will have highest priority with tiles
    local tiles = { "tile_0", "tile_1", "tile_2" }
    local blacklist = {}
    for _, setting in pairs(config) do
        if setting.entity then
            blacklist[setting.entity] = true
        end
    end
    for i = 2, 0, -1 do -- 2, 1, 0
        local tile = tiles[i + 1]
        for j = #config, 1, -1 do
            local setting = config[j]
            local isAny = setting.entity == "signal-anything"
            if setting[tile] then
                local entities = nil
                if setting.entity == nil then
                    entities = {}
                else
                    entities = {}
                    for _, entity in pairs(e.entities) do
                        if (pdata.whitelist and entity.name == setting.entity) or
                            (isAny and not blacklist[entity.name]) then
                            entities[#entities + 1] = entity
                        end
                    end
                end
                for _, entity in pairs(entities) do
                    func(p, entity, setting[tile], i)
                end
            end
            -- Short Circuit
            if isAny then
                break
            end
        end
    end
end

--- @param e EventData.on_player_selected_area
local function on_player_selected_area(e)
    on_selected_area(e, painter.paint_entity)
end


--- @param e EventData.on_player_alt_selected_area
local function on_player_alt_selected_area(e)
    on_selected_area(e, painter.remove_paint_entity)
end

--- @class ToolEntity
local tool = {}

tool.events = {
    [defines.events.on_player_selected_area] = on_player_selected_area,
    [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
}

return tool
