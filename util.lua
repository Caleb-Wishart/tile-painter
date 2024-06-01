--- @class tile_painter_util
local tile_painter_util = {}

tile_painter_util.defines = {
    mod_name = "tile-painter",
    mod_prefix = "tile_painter",
    item_name = "tile-painter"
}
--- Print a message to the console.
--  Pass an object to print it as a JSON string.
--- @param msg string
--- @param obj table
--- @noreturn
function tile_painter_util.print(msg, obj)
    if settings.global[tile_painter_util.defines.mod_name .. "-debug-mode"].value == false then
        return
    end
    if obj == nil then
        game.print(msg)
    else
        game.print(msg .. game.table_to_json(obj or {}))
    end
end

return tile_painter_util
