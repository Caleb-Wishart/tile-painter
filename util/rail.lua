local flib_table = require("__flib__.table")

local rail = {}

rail.legacy_rail_prototypes = {
    "legacy-curved-rail",
    "legacy-straight-rail",
}

rail.legacy_curved_rail_prototypes = {
    "legacy-curved-rail",
}

rail.rail_prototypes = {
    "curved-rail-a",
    "curved-rail-b",
    "half-diagonal-rail",
    "straight-rail",
}

rail.curved_rail_prototypes = {
    "curved-rail-a",
    "curved-rail-b",
}

rail.rails = {}

rail.curved_rails = {}

for _, r in pairs(rail.legacy_rail_prototypes) do
    rail.rails[r] = true
end

for _, r in pairs(rail.legacy_curved_rail_prototypes) do
    rail.curved_rails[r] = true
end

for _, r in pairs(rail.rail_prototypes) do
    rail.rails[r] = true
end

for _, r in pairs(rail.curved_rail_prototypes) do
    rail.curved_rails[r] = true
end

-- Standard Curved Rails that the mod will handle
-- These should be all base game curved rails (including legacy)
rail.base_curved_rails = flib_table.array_merge({ rail.legacy_curved_rail_prototypes, rail.curved_rail_prototypes })

-- The straight rail from all mods
-- To be used as the default icon when grouping by type
rail.base_rails = {
    ['straight-rail'] = flib_table.deep_copy(rail.rails),
}

rail.elevatedRails = {}

rail.filter = {}

local function add_modded_rail(prefix, postfix)
    prefix = prefix or ''
    postfix = postfix or ''
    local base_name = prefix .. 'straight-rail' .. postfix
    rail.base_rails[base_name] = {}

    for _, r in pairs(rail.rail_prototypes) do
        rail.rails[prefix .. r .. postfix] = true
        rail.base_rails[base_name][prefix .. r .. postfix] = true
    end

    for _, r in pairs(rail.curved_rail_prototypes) do
        rail.curved_rails[prefix .. r .. postfix] = true
    end
end

-- Search Mods list if in Prototype Phase or Script if in Runtime Phase
local search = mods and mods or script.active_mods

if search['elevated-rails'] then
    add_modded_rail('elevated-')

    table.insert(rail.filter, 'rail-ramp')
end

-- Minimal Rails Mod
if search['minimalist-rails'] then
    add_modded_rail(nil, '-minimal')
end

-- Naked Rails Mod
if search['naked-rails-f2'] then
    add_modded_rail('naked-')
    add_modded_rail('sleepy-')
end

-- SE future proofing
if search['space-exploration'] then
    add_modded_rail('se-space-')
end


for k, _ in pairs(rail.rails) do
    table.insert(rail.filter, k)
end

return rail
