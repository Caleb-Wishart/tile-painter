local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.gui-lite"),

  require("scripts.gui.base"),
  require("scripts.gui.templates"),
  require("scripts.gui.tab-entity"),
  require("scripts.gui.tab-shape"),

  require("scripts.tool-entity"),
  require("scripts.tool-shape"),

  require("scripts.shortcut"),
})
