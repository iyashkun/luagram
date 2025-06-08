-- Admin plugin - handles administrative commands and user management

local luagram = require("luagram")
local config = require("config")

local plugin = {}

-- Check if user is admin
local function is_admin(user_id)
    for _, admin_id in ipairs(config.ADMIN_IDS) do
        if user_id == admin_id then
            return true
        end
    end
    return false
end

-- Check if user is admin of the chat
local function is_chat_admin(client, chat_id, user_id)
    local success, chat_member = client.api:get_chat_member(chat_id, user_id)
    if success then
        return chat_member.status == "administrator" or chat_member.status == "creator"
    end
    return false
end

-- Get user from replied message or mention
local function get_target_user(message, args)
    if message.reply_to_message and message.reply_to_message.from then
        return message.reply_to_message.from
    elseif args and args[1] then
        local user_id = tonumber(args[1])
        if user_id then
            return {id = user_id, first_name = "User"}
        end
    end
    return nil
end

function plugin.init(client)
    -- Handle /ban command
    client:on_message(luagram.filters.command("ban"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        -- Check if user is admin
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Only works in groups
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local args = {}
        for arg in text:gmatch("/ban%s+(.*)") do
            for word in arg:gmatch("%S+") do
                table.insert(args, word)
            end
        end
        
        local target_user = get_target_user(message, args)
        
        if not target_user then
            client:send_message(chat.id, 
                "ℹ️ Usage: Reply to a message or use `/ban <user_id>`", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Don't ban admins
        if is_admin(target_user.id) or is_chat_admin(client, chat.id, target_user.id) then
            client:send_message(chat.id, "❌ Cannot ban an administrator.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Ban the user
        local success, result = client.api:kick_chat_member(chat.id, target_user.id)
        
        if success then
            client:send_message(chat.id, string.format(
                "🔨 User %s has been banned from the group.",
                target_user.first_name or "Unknown"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("Admin %s banned user %s (%d) from chat %d", 
                user.first_name, target_user.first_name or "Unknown", target_user.id, chat.id))
        else
            client:send_message(chat.id, "❌ Failed to ban user: " .. (result.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /unban command
    client:on_message(luagram.filters.command("unban"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local args = {}
        for arg in text:gmatch("/unban%s+(.*)") do
            for word in arg:gmatch("%S+") do
                table.insert(args, word)
            end
        end
        
        local target_user = get_target_user(message, args)
        
        if not target_user then
            client:send_message(chat.id,
                "ℹ️ Usage: Reply to a message or use `/unban <user_id>`", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local success, result = client.api:unban_chat_member(chat.id, target_user.id, true)
        
        if success then
            client:send_message(chat.id, string.format(
                "✅ User %s has been unbanned from the group.",
                target_user.first_name or "Unknown"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("Admin %s unbanned user %s (%d) from chat %d",
                user.first_name, target_user.first_name or "Unknown", target_user.id, chat.id))
        else
            client:send_message(chat.id, "❌ Failed to unban user: " .. (result.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /kick command
    client:on_message(luagram.filters.command("kick"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local args = {}
        for arg in text:gmatch("/kick%s+(.*)") do
            for word in arg:gmatch("%S+") do
                table.insert(args, word)
            end
        end
        
        local target_user = get_target_user(message, args)
        
        if not target_user then
            client:send_message(chat.id,
                "ℹ️ Usage: Reply to a message or use `/kick <user_id>`", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if is_admin(target_user.id) or is_chat_admin(client, chat.id, target_user.id) then
            client:send_message(chat.id, "❌ Cannot kick an administrator.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Kick user (ban then unban immediately)
        local success1, result1 = client.api:kick_chat_member(chat.id, target_user.id)
        local success2, result2 = client.api:unban_chat_member(chat.id, target_user.id, true)
        
        if success1 then
            client:send_message(chat.id, string.format(
                "👢 User %s has been kicked from the group.",
                target_user.first_name or "Unknown"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("Admin %s kicked user %s (%d) from chat %d",
                user.first_name, target_user.first_name or "Unknown", target_user.id, chat.id))
        else
            client:send_message(chat.id, "❌ Failed to kick user: " .. (result1.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /mute command
    client:on_message(luagram.filters.command("mute"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local args = {}
        for arg in text:gmatch("/mute%s+(.*)") do
            for word in arg:gmatch("%S+") do
                table.insert(args, word)
            end
        end
        
        local target_user = get_target_user(message, args)
        
        if not target_user then
            client:send_message(chat.id,
                "ℹ️ Usage: Reply to a message or use `/mute <user_id>`", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if is_admin(target_user.id) or is_chat_admin(client, chat.id, target_user.id) then
            client:send_message(chat.id, "❌ Cannot mute an administrator.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Mute permissions
        local permissions = {
            can_send_messages = false,
            can_send_media_messages = false,
            can_send_polls = false,
            can_send_other_messages = false,
            can_add_web_page_previews = false,
            can_change_info = false,
            can_invite_users = false,
            can_pin_messages = false
        }
        
        local success, result = client.api:restrict_chat_member(chat.id, target_user.id, permissions)
        
        if success then
            client:send_message(chat.id, string.format(
                "🔇 User %s has been muted.",
                target_user.first_name or "Unknown"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("Admin %s muted user %s (%d) in chat %d",
                user.first_name, target_user.first_name or "Unknown", target_user.id, chat.id))
        else
            client:send_message(chat.id, "❌ Failed to mute user: " .. (result.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /unmute command
    client:on_message(luagram.filters.command("unmute"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local args = {}
        for arg in text:gmatch("/unmute%s+(.*)") do
            for word in arg:gmatch("%S+") do
                table.insert(args, word)
            end
        end
        
        local target_user = get_target_user(message, args)
        
        if not target_user then
            client:send_message(chat.id,
                "ℹ️ Usage: Reply to a message or use `/unmute <user_id>`", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- Restore permissions
        local permissions = {
            can_send_messages = true,
            can_send_media_messages = true,
            can_send_polls = true,
            can_send_other_messages = true,
            can_add_web_page_previews = true,
            can_change_info = false,
            can_invite_users = false,
            can_pin_messages = false
        }
        
        local success, result = client.api:restrict_chat_member(chat.id, target_user.id, permissions)
        
        if success then
            client:send_message(chat.id, string.format(
                "🔊 User %s has been unmuted.",
                target_user.first_name or "Unknown"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("Admin %s unmuted user %s (%d) in chat %d",
                user.first_name, target_user.first_name or "Unknown", target_user.id, chat.id))
        else
            client:send_message(chat.id, "❌ Failed to unmute user: " .. (result.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /promote command
    client:on_message(luagram.filters.command("promote"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local text = message.text
        local args = {}
        for arg in text:gmatch("/promote%s+(.*)") do
            for word in arg:gmatch("%S+") do
                table.insert(args, word)
            end
        end
        
        local target_user = get_target_user(message, args)
        
        if not target_user then
            client:send_message(chat.id,
                "ℹ️ Usage: Reply to a message or use `/promote <user_id>`", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local admin_rights = {
            can_change_info = true,
            can_delete_messages = true,
            can_invite_users = true,
            can_restrict_members = true,
            can_pin_messages = true,
            can_promote_members = false
        }
        
        local success, result = client.api:promote_chat_member(chat.id, target_user.id, admin_rights)
        
        if success then
            client:send_message(chat.id, string.format(
                "⭐ User %s has been promoted to administrator.",
                target_user.first_name or "Unknown"
            ), {
                reply_to_message_id = message.message_id
            })
            
            print(string.format("Admin %s promoted user %s (%d) in chat %d",
                user.first_name, target_user.first_name or "Unknown", target_user.id, chat.id))
        else
            client:send_message(chat.id, "❌ Failed to promote user: " .. (result.description or "Unknown error"), {
                reply_to_message_id = message.message_id
            })
        end
    end)
    
    -- Handle /admins command
    client:on_message(luagram.filters.command("admins"), function(client, message)
        local chat = message.chat
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        -- This would require getChatAdministrators API call
        -- For now, show configured bot admins
        local admin_list = "*🛡️ Bot Administrators:*\n\n"
        
        for i, admin_id in ipairs(config.ADMIN_IDS) do
            admin_list = admin_list .. string.format("%d. User ID: `%d`\n", i, admin_id)
        end
        
        admin_list = admin_list .. "\n_Note: These are bot administrators. Chat administrators may differ._"
        
        client:send_message(chat.id, admin_list, {
            reply_to_message_id = message.message_id
        })
    end)
    
    -- Handle /purge command
    client:on_message(luagram.filters.command("purge"), function(client, message)
        if not config.FEATURES.enable_admin_commands then
            return
        end
        
        local user = message.from
        local chat = message.chat
        
        if not is_admin(user.id) and not is_chat_admin(client, chat.id, user.id) then
            client:send_message(chat.id, "❌ You don't have permission to use this command.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if chat.type == "private" then
            client:send_message(chat.id, "❌ This command only works in groups.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        if not message.reply_to_message then
            client:send_message(chat.id, "ℹ️ Reply to a message to purge from that point.", {
                reply_to_message_id = message.message_id
            })
            return
        end
        
        local start_message_id = message.reply_to_message.message_id
        local end_message_id = message.message_id
        local deleted_count = 0
        
        -- Delete messages in range (limited to prevent API flooding)
        local max_delete = 100
        for i = start_message_id, math.min(end_message_id, start_message_id + max_delete) do
            local success, result = client.api:delete_message(chat.id, i)
            if success then
                deleted_count = deleted_count + 1
            end
        end
        
        -- Send temporary status message
        local status_msg = client:send_message(chat.id, string.format(
            "🧹 Purged %d messages.", deleted_count
        ))
        
        -- Delete status message after 5 seconds
        local socket = require("socket")
        socket.sleep(5)
        if status_msg then
            client:delete_message(chat.id, status_msg.message_id)
        end
        
        print(string.format("Admin %s purged %d messages in chat %d",
            user.first_name, deleted_count, chat.id))
    end)
    
    print("Admin plugin loaded successfully")
end

return plugin
