-- Echo plugin - handles text echoing and message manipulation

local luagram = require("luagram")

local plugin = {}

function plugin.init(client)
    -- Handle /echo command
    client:on_message(luagram.filters.command("echo"), function(client, message)
        local text = message.text
        local args = text:match("/echo%s+(.+)")
        
        if args then
            -- Echo the provided text
            client:send_message(message.chat.id, "🔊 Echo: " .. args, {
                reply_to_message_id = message.message_id
            })
        else
            -- No arguments provided
            client:send_message(message.chat.id, 
                "ℹ️ Usage: `/echo <text>`\n\nExample: `/echo Hello World!`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /reverse command
    client:on_message(luagram.filters.command("reverse"), function(client, message)
        local text = message.text
        local args = text:match("/reverse%s+(.+)")
        
        if args then
            -- Reverse the text
            local reversed = string.reverse(args)
            client:send_message(message.chat.id, "🔄 Reversed: " .. reversed, {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id,
                "ℹ️ Usage: `/reverse <text>`\n\nExample: `/reverse Hello`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /upper command
    client:on_message(luagram.filters.command("upper"), function(client, message)
        local text = message.text
        local args = text:match("/upper%s+(.+)")
        
        if args then
            client:send_message(message.chat.id, "🔤 UPPER: " .. string.upper(args), {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id,
                "ℹ️ Usage: `/upper <text>`\n\nExample: `/upper hello world`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /lower command
    client:on_message(luagram.filters.command("lower"), function(client, message)
        local text = message.text
        local args = text:match("/lower%s+(.+)")
        
        if args then
            client:send_message(message.chat.id, "🔡 lower: " .. string.lower(args), {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id,
                "ℹ️ Usage: `/lower <text>`\n\nExample: `/lower HELLO WORLD`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /count command - count characters, words, lines
    client:on_message(luagram.filters.command("count"), function(client, message)
        local text = message.text
        local args = text:match("/count%s+(.+)")
        
        if args then
            local chars = #args
            local words = 0
            local lines = 1
            
            -- Count words
            for word in args:gmatch("%S+") do
                words = words + 1
            end
            
            -- Count lines
            for line in args:gmatch("\n") do
                lines = lines + 1
            end
            
            local count_text = string.format([[
📊 *Text Statistics:*

• Characters: %d
• Words: %d
• Lines: %d
• Average word length: %.1f

Text: "%s"
]], chars, words, lines, chars / math.max(words, 1), args)
            
            client:send_message(message.chat.id, count_text, {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id,
                "ℹ️ Usage: `/count <text>`\n\nExample: `/count Hello world! How are you?`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /repeat command
    client:on_message(luagram.filters.command("repeat"), function(client, message)
        local text = message.text
        local count, args = text:match("/repeat%s+(%d+)%s+(.+)")
        
        if count and args then
            count = tonumber(count)
            
            -- Limit repetitions to prevent spam
            if count > 10 then
                client:send_message(message.chat.id, 
                    "⚠️ Maximum 10 repetitions allowed.", {
                    reply_to_message_id = message.message_id
                })
                return
            end
            
            local repeated_text = ""
            for i = 1, count do
                repeated_text = repeated_text .. args
                if i < count then
                    repeated_text = repeated_text .. "\n"
                end
            end
            
            client:send_message(message.chat.id, "🔁 Repeated " .. count .. " times:\n\n" .. repeated_text, {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id,
                "ℹ️ Usage: `/repeat <count> <text>`\n\nExample: `/repeat 3 Hello!`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /replace command
    client:on_message(luagram.filters.command("replace"), function(client, message)
        local text = message.text
        local find, replace, args = text:match("/replace%s+\"([^\"]+)\"%s+\"([^\"]+)\"%s+(.+)")
        
        if find and replace and args then
            local result = string.gsub(args, find, replace)
            
            client:send_message(message.chat.id, string.format(
                "🔄 *Replace Result:*\n\n" ..
                "Original: %s\n" ..
                "Replaced '%s' with '%s'\n" ..
                "Result: %s", 
                args, find, replace, result
            ), {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id,
                "ℹ️ Usage: `/replace \"find\" \"replace\" <text>`\n\n" ..
                "Example: `/replace \"hello\" \"hi\" hello world!`", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Auto-echo for messages containing specific keywords
    client:on_message(luagram.filters.text, function(client, message)
        local text = message.text:lower()
        
        -- Don't echo commands
        if text:sub(1, 1) == "/" then
            return
        end
        
        -- Echo messages containing "echo me"
        if text:find("echo me") then
            client:send_message(message.chat.id, "🔊 " .. message.text, {
                reply_to_message_id = message.message_id
            })
        end
        
        -- Respond to greetings
        if text:find("hello") or text:find("hi") or text:find("hey") then
            local greetings = {
                "👋 Hello there!",
                "🙋‍♂️ Hi! How are you?",
                "👋 Hey! Nice to see you!",
                "🤗 Hello! Hope you're having a great day!"
            }
            
            math.randomseed(os.time())
            local greeting = greetings[math.random(#greetings)]
            
            client:send_message(message.chat.id, greeting, {
                reply_to_message_id = message.message_id
            })
        end
        
        -- Respond to thank you messages
        if text:find("thank") or text:find("thanks") then
            local responses = {
                "😊 You're welcome!",
                "🤗 Happy to help!",
                "👍 No problem!",
                "✨ Anytime!"
            }
            
            math.randomseed(os.time())
            local response = responses[math.random(#responses)]
            
            client:send_message(message.chat.id, response, {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    print("Echo plugin loaded successfully")
end

return plugin
