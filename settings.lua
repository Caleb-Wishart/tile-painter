local util = require("__tile-painter__/util")
local mod_name = util.defines.mod_name

data:extend({
    {
        type = "bool-setting",
        name = mod_name .. "-debug-mode",
        setting_type = "runtime-global",
        default_value = false,
        order = "aa"
    },
    {
        type = "bool-setting",
        name = mod_name .. "-smooth-curved-rail",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "ab"
    }
})
