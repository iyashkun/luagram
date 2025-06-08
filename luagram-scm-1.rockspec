package = "luagram"
version = "scm-1"
source = {
   url = "git+https://github.com/iYashKun/luagram.git"
}
description = {
   summary = "Telegram Bot API Library for Lua",
   detailed = [[
      Luagram is a comprehensive Telegram Bot API wrapper for Lua, 
      inspired by Pyrogram. It provides all the functionality needed 
      to create powerful Telegram bots with a clean and intuitive API.
   ]],
   homepage = "https://github.com/iYashKun/luagram",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["luagram"] = "luagram/init.lua",
      ["luagram.client"] = "luagram/client.lua",
      ["luagram.api"] = "luagram/api.lua",
      ["luagram.types"] = "luagram/types.lua",
      ["luagram.session"] = "luagram/session.lua",
      ["luagram.handlers"] = "luagram/handlers.lua",
      ["luagram.filters"] = "luagram/filters.lua",
      ["luagram.utils"] = "luagram/utils.lua",
      ["luagram.errors"] = "luagram/errors.lua",
      ["luagram.file_manager"] = "luagram/file_manager.lua",
      ["luagram.http_client"] = "luagram/http_client.lua",
      ["luagram.json"] = "luagram/json.lua",
      ["luagram.simple_socket"] = "luagram/simple_socket.lua"
   }
}
