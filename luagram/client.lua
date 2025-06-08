-- Luagram Client - Main bot client implementation
local socket = require("luagram.simple_socket")

-- Try to load cjson, fallback to our JSON implementation
local json
local success = pcall(function() json = require("cjson") end)
if not success then
    json = require("luagram.json")
end

local api = require("luagram.api")
local types = require("luagram.types")
local session = require("luagram.session")
local handlers = require("luagram.handlers")
local file_manager = require("luagram.file_manager")
local errors = require("luagram.errors")
local utils = require("luagram.utils")

local Client = {}
Client.__index = Client

-- Constructor
function Client.new(bot_token, options)
    options = options or {}
    
    local self = setmetatable({}, Client)
    
    -- Core properties
    self.bot_token = bot_token or error("Bot token is required")
    self.api_url = options.api_url or "https://api.telegram.org"
    self.session_name = options.session_name or "luagram_session"
    self.workers = options.workers or 4
    self.workdir = options.workdir or "./"
    self.plugins = options.plugins or {}
    self.parse_mode = options.parse_mode or "Markdown"
    
    -- Initialize components
    self.api = api.new(self.api_url, self.bot_token)
    self.session = session.new(self.session_name)
    self.handlers = handlers.new()
    self.file_manager = file_manager.new(self.api)
    
    -- Bot info
    self.me = nil
    self.is_running = false
    self.last_update_id = 0
    
    -- Event handlers storage
    self.message_handlers = {}
    self.callback_query_handlers = {}
    self.inline_query_handlers = {}
    self.edited_message_handlers = {}
    
    return self
end

-- Start the bot
function Client:start()
    print("Starting Luagram bot...")
    
    -- Get bot information
    local success, result = self.api:get_me()
    if not success then
        error("Failed to get bot info: " .. (result.description or "Unknown error"))
    end
    
    self.me = types.User.from_dict(result)
    print(string.format("Bot started successfully: @%s (%s)", 
        self.me.username or "unknown", self.me.first_name))
    
    -- Load session
    self.session:load()
    self.last_update_id = self.session:get("last_update_id", 0)
    
    -- Load plugins
    self:load_plugins()
    
    self.is_running = true
    
    -- Start polling
    self:run_polling()
end

-- Stop the bot
function Client:stop()
    print("Stopping bot...")
    self.is_running = false
    
    -- Save session
    self.session:set("last_update_id", self.last_update_id)
    self.session:save()
    
    print("Bot stopped successfully")
end

-- Main polling loop
function Client:run_polling()
    local timeout = 30
    local allowed_updates = {"message", "edited_message", "callback_query", "inline_query"}
    
    while self.is_running do
        local success, updates = self.api:get_updates(self.last_update_id + 1, 100, timeout, allowed_updates)
        
        if success and updates and #updates > 0 then
            for _, update_data in ipairs(updates) do
                local update = types.Update.from_dict(update_data)
                self:process_update(update)
                self.last_update_id = math.max(self.last_update_id, update.update_id)
            end
        elseif not success then
            print("Error getting updates: " .. (updates and updates.description or "Unknown error"))
            socket.sleep(5)  -- Wait before retrying
        end
        
        socket.sleep(0.1)  -- Small delay to prevent excessive CPU usage
    end
end

-- Process a single update
function Client:process_update(update)
    -- Handle different types of updates
    if update.message then
        self:handle_message(update.message)
    elseif update.edited_message then
        self:handle_edited_message(update.edited_message)
    elseif update.callback_query then
        self:handle_callback_query(update.callback_query)
    elseif update.inline_query then
        self:handle_inline_query(update.inline_query)
    end
end

-- Handle message updates
function Client:handle_message(message)
    for _, handler in ipairs(self.message_handlers) do
        if handler.filter == nil or handler.filter(message) then
            local success, err = pcall(handler.func, self, message)
            if not success then
                print("Error in message handler: " .. tostring(err))
            end
        end
    end
end

-- Handle edited message updates
function Client:handle_edited_message(message)
    for _, handler in ipairs(self.edited_message_handlers) do
        if handler.filter == nil or handler.filter(message) then
            local success, err = pcall(handler.func, self, message)
            if not success then
                print("Error in edited message handler: " .. tostring(err))
            end
        end
    end
end

