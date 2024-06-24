local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.gui-lite"),

  require("scripts.gui-painter"),
  require("scripts.tool-painter"),

  require("scripts.gui-shape"),
  require("scripts.tool-shape"),
})
