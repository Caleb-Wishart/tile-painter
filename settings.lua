local util = require("__tile-painter__/util")
local mod_prefix = util.defines.mod_prefix

data:extend({
    {
        type = "bool-setting",
        name = mod_prefix .. "-debug-mode",
        setting_type = "runtime-global",
        default_value = true, -- TODO Change to false on release
        order = "aa"
    },
    {
        type = "bool-setting",
        name = mod_prefix .. "-include-second-layer",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "ab"
    }
})
