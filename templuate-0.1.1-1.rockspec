package = "templuate"
version = "0.1.1-1"
source = {
   url = "https://github.com/RobPlatt/templuate"
}
description = {
   summary = "A lightweight templating system for Lua",
   detailed = [[
      templuate is a templating system for Lua, written in pure Lua.
   ]],
   homepage = "https://github.com/RobPlatt/templuate",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    templuate = "src/templuate.lua"
  }
}