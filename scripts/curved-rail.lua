-- Contents of this file have been modified from the original version available at:
--  ElderAxe - Landfill Everything
-- https://github.com/ElderAxe/LandfillEverything/blob/main/LICENSE
-- MIT License
-- Copyright (c) 2019 Hadramal
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
-- https://github.com/ElderAxe/LandfillEverything/blob/main/stdlib/curvedRail.lua
local table = require("__flib__.table")
local direction = defines.direction

local MASK_DIM = 12

local default_curve = {
    { 9, 9, 9, 9, 9, 2, 2, 2, 2, 2, 9, 9 },
    { 9, 9, 9, 9, 2, 2, 1, 1, 1, 2, 2, 9 },
    { 9, 9, 9, 2, 2, 1, 1, 0, 1, 1, 2, 9 },
    { 9, 9, 2, 2, 1, 1, 0, 0, 0, 1, 2, 9 },
    { 9, 9, 2, 1, 1, 0, 0, 0, 1, 1, 2, 9 },
    { 9, 9, 2, 1, 0, 0, 0, 1, 1, 2, 2, 9 },
    { 9, 9, 2, 1, 0, 0, 1, 1, 2, 2, 9, 9 },
    { 9, 9, 2, 1, 0, 0, 1, 2, 2, 9, 9, 9 },
    { 9, 9, 2, 1, 0, 0, 1, 2, 9, 9, 9, 9 },
    { 9, 9, 2, 1, 0, 0, 1, 2, 9, 9, 9, 9 },
    { 9, 9, 2, 1, 1, 1, 1, 2, 9, 9, 9, 9 },
    { 9, 9, 2, 2, 2, 2, 2, 2, 9, 9, 9, 9 },
}

local function flipLR(input)
    local out = table.deep_copy(input)
    local offset = MASK_DIM + 1
    for r = 1, MASK_DIM do
        for c = 1, MASK_DIM do
            out[r][c] = input[r][offset - c]
        end
    end
    return out
end


local function flipDiag(input)
    local out = table.deep_copy(input)
    for r = 1, MASK_DIM do
        for c = 1, MASK_DIM do
            out[r][c] = input[c][r]
        end
    end
    return out
end

local curveMap = {}
curveMap[direction.northeast] = default_curve
curveMap[direction.west] = flipDiag(curveMap[direction.northeast])
curveMap[direction.southeast] = flipLR(curveMap[direction.west])
curveMap[direction.south] = flipDiag(curveMap[direction.southeast])
curveMap[direction.southwest] = flipLR(curveMap[direction.south])
curveMap[direction.east] = flipDiag(curveMap[direction.southwest])
curveMap[direction.northwest] = flipLR(curveMap[direction.east])
curveMap[direction.north] = flipDiag(curveMap[direction.northwest])

--- Get the mask for a curved rail given the direction and the delta (offset)
--- @param dir defines.direction The direction of the rail
--- @param delta number The offset of the rail
--- @return table A list of {x, y} pairs
local function curved_rail_mask(dir, delta)
    local out = {}
    if dir == nil then
        dir = direction.north
    end
    local map = table.deep_copy(curveMap[dir])
    local offset = math.floor(MASK_DIM / 2) + 1
    for r = 1, MASK_DIM do
        for c = 1, MASK_DIM do
            if map[r][c] == delta then
                out[#out + 1] = { ["x"] = c - offset, ["y"] = r - offset }
            end
        end
    end
    return out
end

return curved_rail_mask
