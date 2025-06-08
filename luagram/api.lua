-- Luagram API - Telegram Bot API wrapper
local http_client = require("luagram.http_client")

-- Try to load cjson, fallback to our JSON implementation
local json
local success = pcall(function() json = require("cjson") end)
if not success then
    json = require("luagram.json")
end

local API = {}
API.__index = API

function API.new(api_url, bot_token)
    local self = setmetatable({}, API)
    self.api_url = api_url
    self.bot_token = bot_token
    self.base_url = string.format("%s/bot%s", api_url, bot_token)
    self.http = http_client.new()
    return self
end

-- Make HTTP request to Telegram API
function API:request(method, data, files)
    local url = self.base_url .. "/" .. method
    local body = ""
    local headers = {}
    
    if files and next(files) then
        -- Multipart form data for file uploads
        local boundary = "----luagram" .. tostring(os.time())
        headers["Content-Type"] = "multipart/form-data; boundary=" .. boundary
        
        body = self:build_multipart_body(data, files, boundary)
    else
        -- JSON data
        headers["Content-Type"] = "application/json"
        if data and next(data) then
            body = json.encode(data)
        end
    end
    
    -- Make HTTP request using our simple client
    local success, response = self.http:request("POST", url, headers, body)
    
    if not success then
        return false, {description = "Network error: " .. tostring(response)}
    end
    
    if response.status ~= 200 then
        return false, {description = "HTTP error: " .. tostring(response.status)}
    end
    
    local success_decode, response_data = pcall(json.decode, response.body)
    
    if not success_decode then
        return false, {description = "Invalid JSON response"}
    end
    
    if response_data.ok then
        return true, response_data.result
    else
        return false, response_data
    end
end

-- Build multipart form data body
function API:build_multipart_body(data, files, boundary)
    local parts = {}
    
    -- Add regular form fields
    if data then
        for key, value in pairs(data) do
            if type(value) == "table" then
                value = json.encode(value)
            end
            table.insert(parts, string.format(
                "--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s",
                boundary, key, tostring(value)
            ))
        end
    end
    
    -- Add file fields
    for field_name, file_info in pairs(files) do
        local file_content = file_info.content
        local file_name = file_info.name or "file"
        local mime_type = file_info.mime_type or "application/octet-stream"
        
        table.insert(parts, string.format(
            "--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\nContent-Type: %s\r\n\r\n%s",
            boundary, field_name, file_name, mime_type, file_content
        ))
    end
    
    return table.concat(parts, "\r\n") .. "\r\n--" .. boundary .. "--\r\n"
end

-- API Methods
function API:get_me()
    return self:request("getMe")
end

function API:get_updates(offset, limit, timeout, allowed_updates)
    local data = {}
    if offset then data.offset = offset end
    if limit then data.limit = limit end
    if timeout then data.timeout = timeout end
    if allowed_updates then data.allowed_updates = allowed_updates end
    
    return self:request("getUpdates", data)
end

function API:send_message(data)
    return self:request("sendMessage", data)
end

function API:edit_message_text(data)
    return self:request("editMessageText", data)
end

function API:delete_message(chat_id, message_id)
    local data = {
        chat_id = chat_id,
        message_id = message_id
    }
    return self:request("deleteMessage", data)
end

function API:send_photo(data)
    local files = {}
    if type(data.photo) == "string" and data.photo:sub(1, 1) == "/" then
        -- Local file path
        local file = io.open(data.photo, "rb")
        if file then
            files.photo = {
                content = file:read("*all"),
                name = data.photo:match("([^/]+)$"),
                mime_type = "image/jpeg"
            }
            file:close()
            data.photo = nil
        end
    end
    
    return self:request("sendPhoto", data, files)
end

function API:send_document(data)
    local files = {}
    if type(data.document) == "string" and data.document:sub(1, 1) == "/" then
        -- Local file path
        local file = io.open(data.document, "rb")
        if file then
            files.document = {
                content = file:read("*all"),
                name = data.document:match("([^/]+)$"),
                mime_type = "application/octet-stream"
            }
            file:close()
            data.document = nil
        end
    end
    
    return self:request("sendDocument", data, files)
end