-- Handle callback query updates
function Client:handle_callback_query(callback_query)
    for _, handler in ipairs(self.callback_query_handlers) do
        if handler.filter == nil or handler.filter(callback_query) then
            local success, err = pcall(handler.func, self, callback_query)
            if not success then
                print("Error in callback query handler: " .. tostring(err))
            end
        end
    end
end

-- Handle inline query updates
function Client:handle_inline_query(inline_query)
    for _, handler in ipairs(self.inline_query_handlers) do
        if handler.filter == nil or handler.filter(inline_query) then
            local success, err = pcall(handler.func, self, inline_query)
            if not success then
                print("Error in inline query handler: " .. tostring(err))
            end
        end
    end
end

-- Register message handler
function Client:on_message(filter, func)
    if type(filter) == "function" and func == nil then
        func = filter
        filter = nil
    end
    
    table.insert(self.message_handlers, {
        filter = filter,
        func = func
    })
end

-- Register callback query handler
function Client:on_callback_query(filter, func)
    if type(filter) == "function" and func == nil then
        func = filter
        filter = nil
    end
    
    table.insert(self.callback_query_handlers, {
        filter = filter,
        func = func
    })
end

-- Register inline query handler
function Client:on_inline_query(filter, func)
    if type(filter) == "function" and func == nil then
        func = filter
        filter = nil
    end
    
    table.insert(self.inline_query_handlers, {
        filter = filter,
        func = func
    })
end

-- Register edited message handler
function Client:on_edited_message(filter, func)
    if type(filter) == "function" and func == nil then
        func = filter
        filter = nil
    end
    
    table.insert(self.edited_message_handlers, {
        filter = filter,
        func = func
    })
end

-- Load plugins
function Client:load_plugins()
    for plugin_name, plugin_path in pairs(self.plugins) do
        local success, plugin = pcall(require, plugin_path)
        if success and type(plugin) == "table" and plugin.init then
            plugin.init(self)
            print("Loaded plugin: " .. plugin_name)
        else
            print("Failed to load plugin: " .. plugin_name)
        end
    end
end

