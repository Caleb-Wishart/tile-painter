local by_version = {
    ["1.0.0"] = function ()
        for _, player in pairs(game.players) do
            for _, child in pairs(player.gui.screen.children) do
                if child.get_mod() == "tile-painter" then
                    child.destroy()
                end
            end
        end
        global = { gui = {} }
    end,

    ["2.0.0"] = function ()
        for _, player in pairs(game.players) do
            for _, child in pairs(player.gui.screen.children) do
                if child.get_mod() == "tile-painter" then
                    child.destroy()
                end
            end
        end
        storage = { gui = {} }
    end
}
local migrations = {}

---@param e ConfigurationChangedData
function migrations.on_configuration_changed(e)
    -- By Version migrations
    local _mod_changes = e.mod_changes and e.mod_changes[script.mod_name]
    if not _mod_changes then
        return
    end
    local old_version = _mod_changes.old_version
    if not old_version then
        return
    end

    for version, migration in pairs(by_version) do
        if helpers.compare_versions(old_version, version) <= 0 then
            migration()
        end
    end

    if not storage then
        return
    end
    -- if a mod with an entity or tile was removed, ensure it is removed from gui selections
    for _, player in pairs(game.players) do
        local self = storage.gui[player.index] --[[@as TPGui]]
        if self == nil then
            goto continue
        end
        local tdata = self.tabs["entity"]
        if tdata == nil then
            goto continue
        end
        for _, preset in pairs(tdata.presets) do
            local config = preset.config
            if config == nil then
                goto continue
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
        ::continue::
    end
end

return migrations
