#!/usr/bin/env lua

-- Example Telegram Bot using Luagram
-- This bot demonstrates basic functionality and common patterns

-- Import Luagram
local luagram = require("luagram")
local config = require("config")

-- Create bot client
local bot = luagram.Client.new(config.BOT_TOKEN, {
    session_name = "example_bot_session",
    parse_mode = "Markdown",
    plugins = {
        start = "plugins.start",
        echo = "plugins.echo",
        admin = "plugins.admin",
        eval = "plugins.eval"
    }
})

-- Basic message handler
bot:on_message(luagram.filters.text, function(client, message)
    print(string.format("[%s] %s: %s", 
        os.date("%H:%M:%S"), 
        message.from.first_name, 
        message.text))
end)

-- Handle /help command
bot:on_message(luagram.filters.command("help"), function(client, message)
    local help_text = [[
*Available Commands:*

/start - Start the bot
/help - Show this help message
/echo [text] - Echo your message
/info - Get chat information
/keyboard - Show inline keyboard example

*Admin Commands:*
/ban - Ban user (reply to message)
/unban - Unban user (reply to message)
/stats - Show bot statistics

*Features:*
• File handling (send any file to get info)
• Inline keyboards and callbacks
• Message editing and deletion
• Admin management tools
    ]]
    
    client:send_message(message.chat.id, help_text)
end)

-- Handle /info command
bot:on_message(luagram.filters.command("info"), function(client, message)
    local chat = message.chat
    local user = message.from
    
    local info_text = string.format([[
*Chat Information:*
• Chat ID: `%s`
• Chat Type: %s
• Chat Title: %s

*User Information:*
• User ID: `%s`
• Username: @%s
• First Name: %s
• Last Name: %s
]], 
        chat.id,
        chat.type,
        chat.title or "N/A",
        user.id,
        user.username or "None",
        user.first_name,
        user.last_name or "N/A"
    )
    
    client:send_message(message.chat.id, info_text)
end)

-- Handle /keyboard command - demonstrate inline keyboards
bot:on_message(luagram.filters.command("keyboard"), function(client, message)
    local keyboard = luagram.types.InlineKeyboardMarkup.new({
        {
            {text = "🔴 Red", callback_data = "color_red"},
            {text = "🟢 Green", callback_data = "color_green"},
            {text = "🔵 Blue", callback_data = "color_blue"}
        },
        {
            {text = "🌐 Visit Website", url = "https://telegram.org"}
        },
        {
            {text = "❌ Close", callback_data = "close"}
        }
    })
    
    client:send_message(message.chat.id, "Choose a color:", {
        reply_markup = keyboard
    })
end)

-- Handle callback queries
bot:on_callback_query(function(client, callback_query)
    local data = callback_query.data
    
    if data:match("^color_") then
        local color = data:match("^color_(.+)")
        local color_names = {
            red = "🔴 Red",
            green = "🟢 Green", 
            blue = "🔵 Blue"
        }
        
        client:edit_message_text(
            callback_query.message.chat.id,
            callback_query.message.message_id,
            "You selected: " .. color_names[color]
        )
        
        client:answer_callback_query(callback_query.id, {
            text = "Color selected: " .. color_names[color],
            show_alert = false
        })
        
    elseif data == "close" then
        client:delete_message(
            callback_query.message.chat.id,
            callback_query.message.message_id
        )
        
        client:answer_callback_query(callback_query.id)
    end
end)

-- Handle file uploads
bot:on_message(luagram.filters.document, function(client, message)
    local doc = message.document
    local file_info = string.format([[
*File Information:*
• Name: %s
• Size: %s bytes
• MIME Type: %s
• File ID: `%s`

Use /download to download this file.
]], 
        doc.file_name or "Unknown",
        doc.file_size or "Unknown",
        doc.mime_type or "Unknown",
        doc.file_id
    )
    
    client:send_message(message.chat.id, file_info)
end)

-- Handle photo uploads
bot:on_message(luagram.filters.photo, function(client, message)
    local photo = message.photo[#message.photo]  -- Get largest size
    
    local photo_info = string.format([[
*Photo Information:*
• Size: %dx%d
• File Size: %s bytes
• File ID: `%s`

Caption: %s
]], 
        photo.width,
        photo.height,
        photo.file_size or "Unknown",
        photo.file_id,
        message.caption or "No caption"
    )
    
    client:send_message(message.chat.id, photo_info)
end)

-- Handle errors gracefully
bot:on_message(luagram.filters.command("error"), function(client, message)
    -- Intentional error for testing
    error("This is a test error")
end)

-- Handle private chats differently
bot:on_message(luagram.filters.private, function(client, message)
    -- This runs for all private messages
    -- You can add private chat specific logic here
end)

-- Handle group messages
bot:on_message(luagram.filters.group | luagram.filters.supergroup, function(client, message)
    -- This runs for all group messages
    -- You can add group specific logic here
end)

-- Handle forwarded messages
bot:on_message(luagram.filters.forwarded, function(client, message)
    if message.forward_from then
        client:send_message(message.chat.id, 
            "This message was forwarded from: " .. message.forward_from.first_name)
    end
end)

-- Handle mentions
bot:on_message(luagram.filters.mention({"everyone", "all"}), function(client, message)
    client:send_message(message.chat.id, "You mentioned everyone!")
end)

-- Handle hashtags
bot:on_message(luagram.filters.hashtag({"important", "urgent"}), function(client, message)
    client:send_message(message.chat.id, "This message has an important hashtag!")
end)

-- Statistics tracking
local stats = {
    messages_received = 0,
    commands_processed = 0,
    files_received = 0
}

-- Update statistics
bot:on_message(luagram.filters.all, function(client, message)
    stats.messages_received = stats.messages_received + 1
    
    if message.text and message.text:sub(1, 1) == "/" then
        stats.commands_processed = stats.commands_processed + 1
    end
    
    if message.document or message.photo or message.video or message.audio then
        stats.files_received = stats.files_received + 1
    end
end)

-- Handle /stats command
bot:on_message(luagram.filters.command("stats"), function(client, message)
    local stats_text = string.format([[
*Bot Statistics:*
• Messages received: %d
• Commands processed: %d  
• Files received: %d
• Uptime: %s
]], 
        stats.messages_received,
        stats.commands_processed,
        stats.files_received,
        os.date("!%H:%M:%S", os.time() - (stats.start_time or os.time()))
    )
    
    client:send_message(message.chat.id, stats_text)
end)

-- Initialize start time
stats.start_time = os.time()

-- Error handling wrapper
local function safe_start()
    local success, err = pcall(function()
        print("Starting example bot...")
        print("Bot token: " .. config.BOT_TOKEN:sub(1, 10) .. "...")
        
        bot:start()
    end)
    
    if not success then
        print("Error starting bot: " .. tostring(err))
        os.exit(1)
    end
end

-- Graceful shutdown handling
local function signal_handler(signal)
    print("\nReceived signal " .. signal .. ", shutting down...")
    bot:stop()
    print("Bot stopped successfully")
    os.exit(0)
end

-- Set up signal handlers (Unix-like systems)
if os.getenv("UNIX") or os.getenv("SHELL") then
    os.execute("trap 'kill -TERM $PPID' INT TERM")
end

-- Start the bot
safe_start()
