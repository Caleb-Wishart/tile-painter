local Flib_table = require("__flib__.table")
local Directions = defines.direction

local Rail = require("util.rail")

local TP_rail_mask = {}

-- Copy util rail objects to rail_mask to reduce dependencies
for k, v in pairs(Rail) do
    TP_rail_mask[k] = v
end

-- Rail masks for smoothed curved rails
-- must be 2n and the rail position should be in the middle of the mask
TP_rail_mask.MASK_DIM = 14
-- Set for Rail Orientation: 0.125
TP_rail_mask.RIGHT_OFFSET = 10


local curve_a = {
    { 999, 999, 004, 004, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 004, 003, 003, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 004, 003, 002, 002, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 004, 003, 002, 001, 000, 000, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 004, 003, 002, 001, 000, 000, 000, 000, 011, 012, 013, 014, },
    { 999, 999, 004, 003, 002, 001, 000, 000, 000, 011, 011, 012, 013, 014, },
    { 999, 999, 004, 003, 002, 001, 000, 000, 000, 011, 012, 012, 013, 014, },
    { 999, 999, 004, 003, 002, 001, 000, 000, 011, 011, 012, 013, 013, 014, },
    { 999, 999, 004, 003, 002, 001, 000, 000, 011, 012, 012, 013, 014, 014, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
}

local curve_b = {
    { 999, 999, 999, 999, 004, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 004, 004, 003, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 004, 004, 003, 003, 002, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 004, 004, 003, 003, 002, 002, 001, 999, 999, 999, 999, 999, 999, },
    { 999, 004, 003, 003, 002, 002, 001, 001, 000, 000, 999, 999, 999, 999, },
    { 999, 004, 003, 002, 002, 001, 001, 000, 000, 000, 999, 999, 999, 999, },
    { 999, 004, 003, 002, 001, 001, 000, 000, 000, 011, 011, 999, 999, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 000, 000, 011, 012, 012, 999, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 000, 011, 011, 012, 013, 013, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 011, 011, 012, 012, 013, 014, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 012, 012, 013, 013, 014, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 013, 013, 014, 014, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 014, 014, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
}

local legacy_curve = {
    { 999, 999, 999, 004, 004, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 004, 004, 003, 003, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 004, 004, 003, 003, 002, 002, 001, 999, 999, 999, 999, 999, 999, },
    { 999, 004, 003, 003, 002, 002, 001, 001, 000, 999, 999, 999, 999, 999, },
    { 999, 004, 003, 002, 002, 001, 001, 000, 000, 000, 999, 999, 999, 999, },
    { 999, 004, 003, 002, 001, 001, 000, 000, 000, 011, 011, 999, 999, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 000, 011, 011, 012, 012, 999, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 011, 011, 012, 012, 013, 013, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 011, 012, 012, 013, 013, 014, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 011, 012, 013, 013, 014, 014, 999, },
    { 999, 004, 003, 002, 001, 000, 000, 011, 012, 013, 014, 014, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
    { 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, },
}

local function flip_LR(input)
    local out = Flib_table.deep_copy(input)
    local offset = TP_rail_mask.MASK_DIM + 1
    for r = 1, TP_rail_mask.MASK_DIM do
        for c = 1, TP_rail_mask.MASK_DIM do
            out[r][c] = input[r][offset - c]
        end
    end
    return out
end

local function flip_diagonal(input)
    local out = Flib_table.deep_copy(input)
    for r = 1, TP_rail_mask.MASK_DIM do
        for c = 1, TP_rail_mask.MASK_DIM do
            out[r][c] = input[c][r]
        end
    end
    return out
end


local masks = {
    legacy_curve, -- ["legacy-curved-rail"]
    curve_a,      -- ["curved-rail-a"]
    curve_b,      -- ["curved-rail-b"]
}

local curve_masks = {}
-- All these arrays should be the same length
for i = 1, #masks do
    local mask = masks[i]
    local k = Rail.base_curved_rails[i]

    -- Create a mask for each direction based on the original mask
    local m = {}
    m[Directions.northeast] = mask
    m[Directions.west] = flip_diagonal(m[Directions.northeast])
    m[Directions.southeast] = flip_LR(m[Directions.west])
    m[Directions.south] = flip_diagonal(m[Directions.southeast])
    m[Directions.southwest] = flip_LR(m[Directions.south])
    m[Directions.east] = flip_diagonal(m[Directions.southwest])
    m[Directions.northwest] = flip_LR(m[Directions.east])
    m[Directions.north] = flip_diagonal(m[Directions.northwest])
    curve_masks[k] = m
end


--- Get the mask for a curved rail given the direction and the delta (offset)
--- @param name string The entity prototype type of the rail (curved-rail-a or curved-rail-b)
--- @param direction defines.direction The direction of the rail
--- @param delta number? The offset from the rail position (default 0)
--- @param side "L"|"R"? The side of the rail to get the mask for
--- @return table A list of {x, y} pairs
function TP_rail_mask.curved_rail_mask(name, direction, delta, side)
    local out = {}
    if direction == nil then
        direction = Directions.northeast
    end
    if delta == nil then
        delta = 0
    end
    if side == "L" then
        delta = delta + 0
    elseif side == "R" then
        delta = delta + TP_rail_mask.RIGHT_OFFSET
    end
    -- Handle prefix / postfix from modded rail prototypes
    for _, v in pairs(Rail.rail_prototypes) do
        if name:find(v, 1, true) ~= nil then
            name = v
            break
        end
    end
    local mask = Flib_table.deep_copy(curve_masks[name][direction])
    local offset = math.floor(TP_rail_mask.MASK_DIM / 2) + 1
    -- Offset shifts the map to center on the entity position
    for row = 1, TP_rail_mask.MASK_DIM do
        for col = 1, TP_rail_mask.MASK_DIM do
            local d = mask[row][col]
            if side == nil then
                d = d % 10
            end
            if d == delta then
                out[#out + 1] = { ["x"] = col - offset, ["y"] = row - offset }
            end
        end
    end
    return out
end

return TP_rail_mask
