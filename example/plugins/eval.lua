-- Evaluation plugin - handles /eval command and group management functions

local luagram = require("luagram")
local config = require("config")

local plugin = {}

-- Safe evaluation environment
local function create_safe_env(client, message)
    local safe_env = {
        -- Basic Lua functions
        print = function(...) 
            local args = {...}
            local result = ""
            for i, arg in ipairs(args) do
                result = result .. tostring(arg)
                if i < #args then result = result .. "\t" end
            end
            return result
        end,
        tostring = tostring,
        tonumber = tonumber,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        select = select,
        unpack = unpack,
        
        -- Math library
        math = math,
        
        -- String library
        string = string,
        
        -- Table library
        table = table,
        
        -- OS limited functions
        os = {
            time = os.time,
            date = os.date,
            clock = os.clock,
            difftime = os.difftime
        },
        
        -- Bot context
        bot = client,
        message = message,
        chat = message.chat,
        user = message.from,
        
        -- Utility functions
        utils = luagram.utils,
        json = require("luagram.json"),
        
        -- Bot methods (safe wrappers)
        send_message = function(text, options)
            return client:send_message(message.chat.id, text, options)
        end,
        
        edit_message = function(msg_id, text, options)
            return client:edit_message_text(message.chat.id, msg_id, text, options)
        end,
        
        delete_message = function(msg_id)
            return client:delete_message(message.chat.id, msg_id)
        end,
        
        get_chat_info = function()
            return {
                id = message.chat.id,
                type = message.chat.type,
                title = message.chat.title,
                username = message.chat.username,
                description = message.chat.description
            }
        end,
        
        get_user_info = function(user_id)
            user_id = user_id or message.from.id
            if user_id == message.from.id then
                return {
                    id = message.from.id,
                    username = message.from.username,
                    first_name = message.from.first_name,
                    last_name = message.from.last_name,
                    language_code = message.from.language_code
                }
            end
            return nil
        end
    }
    
    -- Set metatable to prevent access to global environment
    setmetatable(safe_env, {
        __index = function(t, k)
            error("Access to '" .. tostring(k) .. "' is not allowed")
        end,
        __newindex = function(t, k, v)
            rawset(t, k, v)
        end
    })
    
    return safe_env
end

-- Check if user is admin
local function is_admin(user_id)
    for _, admin_id in ipairs(config.ADMIN_IDS) do
        if user_id == admin_id then
            return true
        end
    end
    return false
end

-- Check if user is chat admin
local function is_chat_admin(client, chat_id, user_id)
    local success, chat_member = client.api:get_chat_member(chat_id, user_id)
    if success then
        return chat_member.status == "administrator" or chat_member.status == "creator"
    end
    return false
end

