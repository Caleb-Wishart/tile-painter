--- @class tp_color
local tp_color = {}

-- Definitions from LaTeX Color
-- https://latexcolor.com/

-- #FF7F50
--- @param alpha number?
function tp_color.coral(alpha)
    return { r = 1, g = 0.5, b = 0.31, a = alpha or 1 }
end

-- #00FFFF
--- @param alpha number?
function tp_color.cyan(alpha)
    return { r = 0, g = 1, b = 1, a = alpha or 1 }
end

-- #7FFFD0
--- @param alpha number?
function tp_color.aquamarine(alpha)
    return { r = 0.5, g = 1, b = 0.83, a = alpha or 1 }
end

-- #007FFF
--- @param alpha number?
function tp_color.azure(alpha)
    return { r = 0, g = 0.5, b = 1, a = alpha or 1 }
end

-- #9932CC
--- @param alpha number?
function tp_color.dark_orchid(alpha)
    return { r = 0.6, g = 0.2, b = 0.8, a = alpha or 1 }
end

-- #D70A53
--- @param alpha number?
function tp_color.debian_red(alpha)
    return { r = 0.84, g = 0.04, b = 0.33, a = alpha or 1 }
end

-- #50C878
--- @param alpha number?
function tp_color.emerald(alpha)
    return { r = 0.31, g = 0.78, b = 0.47, a = alpha or 1 }
end

-- #7F7F7F
--- @param alpha number?
function tp_color.gray(alpha)
    return { r = 0.5, g = 0.5, b = 0.5, a = alpha or 1 }
end

-- #FF4F00
--- @param alpha number?
function tp_color.orange(alpha)
    return { r = 1, g = 0.31, b = 0, a = alpha or 1 }
end

-- #EE82EE
--- @param alpha number?
function tp_color.lavender_magenta(alpha)
    return { r = 0.93, g = 0.51, b = 0.93, a = alpha or 1 }
end

-- #CB410B
--- @param alpha number?
function tp_color.sinopia(alpha)
    return { r = 0.8, g = 0.25, b = 0.04, a = alpha or 1 }
end

return tp_color
