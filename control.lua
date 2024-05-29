local painter = require("__tile-painter__/scripts/painter")
local gui = require("__tile-painter__/scripts/gui")
local gui_handlers = require("__tile-painter__/scripts/guihandlers")
local util = require("__tile-painter__/util")

local mod_name = util.defines.mod_name
local mod_prefix = util.defines.mod_prefix
local item_name = util.defines.item_name


script.on_event(defines.events.on_mod_item_opened, function(event)
  if event.item.name == item_name then
    gui.toggle_interface(event.player_index)
  end
end)

script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item ~= item_name then return end
  local p = game.get_player(event.player_index) ---@cast p -nil
  local player_global = global.players[p.index]
  if player_global == nil then return end

  local force = p.force ---@cast force LuaForce

  local config = player_global.config
  if config == nil then return end

  -- Iterate last to first
  -- The first settings will have highest priority with tiles
  local tiles = { "tile_0", "tile_1", "tile_2" }
  for i = 0, 2 do -- 0, 1, 2
    local tile = tiles[i + 1]
    for j = #config, 1, -1 do
      local setting = config[j]

      local entity = nil
      if setting.entity == nil then
        entity = event.entities
      else -- if entity is set, get all entities of that type in the area
        entity = {}
        local count = 1
        for _, e in pairs(event.entities) do
          if e.name == setting.entity then
            entity[count] = e
            count = count + 1
          end
        end
      end
      if setting[tile] then
        for _, e in pairs(entity) do
          painter.paint_tiles_entity(force, e, setting[tile], i)
        end
      end
    end
  end

  -- if settings.get_player_settings(event.player_index)[mod_name .. "-include-second-layer"].value then
  -- end
end)


script.on_event(defines.events.on_player_dropped_item, function(event)
  if event.entity and event.entity.name == item_name then
    event.entity.destroy()
  end
end)


local function initialize_global(player)
  global.players[player.index] = {
    inventory_selected = nil,
    elements = {},
    config = {},
  }
end

script.on_init(function()
  global.players = {}

  for _, player in pairs(game.players) do
    initialize_global(player)
  end
end)

script.on_configuration_changed(function(config_changed_data)
  if config_changed_data.mod_changes["tile-painter"] then
    for _, player in pairs(game.players) do
      local player_global = global.players[player.index]
      if player_global.elements.main_frame ~= nil then gui.toggle_interface(player.index) end
    end
  end
end)


script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  initialize_global(player)
end)

script.on_event(defines.events.on_player_removed, function(event)
  global.players[event.player_index] = nil
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  local player = game.get_player(event.player_index)
  if player == nil then return end

  local player_global = global.players[player.index]
  if player_global == nil then return end

  player_global.inventory_selected = player.cursor_stack.valid_for_read and player.cursor_stack.name or nil

  if player_global.elements.main_frame ~= nil then
    gui.build_character_inventory(player, player_global)
  end
end)


local gui_identifier_map = {
  [defines.events.on_gui_click] = "on_gui_click",
  [defines.events.on_gui_elem_changed] = "on_gui_elem_changed",
}

-- @param event EventData
local function handle_gui_event(event)
  if event.element.tags == nil then return end
  if event.element.tags.action == nil then return end
  local event_listeners = gui_handlers[gui_identifier_map[event.name]]

  if event_listeners == nil then return end

  local method = event_listeners[event.element.tags.action]
  if method == nil then return end

  method(event)
end

script.on_event(defines.events.on_gui_click, handle_gui_event)
script.on_event(defines.events.on_gui_elem_changed, handle_gui_event)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.name == (mod_prefix .. "_main_frame") then
    gui.toggle_interface(event.player_index)
  end
end)
