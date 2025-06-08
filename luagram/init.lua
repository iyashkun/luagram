-- Luagram - Telegram Bot API Library for Lua
-- Author: iYashKun
-- Version: 1.0.0
-- Description: A comprehensive Telegram Bot API wrapper for Lua, inspired by Pyrogram

local luagram = {}

-- Import core modules
local Client = require("luagram.client")
local types = require("luagram.types")
local filters = require("luagram.filters")
local handlers = require("luagram.handlers")
local errors = require("luagram.errors")

-- Export main classes and functions
luagram.Client = Client
luagram.types = types
luagram.filters = filters
luagram.handlers = handlers
luagram.errors = errors

-- Version information
luagram.version = "1.0.0"
luagram.version_info = {1, 0, 0}

-- Export commonly used types for convenience
luagram.Message = types.Message
luagram.User = types.User
luagram.Chat = types.Chat
luagram.Update = types.Update
luagram.InlineKeyboardMarkup = types.InlineKeyboardMarkup
luagram.ReplyKeyboardMarkup = types.ReplyKeyboardMarkup
luagram.CallbackQuery = types.CallbackQuery
luagram.InlineQuery = types.InlineQuery

-- Export filters for convenience
luagram.Filter = filters.Filter
luagram.create_filter = filters.create_filter

-- Export handler decorators
luagram.on_message = handlers.on_message
luagram.on_callback_query = handlers.on_callback_query
luagram.on_inline_query = handlers.on_inline_query
luagram.on_edited_message = handlers.on_edited_message

-- Convenience function to create a new client
function luagram.new_client(bot_token, options)
    return Client.new(bot_token, options)
end

-- Module information
luagram.about = function()
    return string.format("Luagram v%s - Telegram Bot API Library for Lua", luagram.version)
end

return luagram
