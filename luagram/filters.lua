-- Luagram Filters - Message filtering system
local filters = {}

-- Base filter class
local Filter = {}
Filter.__index = Filter

function Filter.new(func)
    local self = setmetatable({}, Filter)
    self.func = func
    return self
end

function Filter:__call(message)
    return self.func(message)
end

-- Combine filters with AND logic
function Filter:__band(other)
    return Filter.new(function(message)
        return self(message) and other(message)
    end)
end

-- Combine filters with OR logic
function Filter:__bor(other)
    return Filter.new(function(message)
        return self(message) or other(message)
    end)
end

-- Negate filter
function Filter:__bnot()
    return Filter.new(function(message)
        return not self(message)
    end)
end

-- Common filters
filters.all = Filter.new(function(message)
    return true
end)

filters.text = Filter.new(function(message)
    return message.text ~= nil
end)

filters.photo = Filter.new(function(message)
    return message.photo ~= nil
end)

filters.video = Filter.new(function(message)
    return message.video ~= nil
end)

filters.audio = Filter.new(function(message)
    return message.audio ~= nil
end)

filters.document = Filter.new(function(message)
    return message.document ~= nil
end)

filters.sticker = Filter.new(function(message)
    return message.sticker ~= nil
end)

filters.voice = Filter.new(function(message)
    return message.voice ~= nil
end)

filters.video_note = Filter.new(function(message)
    return message.video_note ~= nil
end)

filters.location = Filter.new(function(message)
    return message.location ~= nil
end)

filters.contact = Filter.new(function(message)
    return message.contact ~= nil
end)

filters.media = Filter.new(function(message)
    return message.photo or message.video or message.audio or 
           message.document or message.sticker or message.voice or
           message.video_note
end)

filters.forwarded = Filter.new(function(message)
    return message.forward_from or message.forward_from_chat
end)

filters.reply = Filter.new(function(message)
    return message.reply_to_message ~= nil
end)

filters.edited = Filter.new(function(message)
    return message.edit_date ~= nil
end)

filters.private = Filter.new(function(message)
    return message.chat.type == "private"
end)

filters.group = Filter.new(function(message)
    return message.chat.type == "group"
end)

filters.supergroup = Filter.new(function(message)
    return message.chat.type == "supergroup"
end)

filters.channel = Filter.new(function(message)
    return message.chat.type == "channel"
end)

-- Factory functions for dynamic filters
function filters.command(commands)
    commands = type(commands) == "string" and {commands} or commands
    
    return Filter.new(function(message)
        if not message.text then return false end
        
        local text = message.text
        if not text:sub(1, 1) == "/" then return false end
        
        local command = text:match("^/([%w_]+)")
        if not command then return false end
        
        for _, cmd in ipairs(commands) do
            if command == cmd then return true end
        end
        
        return false
    end)
end

function filters.regex(pattern, flags)
    flags = flags or ""
    
    return Filter.new(function(message)
        if not message.text then return false end
        return message.text:match(pattern) ~= nil
    end)
end

function filters.user(user_ids)
    user_ids = type(user_ids) == "number" and {user_ids} or user_ids
    
    return Filter.new(function(message)
        if not message.from then return false end
        
        for _, user_id in ipairs(user_ids) do
            if message.from.id == user_id then return true end
        end
        
        return false
    end)
end

function filters.chat(chat_ids)
    chat_ids = type(chat_ids) == "number" and {chat_ids} or chat_ids
    
    return Filter.new(function(message)
        if not message.chat then return false end
        
        for _, chat_id in ipairs(chat_ids) do
            if message.chat.id == chat_id then return true end
        end
        
        return false
    end)
end

function filters.username(usernames)
    usernames = type(usernames) == "string" and {usernames} or usernames
    
    return Filter.new(function(message)
        if not message.from or not message.from.username then return false end
        
        for _, username in ipairs(usernames) do
            if message.from.username:lower() == username:lower() then return true end
        end
        
        return false
    end)
end

function filters.mention(mentions)
    mentions = type(mentions) == "string" and {mentions} or mentions
    
    return Filter.new(function(message)
        if not message.text then return false end
        
        for _, mention in ipairs(mentions) do
            if message.text:find("@" .. mention) then return true end
        end
        
        return false
    end)
end

function filters.hashtag(hashtags)
    hashtags = type(hashtags) == "string" and {hashtags} or hashtags
    
    return Filter.new(function(message)
        if not message.text then return false end
        
        for _, hashtag in ipairs(hashtags) do
            if message.text:find("#" .. hashtag) then return true end
        end
        
        return false
    end)
end

function filters.service()
    return Filter.new(function(message)
        return message.new_chat_members or message.left_chat_member or
               message.new_chat_title or message.new_chat_photo or
               message.delete_chat_photo or message.group_chat_created or
               message.supergroup_chat_created or message.channel_chat_created or
               message.migrate_to_chat_id or message.migrate_from_chat_id or
               message.pinned_message
    end)
end

-- Custom filter creator
function filters.create_filter(func)
    return Filter.new(func)
end

filters.Filter = Filter
filters.create = filters.create_filter

return filters
