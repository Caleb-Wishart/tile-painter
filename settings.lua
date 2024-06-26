data:extend({
    {
        type = "bool-setting",
        name = "tp-debug-mode",
        setting_type = "runtime-global",
        default_value = false,
        order = "aa"
    },
    {
        type = "bool-setting",
        name = "tp-smooth-curved-rail",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "ab"
    },
    {
        type = "int-setting",
        name = "tp-fill-max-distance",
        setting_type = "runtime-global",
        default_value = 50,
        minimum_value = 10,
        maximum_value = 500,
        order = "ba"
    },
})
