-- Start plugin - handles /start command and new user onboarding

local luagram = require("luagram")
local config = require("config")

local plugin = {}

function plugin.init(client)
    -- Handle /start command
    client:on_message(luagram.filters.command("start"), function(client, message)
        local user = message.from
        local chat = message.chat
        
        -- Different responses for private vs group chats
        if chat.type == "private" then
            -- Private chat start message
            local welcome_text = string.format([[
👋 *Hello %s!*

Welcome to the Example Bot! I'm here to help you with various tasks.

*What I can do:*
• Echo your messages
• Handle file uploads
• Provide chat information
• Admin tools (for authorized users)
• Interactive keyboards and buttons

Type /help to see all available commands.

*Quick Start:*
• Send me any text to see it echoed back
• Upload a file to get its information
• Try /keyboard for an interactive example

Let's get started! 🚀
]], user.first_name)
            
            -- Send welcome message with inline keyboard
            local keyboard = luagram.types.InlineKeyboardMarkup.new({
                {
                    {text = "📚 Help", callback_data = "help"},
                    {text = "ℹ️ Info", callback_data = "info"}
                },
                {
                    {text = "🎯 Try Keyboard", callback_data = "keyboard_demo"}
                }
            })
            
            client:send_message(chat.id, welcome_text, {
                reply_markup = keyboard
            })
            
        else
            -- Group chat start message
            local group_welcome = string.format([[
👋 *Hello everyone!*

Thanks for adding me to %s!

I'm the Example Bot and I can help manage this group. Here's what I can do:

*Group Features:*
• Welcome new members
• File information and handling
• Admin commands (for authorized users)
• Message statistics
• Interactive responses

Type /help@your_bot_username to see all commands.

*For Admins:*
Make sure to give me admin privileges to use moderation features.
]], chat.title or "the group")
            
            client:send_message(chat.id, group_welcome)
        end
        
        -- Log the start command
        print(string.format("User %s (%d) started the bot in %s (%d)", 
            user.first_name, user.id, chat.title or "private", chat.id))
    end)
    
    -- Handle new chat members
    client:on_message(luagram.filters.service, function(client, message)
        if message.new_chat_members then
            for _, new_member in ipairs(message.new_chat_members) do
                -- Don't welcome bots
                if not new_member.is_bot then
                    local welcome_text = string.format(
                        "🎉 Welcome to %s, %s!\n\n" ..
                        "Feel free to introduce yourself and check out /help for available commands.",
                        message.chat.title or "the group",
                        new_member.first_name
                    )
                    
                    -- Create welcome keyboard
                    local keyboard = luagram.types.InlineKeyboardMarkup.new({
                        {
                            {text = "👋 Say Hello", callback_data = "welcome_hello_" .. new_member.id},
                            {text = "📖 Rules", callback_data = "welcome_rules"}
                        }
                    })
                    
                    client:send_message(message.chat.id, welcome_text, {
                        reply_markup = keyboard
                    })
                    
                    print(string.format("Welcomed new member: %s (%d)", 
                        new_member.first_name, new_member.id))
                end
            end
        end
        
        -- Handle member left
        if message.left_chat_member then
            local left_member = message.left_chat_member
            if not left_member.is_bot then
                local goodbye_text = string.format(
                    "👋 %s has left the group. Goodbye!",
                    left_member.first_name
                )
                
                client:send_message(message.chat.id, goodbye_text)
            end
        end
    end)
    
    -- Handle welcome callback queries
    client:on_callback_query(function(client, callback_query)
        local data = callback_query.data
        
        if data == "help" then
            -- Redirect to help command
            local help_text = [[
*📚 Available Commands:*

/start - Start the bot
/help - Show help message
/echo [text] - Echo your message
/info - Get chat information
/keyboard - Interactive keyboard demo
/stats - Bot statistics

*🔧 Admin Commands:*
/ban - Ban user (reply to message)
/unban - Unban user
/kick - Kick user (reply to message)

*📁 File Features:*
Send any file to get detailed information about it.

*🎯 Interactive Features:*
Use inline keyboards and callback buttons for better user experience.
            ]]
            
            client:edit_message_text(
                callback_query.message.chat.id,
                callback_query.message.message_id,
                help_text
            )
            
        elseif data == "info" then
            local user = callback_query.from
            local info_text = string.format([[
*ℹ️ Your Information:*

• User ID: `%d`
• Username: @%s
• First Name: %s
• Last Name: %s
• Language: %s

*🤖 Bot Information:*
• Version: 1.0.0
• Library: Luagram
• Uptime: Online ✅
            ]], 
                user.id,
                user.username or "Not set",
                user.first_name,
                user.last_name or "Not set",
                user.language_code or "Unknown"
            )
            
            client:edit_message_text(
                callback_query.message.chat.id,
                callback_query.message.message_id,
                info_text
            )
            
        elseif data == "keyboard_demo" then
            local demo_keyboard = luagram.types.InlineKeyboardMarkup.new({
                {
                    {text = "🔴", callback_data = "demo_red"},
                    {text = "🟡", callback_data = "demo_yellow"},
                    {text = "🟢", callback_data = "demo_green"}
                },
                {
                    {text = "🔄 Shuffle", callback_data = "demo_shuffle"},
                    {text = "❌ Close", callback_data = "demo_close"}
                }
            })
            
            client:edit_message_text(
                callback_query.message.chat.id,
                callback_query.message.message_id,
                "*🎯 Interactive Keyboard Demo*\n\nTry clicking the buttons below!",
                {reply_markup = demo_keyboard}
            )
            
        elseif data:match("^welcome_hello_") then
            local user_id = tonumber(data:match("^welcome_hello_(%d+)"))
            if callback_query.from.id == user_id then
                client:answer_callback_query(callback_query.id, {
                    text = "👋 Hello! Welcome to the group!",
                    show_alert = true
                })
            end
            
        elseif data == "welcome_rules" then
            local rules_text = [[
*📋 Group Rules:*

1. Be respectful to all members
2. No spam or excessive self-promotion
3. Stay on topic
4. No harassment or bullying
5. Follow Telegram's Terms of Service

Violations may result in warnings or removal from the group.
            ]]
            
            client:answer_callback_query(callback_query.id, {
                text = rules_text,
                show_alert = true
            })
            
        elseif data:match("^demo_") then
            local action = data:match("^demo_(.+)")
            
            if action == "close" then
                client:delete_message(
                    callback_query.message.chat.id,
                    callback_query.message.message_id
                )
            elseif action == "red" then
                client:answer_callback_query(callback_query.id, {
                    text = "🔴 You clicked Red!",
                    show_alert = false
                })
            elseif action == "yellow" then
                client:answer_callback_query(callback_query.id, {
                    text = "🟡 You clicked Yellow!",
                    show_alert = false
                })
            elseif action == "green" then
                client:answer_callback_query(callback_query.id, {
                    text = "🟢 You clicked Green!",
                    show_alert = false
                })
            elseif action == "shuffle" then
                local colors = {"🔴", "🟡", "🟢", "🔵", "🟣", "🟠"}
                local shuffled = {}
                
                -- Simple shuffle
                for i = 1, 3 do
                    shuffled[i] = colors[math.random(#colors)]
                end
                
                local new_keyboard = luagram.types.InlineKeyboardMarkup.new({
                    {
                        {text = shuffled[1], callback_data = "demo_color1"},
                        {text = shuffled[2], callback_data = "demo_color2"}, 
                        {text = shuffled[3], callback_data = "demo_color3"}
                    },
                    {
                        {text = "🔄 Shuffle", callback_data = "demo_shuffle"},
                        {text = "❌ Close", callback_data = "demo_close"}
                    }
                })
                
                client:edit_message_reply_markup(
                    callback_query.message.chat.id,
                    callback_query.message.message_id,
                    new_keyboard
                )
                
                client:answer_callback_query(callback_query.id, {
                    text = "🔄 Colors shuffled!",
                    show_alert = false
                })
            end
        end
    end)
    
    print("Start plugin loaded successfully")
end

return plugin