function API:send_audio(data)
    local files = {}
    if type(data.audio) == "string" and data.audio:sub(1, 1) == "/" then
        local file = io.open(data.audio, "rb")
        if file then
            files.audio = {
                content = file:read("*all"),
                name = data.audio:match("([^/]+)$"),
                mime_type = "audio/mpeg"
            }
            file:close()
            data.audio = nil
        end
    end
    
    return self:request("sendAudio", data, files)
end

function API:send_video(data)
    local files = {}
    if type(data.video) == "string" and data.video:sub(1, 1) == "/" then
        local file = io.open(data.video, "rb")
        if file then
            files.video = {
                content = file:read("*all"),
                name = data.video:match("([^/]+)$"),
                mime_type = "video/mp4"
            }
            file:close()
            data.video = nil
        end
    end
    
    return self:request("sendVideo", data, files)
end

function API:answer_callback_query(data)
    return self:request("answerCallbackQuery", data)
end

function API:answer_inline_query(data)
    return self:request("answerInlineQuery", data)
end

function API:get_file(file_id)
    local data = {file_id = file_id}
    return self:request("getFile", data)
end

function API:get_chat(chat_id)
    local data = {chat_id = chat_id}
    return self:request("getChat", data)
end

function API:get_chat_member(chat_id, user_id)
    local data = {
        chat_id = chat_id,
        user_id = user_id
    }
    return self:request("getChatMember", data)
end

function API:kick_chat_member(chat_id, user_id, until_date)
    local data = {
        chat_id = chat_id,
        user_id = user_id
    }
    if until_date then
        data.until_date = until_date
    end
    return self:request("kickChatMember", data)
end

function API:unban_chat_member(chat_id, user_id, only_if_banned)
    local data = {
        chat_id = chat_id,
        user_id = user_id
    }
    if only_if_banned then
        data.only_if_banned = only_if_banned
    end
    return self:request("unbanChatMember", data)
end

function API:restrict_chat_member(chat_id, user_id, permissions, until_date)
    local data = {
        chat_id = chat_id,
        user_id = user_id,
        permissions = permissions
    }
    if until_date then
        data.until_date = until_date
    end
    return self:request("restrictChatMember", data)
end

function API:promote_chat_member(chat_id, user_id, options)
    local data = {
        chat_id = chat_id,
        user_id = user_id
    }
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("promoteChatMember", data)
end

-- Additional API methods from the attached specification

function API:forward_media_group(chat_id, from_chat_id, message_ids, options)
    local data = {
        chat_id = chat_id,
        from_chat_id = from_chat_id,
        message_ids = message_ids
    }
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("forwardMediaGroup", data)
end

function API:forward_messages(chat_id, from_chat_id, message_ids, options)
    local data = {
        chat_id = chat_id,
        from_chat_id = from_chat_id,
        message_ids = message_ids
    }
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("forwardMessages", data)
end

function API:copy_message(chat_id, from_chat_id, message_id, options)
    local data = {
        chat_id = chat_id,
        from_chat_id = from_chat_id,
        message_id = message_id
    }
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("copyMessage", data)
end

function API:copy_media_group(chat_id, from_chat_id, message_id, options)
    local data = {
        chat_id = chat_id,
        from_chat_id = from_chat_id,
        message_id = message_id
    }
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("copyMediaGroup", data)
end

function API:send_sticker(data)
    local files = {}
    if type(data.sticker) == "string" and data.sticker:sub(1, 1) == "/" then
        local file = io.open(data.sticker, "rb")
        if file then
            files.sticker = {
                content = file:read("*all"),
                name = data.sticker:match("([^/]+)$"),
                mime_type = "application/octet-stream"
            }
            file:close()
            data.sticker = nil
        end
    end
    return self:request("sendSticker", data, files)
end

function API:send_animation(data)
    local files = {}
    if type(data.animation) == "string" and data.animation:sub(1, 1) == "/" then
        local file = io.open(data.animation, "rb")
        if file then
            files.animation = {
                content = file:read("*all"),
                name = data.animation:match("([^/]+)$"),
                mime_type = "video/mp4"
            }
            file:close()
            data.animation = nil
        end
    end
    return self:request("sendAnimation", data, files)
end