-- API method wrappers
function Client:send_message(chat_id, text, options)
    options = options or {}
    options.chat_id = chat_id
    options.text = text
    options.parse_mode = options.parse_mode or self.parse_mode
    
    local success, result = self.api:send_message(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:edit_message_text(chat_id, message_id, text, options)
    options = options or {}
    options.chat_id = chat_id
    options.message_id = message_id
    options.text = text
    options.parse_mode = options.parse_mode or self.parse_mode
    
    local success, result = self.api:edit_message_text(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:delete_message(chat_id, message_id)
    local success, result = self.api:delete_message(chat_id, message_id)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:send_photo(chat_id, photo, options)
    options = options or {}
    options.chat_id = chat_id
    options.photo = photo
    
    local success, result = self.api:send_photo(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:send_document(chat_id, document, options)
    options = options or {}
    options.chat_id = chat_id
    options.document = document
    
    local success, result = self.api:send_document(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:answer_callback_query(callback_query_id, options)
    options = options or {}
    options.callback_query_id = callback_query_id
    
    local success, result = self.api:answer_callback_query(options)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:answer_inline_query(inline_query_id, results, options)
    options = options or {}
    options.inline_query_id = inline_query_id
    options.results = results
    
    local success, result = self.api:answer_inline_query(options)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

-- File operations
function Client:download_media(message, file_name, block_size)
    return self.file_manager:download_media(message, file_name, block_size)
end

function Client:download_file(file_path, file_name, block_size)
    return self.file_manager:download_file(file_path, file_name, block_size)
end

-- Extended API methods

function Client:forward_media_group(chat_id, from_chat_id, message_ids, options)
    local success, result = self.api:forward_media_group(chat_id, from_chat_id, message_ids, options)
    if success then
        local messages = {}
        for _, msg_data in ipairs(result) do
            table.insert(messages, types.Message.from_dict(msg_data))
        end
        return messages
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:forward_messages(chat_id, from_chat_id, message_ids, options)
    local success, result = self.api:forward_messages(chat_id, from_chat_id, message_ids, options)
    if success then
        local messages = {}
        for _, msg_data in ipairs(result) do
            table.insert(messages, types.Message.from_dict(msg_data))
        end
        return messages
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:copy_message(chat_id, from_chat_id, message_id, options)
    local success, result = self.api:copy_message(chat_id, from_chat_id, message_id, options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:copy_media_group(chat_id, from_chat_id, message_id, options)
    local success, result = self.api:copy_media_group(chat_id, from_chat_id, message_id, options)
    if success then
        local messages = {}
        for _, msg_data in ipairs(result) do
            table.insert(messages, types.Message.from_dict(msg_data))
        end
        return messages
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:send_sticker(chat_id, sticker, options)
    options = options or {}
    options.chat_id = chat_id
    options.sticker = sticker
    
    local success, result = self.api:send_sticker(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:send_animation(chat_id, animation, options)
    options = options or {}
    options.chat_id = chat_id
    options.animation = animation
    
    local success, result = self.api:send_animation(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:send_voice(chat_id, voice, options)
    options = options or {}
    options.chat_id = chat_id
    options.voice = voice
    
    local success, result = self.api:send_voice(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:send_location(chat_id, latitude, longitude, options)
    options = options or {}
    options.chat_id = chat_id
    options.latitude = latitude
    options.longitude = longitude
    
    local success, result = self.api:send_location(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:edit_message_caption(chat_id, message_id, caption, options)
    options = options or {}
    options.chat_id = chat_id
    options.message_id = message_id
    options.caption = caption
    
    local success, result = self.api:edit_message_caption(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:edit_message_media(chat_id, message_id, media, options)
    options = options or {}
    options.chat_id = chat_id
    options.message_id = message_id
    options.media = media
    
    local success, result = self.api:edit_message_media(options)
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:edit_message_reply_markup(chat_id, message_id, reply_markup)
    local success, result = self.api:edit_message_reply_markup({
        chat_id = chat_id,
        message_id = message_id,
        reply_markup = reply_markup
    })
    if success then
        return types.Message.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:send_chat_action(chat_id, action)
    local success, result = self.api:send_chat_action(chat_id, action)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:delete_messages(chat_id, message_ids)
    local success, result = self.api:delete_messages(chat_id, message_ids)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

-- Group management methods

function Client:ban_chat_member(chat_id, user_id, until_date, revoke_messages)
    local success, result = self.api:kick_chat_member(chat_id, user_id, until_date)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:unban_chat_member(chat_id, user_id, only_if_banned)
    local success, result = self.api:unban_chat_member(chat_id, user_id, only_if_banned)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:restrict_chat_member(chat_id, user_id, permissions, until_date)
    local success, result = self.api:restrict_chat_member(chat_id, user_id, permissions, until_date)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:promote_chat_member(chat_id, user_id, options)
    local success, result = self.api:promote_chat_member(chat_id, user_id, options)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:set_administrator_title(chat_id, user_id, custom_title)
    local success, result = self.api:set_administrator_title(chat_id, user_id, custom_title)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:set_chat_photo(chat_id, photo)
    local success, result = self.api:set_chat_photo({chat_id = chat_id, photo = photo})
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:delete_chat_photo(chat_id)
    local success, result = self.api:delete_chat_photo(chat_id)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:set_chat_title(chat_id, title)
    local success, result = self.api:set_chat_title(chat_id, title)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:set_chat_description(chat_id, description)
    local success, result = self.api:set_chat_description(chat_id, description)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:set_chat_permissions(chat_id, permissions)
    local success, result = self.api:set_chat_permissions(chat_id, permissions)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:pin_chat_message(chat_id, message_id, options)
    local success, result = self.api:pin_chat_message(chat_id, message_id, options)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:unpin_chat_message(chat_id, message_id)
    local success, result = self.api:unpin_chat_message(chat_id, message_id)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:unpin_all_chat_messages(chat_id)
    local success, result = self.api:unpin_all_chat_messages(chat_id)
    if not success then
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
    return true
end

function Client:get_chat_members_count(chat_id)
    local success, result = self.api:get_chat_members_count(chat_id)
    if success then
        return result
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:get_chat_members(chat_id, offset, limit)
    local success, result = self.api:get_chat_members(chat_id, offset, limit)
    if success then
        local members = {}
        for _, member_data in ipairs(result) do
            table.insert(members, types.ChatMember.from_dict(member_data))
        end
        return members
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:export_chat_invite_link(chat_id)
    local success, result = self.api:export_chat_invite_link(chat_id)
    if success then
        return result
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

function Client:create_chat_invite_link(chat_id, options)
    local success, result = self.api:create_chat_invite_link(chat_id, options)
    if success then
        return types.ChatInviteLink.from_dict(result)
    else
        error(errors.TelegramError.new(result.description or "Unknown error"))
    end
end

return Client
