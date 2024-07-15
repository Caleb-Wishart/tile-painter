data:extend({
    {
        type = "bool-setting",
        name = "tp-debug-mode",
        setting_type = "runtime-global",
        default_value = false,
        order = "aa"
    },
    {
        type = "string-setting",
        name = "tp-default-gui-location",
        setting_type = "runtime-per-user",
        default_value = "top-left",
        allowed_values = { "top-left", "center" },
        order = "ab"
    },
    {
        type = "bool-setting",
        name = "tp-entity-smooth-curved-rail",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "ba"
    },
    {
        type = "bool-setting",
        name = "tp-shape-invert-y-axis",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "bb"
    },
    -- {
    --     type = "int-setting",
    --     name = "tp-fill-max-distance",
    --     setting_type = "runtime-global",
    --     default_value = 50,
    --     minimum_value = 10,
    --     maximum_value = 500,
    --     order = "bc"
    -- },
})
