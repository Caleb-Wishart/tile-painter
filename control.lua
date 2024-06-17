local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("__flib__.gui-lite"),

  require("scripts.gui"),
  require("scripts.tool-entity"),
  require("scripts.tool-shape"),
})
