local flib_migration = require("__flib__.migration")

local by_version = {
    ["1.0.0"] = function()
        for _, player in pairs(game.players) do
            for _, child in pairs(player.gui.screen.children) do
                if child.get_mod() == "tile-painter" then
                    child.destroy()
                end
            end
        end
        global = { gui = {} }
    end,

    ["2.0.0"] = function()
        for _, player in pairs(game.players) do
            for _, child in pairs(player.gui.screen.children) do
                if child.get_mod() == "tile-painter" then
                    child.destroy()
                end
            end
        end
        storage = { gui = {} }
    end,
}

--- @param e ConfigurationChangedData
local function on_configuration_changed(e)
    flib_migration.on_config_changed(e, by_version)
    for _, player in pairs(game.players) do
        local self = storage.gui[player.index]
        if self == nil then
            return
        end
        local tdata = self.tabs["entity"]
        if tdata == nil then
            return
        end
        for _, preset in pairs(tdata.presets) do
            local config = preset.config
            if config == nil then
                return
            end
            for _, c in pairs(config) do
                if prototypes.entity[c["entity"]] == nil then
                    c["entity"] = nil
                end
                if prototypes.tile[c["tile_0"]] == nil then
                    c["tile_0"] = nil
                end
                if prototypes.tile[c["tile_1"]] == nil then
                    c["tile_1"] = nil
                end
                if prototypes.tile[c["tile_2"]] == nil then
                    c["tile_2"] = nil
                end
            end
        end
    end
end

local migrations = {}

migrations.on_configuration_changed = on_configuration_changed

return migrations
