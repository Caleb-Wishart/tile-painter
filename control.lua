local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.gui-lite"),

  require("scripts.gui-entity"),
  require("scripts.tool-entity"),

  require("scripts.gui-shape"),
  require("scripts.tool-shape"),

  require("scripts.shortcut"),
})