function API:send_voice(data)
    local files = {}
    if type(data.voice) == "string" and data.voice:sub(1, 1) == "/" then
        local file = io.open(data.voice, "rb")
        if file then
            files.voice = {
                content = file:read("*all"),
                name = data.voice:match("([^/]+)$"),
                mime_type = "audio/ogg"
            }
            file:close()
            data.voice = nil
        end
    end
    return self:request("sendVoice", data, files)
end

function API:send_location(data)
    return self:request("sendLocation", data)
end

function API:edit_message_caption(data)
    return self:request("editMessageCaption", data)
end

function API:edit_message_media(data)
    return self:request("editMessageMedia", data)
end

function API:edit_message_reply_markup(data)
    return self:request("editMessageReplyMarkup", data)
end

function API:send_chat_action(chat_id, action)
    local data = {
        chat_id = chat_id,
        action = action
    }
    return self:request("sendChatAction", data)
end

function API:delete_messages(chat_id, message_ids)
    local data = {
        chat_id = chat_id,
        message_ids = message_ids
    }
    return self:request("deleteMessages", data)
end

function API:set_administrator_title(chat_id, user_id, custom_title)
    local data = {
        chat_id = chat_id,
        user_id = user_id,
        custom_title = custom_title
    }
    return self:request("setChatAdministratorCustomTitle", data)
end

function API:set_chat_photo(data)
    local files = {}
    if type(data.photo) == "string" and data.photo:sub(1, 1) == "/" then
        local file = io.open(data.photo, "rb")
        if file then
            files.photo = {
                content = file:read("*all"),
                name = data.photo:match("([^/]+)$"),
                mime_type = "image/jpeg"
            }
            file:close()
            data.photo = nil
        end
    end
    return self:request("setChatPhoto", data, files)
end

function API:delete_chat_photo(chat_id)
    local data = {chat_id = chat_id}
    return self:request("deleteChatPhoto", data)
end

function API:set_chat_title(chat_id, title)
    local data = {
        chat_id = chat_id,
        title = title
    }
    return self:request("setChatTitle", data)
end

function API:set_chat_description(chat_id, description)
    local data = {
        chat_id = chat_id,
        description = description
    }
    return self:request("setChatDescription", data)
end

function API:set_chat_permissions(chat_id, permissions)
    local data = {
        chat_id = chat_id,
        permissions = permissions
    }
    return self:request("setChatPermissions", data)
end

function API:pin_chat_message(chat_id, message_id, options)
    local data = {
        chat_id = chat_id,
        message_id = message_id
    }
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("pinChatMessage", data)
end

function API:unpin_chat_message(chat_id, message_id)
    local data = {
        chat_id = chat_id,
        message_id = message_id
    }
    return self:request("unpinChatMessage", data)
end

function API:unpin_all_chat_messages(chat_id)
    local data = {chat_id = chat_id}
    return self:request("unpinAllChatMessages", data)
end

function API:get_chat_members_count(chat_id)
    local data = {chat_id = chat_id}
    return self:request("getChatMemberCount", data)
end

function API:get_chat_members(chat_id, offset, limit)
    local data = {
        chat_id = chat_id,
        offset = offset or 0,
        limit = limit or 200
    }
    return self:request("getChatAdministrators", data)
end

function API:get_users(user_ids)
    local data = {user_ids = user_ids}
    return self:request("getUsers", data)
end

function API:export_chat_invite_link(chat_id)
    local data = {chat_id = chat_id}
    return self:request("exportChatInviteLink", data)
end

function API:create_chat_invite_link(chat_id, options)
    local data = {chat_id = chat_id}
    if options then
        for key, value in pairs(options) do
            data[key] = value
        end
    end
    return self:request("createChatInviteLink", data)
end

function API:send_invoice(data)
    return self:request("sendInvoice", data)
end

function API:answer_pre_checkout_query(pre_checkout_query_id, ok, error_message)
    local data = {
        pre_checkout_query_id = pre_checkout_query_id,
        ok = ok
    }
    if error_message then
        data.error_message = error_message
    end
    return self:request("answerPreCheckoutQuery", data)
end

function API:create_invoice_link(data)
    return self:request("createInvoiceLink", data)
end

function API:refund_star_payment(user_id, telegram_payment_charge_id)
    local data = {
        user_id = user_id,
        telegram_payment_charge_id = telegram_payment_charge_id
    }
    return self:request("refundStarPayment", data)
end

return API