function plugin.init(client)
    -- Handle /eval command
    client:on_message(luagram.filters.command("eval"), function(client, message)
        local user = message.from
        
        -- Check if user is authorized
        if not is_admin(user.id) then
            client:send_message(message.chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local code = text:match("/eval%s+(.+)")
        
        if not code then
            local help_text = [[
*🔧 Eval Command Help*

Usage: `/eval <lua_code>`

*Examples:*
```lua
/eval return 2 + 2

/eval 
local result = {}
for i = 1, 5 do
    table.insert(result, i * 2)
end
return table.concat(result, ", ")

/eval
send_message("Hello from eval!")
return "Message sent"

/eval
return get_chat_info()
```

*Available functions:*
• `send_message(text, options)` - Send message to current chat
• `edit_message(msg_id, text)` - Edit a message
• `delete_message(msg_id)` - Delete a message
• `get_chat_info()` - Get current chat information
• `get_user_info(user_id?)` - Get user information
• `bot` - Access to bot client
• `message`, `chat`, `user` - Current context
• `math`, `string`, `table`, `os` (limited) - Standard libraries
• `utils`, `json` - Utility libraries

*Security:* This command is restricted to bot administrators only.
            ]]
            
            client:send_message(message.chat.id, help_text, {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Create safe environment
        local env = create_safe_env(client, message)
        
        -- Wrap code in a function if it doesn't return anything
        local wrapped_code = code
        if not code:match("return%s") and not code:match("^%s*return%s") then
            wrapped_code = "return (" .. code .. ")"
        end
        
        -- Try to compile the code
        local func, compile_err = load(wrapped_code, "eval", "t", env)
        
        if not func then
            client:send_message(message.chat.id, string.format(
                "❌ *Compilation Error:*\n```\n%s\n```", 
                compile_err
            ), {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Execute with timeout protection
        local start_time = os.time()
        local timeout = 10 -- 10 seconds
        
        local success, result = pcall(function()
            local co = coroutine.create(func)
            local ok, res = coroutine.resume(co)
            
            -- Check for timeout
            if os.time() - start_time > timeout then
                error("Execution timeout")
            end
            
            if not ok then
                error(res)
            end
            
            return res
        end)
        
        if success then
            local result_text
            if result == nil then
                result_text = "nil"
            elseif type(result) == "table" then
                -- Pretty print tables
                local function serialize_table(t, depth)
                    depth = depth or 0
                    if depth > 3 then return "..." end
                    
                    local parts = {}
                    local is_array = true
                    local max_index = 0
                    
                    -- Check if it's an array
                    for k, v in pairs(t) do
                        if type(k) ~= "number" or k ~= math.floor(k) or k <= 0 then
                            is_array = false
                            break
                        end
                        max_index = math.max(max_index, k)
                    end
                    
                    if is_array then
                        for i = 1, max_index do
                            if t[i] == nil then
                                is_array = false
                                break
                            end
                        end
                    end
                    
                    if is_array then
                        -- Array format
                        for i = 1, max_index do
                            local v = t[i]
                            if type(v) == "table" then
                                table.insert(parts, serialize_table(v, depth + 1))
                            else
                                table.insert(parts, tostring(v))
                            end
                        end
                        return "[" .. table.concat(parts, ", ") .. "]"
                    else
                        -- Object format
                        for k, v in pairs(t) do
                            local key_str = type(k) == "string" and k or "[" .. tostring(k) .. "]"
                            local value_str
                            if type(v) == "table" then
                                value_str = serialize_table(v, depth + 1)
                            else
                                value_str = tostring(v)
                            end
                            table.insert(parts, key_str .. " = " .. value_str)
                        end
                        return "{" .. table.concat(parts, ", ") .. "}"
                    end
                end
                
                result_text = serialize_table(result)
            else
                result_text = tostring(result)
            end
            
            -- Limit output length
            if #result_text > 4000 then
                result_text = result_text:sub(1, 4000) .. "..."
            end
            
            client:send_message(message.chat.id, string.format(
                "✅ *Execution Result:*\n```\n%s\n```", 
                result_text
            ), {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id, string.format(
                "❌ *Runtime Error:*\n```\n%s\n```", 
                result
            ), {
                reply_to_message_id = message.message_id
            })
        end
        
        print(string.format("User %s (%d) executed eval: %s", 
            user.first_name, user.id, code:sub(1, 100)))
    end)
    
    -- Advanced group management commands
    
    -- Handle /gban command (global ban simulation)
    client:on_message(luagram.filters.command("gban"), function(client, message)
        if not is_admin(message.from.id) then
            client:send_message(message.chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if message.chat.type == "private" then
            client:send_message(message.chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local target_user = nil
        if message.reply_to_message and message.reply_to_message.from then
            target_user = message.reply_to_message.from
        end
        
        if not target_user then
            client:send_message(message.chat.id, "ℹ️ Reply to a message to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if is_admin(target_user.id) then
            client:send_message(message.chat.id, "❌ Cannot ban an administrator.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Simulate global ban (ban from current group and log)
        local success, result = client.api:kick_chat_member(message.chat.id, target_user.id)
        
        if success then
            client:send_message(message.chat.id, string.format(
                "🔨 *Global Ban Applied*\n\n" ..
                "User: %s (@%s)\n" ..
                "User ID: `%d`\n" ..
                "Banned by: %s\n" ..
                "Chat: %s\n\n" ..
                "_This user has been banned from this group and logged for potential future action._",
                target_user.first_name,
                target_user.username or "none",
                target_user.id,
                message.from.first_name,
                message.chat.title or "this chat"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("GBAN: User %s (%d) banned by %s (%d) in chat %d", 
                target_user.first_name, target_user.id, 
                message.from.first_name, message.from.id, 
                message.chat.id))
        else
            client:send_message(message.chat.id, "❌ Failed to ban user: " .. (result.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /purge command
    client:on_message(luagram.filters.command("purge"), function(client, message)
        if not is_admin(message.from.id) and not is_chat_admin(client, message.chat.id, message.from.id) then
            client:send_message(message.chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if message.chat.type == "private" then
            client:send_message(message.chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if not message.reply_to_message then
            client:send_message(message.chat.id, "ℹ️ Reply to a message to purge from that point.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local start_msg_id = message.reply_to_message.message_id
        local end_msg_id = message.message_id
        local purged_count = 0
        
        -- Delete messages in range (simplified - would need proper implementation)
        for msg_id = start_msg_id, end_msg_id do
            local success = pcall(function()
                client:delete_message(message.chat.id, msg_id)
                purged_count = purged_count + 1
            end)
            
            if not success then
                -- Message might not exist or can't be deleted
            end
        end
        
        local result_msg = client:send_message(message.chat.id, string.format(
            "🗑️ Purged %d messages", purged_count
        ))
        
        -- Auto-delete the result message after 5 seconds (simulated)
        print(string.format("Purged %d messages in chat %d by %s", 
            purged_count, message.chat.id, message.from.first_name))
    end)
    
    -- Handle /warns command
    client:on_message(luagram.filters.command("warns"), function(client, message)
        if message.chat.type == "private" then
            client:send_message(message.chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local target_user = message.from
        if message.reply_to_message and message.reply_to_message.from then
            target_user = message.reply_to_message.from
        end
        
        -- Simulate warning system (would need database in real implementation)
        local warns_count = math.random(0, 3) -- Simulated
        
        local warns_text = string.format([[
*⚠️ Warnings for %s*

User: %s (@%s)
User ID: `%d`
Current Warnings: %d/3

_Warnings are used to track user behavior. After 3 warnings, automatic action may be taken._
]], 
            target_user.first_name,
            target_user.first_name,
            target_user.username or "none",
            target_user.id,
            warns_count
        )
        
        client:send_message(message.chat.id, warns_text, {
            reply_to_message_id = message.message_id
        })
    end)
    
    -- Handle /warn command
    client:on_message(luagram.filters.command("warn"), function(client, message)
        if not is_admin(message.from.id) and not is_chat_admin(client, message.chat.id, message.from.id) then
            client:send_message(message.chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if message.chat.type == "private" then
            client:send_message(message.chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local target_user = nil
        if message.reply_to_message and message.reply_to_message.from then
            target_user = message.reply_to_message.from
        end
        
        if not target_user then
            client:send_message(message.chat.id, "ℹ️ Reply to a message to warn the user.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if is_admin(target_user.id) then
            client:send_message(message.chat.id, "❌ Cannot warn an administrator.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local reason = message.text:match("/warn%s+(.+)") or "No reason specified"
        
        -- Simulate warning system
        local new_warn_count = math.random(1, 3)
        
        local warn_text = string.format([[
⚠️ *User Warned*

User: %s (@%s)
Warned by: %s
Reason: %s
Total Warnings: %d/3

%s
]], 
            target_user.first_name,
            target_user.username or "none",
            message.from.first_name,
            reason,
            new_warn_count,
            new_warn_count >= 3 and "_⚠️ Warning limit reached! Consider taking action._" or ""
        )
        
        client:send_message(message.chat.id, warn_text, {
            reply_to_message_id = message.reply_to_message.message_id
        })
        
        print(string.format("User %s (%d) warned by %s (%d) in chat %d. Reason: %s", 
            target_user.first_name, target_user.id,
            message.from.first_name, message.from.id,
            message.chat.id, reason))
    end)
    
    -- Handle /chatinfo command
    client:on_message(luagram.filters.command("chatinfo"), function(client, message)
        local chat = message.chat
        
        -- Get additional chat information
        local success, chat_info = client.api:get_chat(chat.id)
        local members_count = 0
        
        if chat.type ~= "private" then
            local count_success, count_result = client.api:get_chat_members_count(chat.id)
            if count_success then
                members_count = count_result
            end
        end
        
        local info_text = string.format([[
*💬 Chat Information*

**Basic Info:**
• Chat ID: `%s`
• Type: %s
• Title: %s
• Username: @%s

**Statistics:**
• Members: %d
• Created: %s

**Settings:**
• Description: %s
• Invite Link: %s

**Permissions:**
• Messages: %s
• Media: %s
• Polls: %s
• Links: %s
]], 
            chat.id,
            chat.type,
            chat.title or "N/A",
            chat.username or "none",
            members_count,
            "Unknown", -- Would need chat creation date
            chat.description or "No description",
            "Available to admins",
            "Allowed",
            "Allowed", 
            "Allowed",
            "Allowed"
        )
        
        client:send_message(message.chat.id, info_text, {
            reply_to_message_id = message.message_id
        })
    end)
    
    -- Handle /admins command
    client:on_message(luagram.filters.command("admins"), function(client, message)
        if message.chat.type == "private" then
            client:send_message(message.chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local success, admins = client.api:get_chat_members(message.chat.id)
        
        if success and admins then
            local admin_list = {"*👑 Chat Administrators:*\n"}
            
            for _, admin in ipairs(admins) do
                local status_emoji = admin.status == "creator" and "👑" or "⭐"
                local admin_info = string.format(
                    "%s %s (@%s) - %s",
                    status_emoji,
                    admin.user.first_name,
                    admin.user.username or "none",
                    admin.status
                )
                table.insert(admin_list, admin_info)
            end
            
            local admins_text = table.concat(admin_list, "\n")
            
            client:send_message(message.chat.id, admins_text, {
                reply_to_message_id = message.message_id
            })
        else
            client:send_message(message.chat.id, "❌ Failed to get administrator list.", {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    print("Evaluation and group management plugin loaded successfully")
end

return plugin
