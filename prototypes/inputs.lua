local util = require("util")
local mod_name = util.defines.mod_name

data:extend {
    {
        type = "custom-input",
        name = mod_name .. "-fill-shape-left-click",
        key_sequence = "mouse-button-1"
    },
    {
        type = "custom-input",
        name = mod_name .. "-fill-shape-right-click",
        key_sequence = "mouse-button-2"
    },
}
