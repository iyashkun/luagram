-- Luagram Handlers - Event handler system
local handlers = {}

-- Handler decorator functions
function handlers.on_message(filter, func)
    return function(client)
        client:on_message(filter, func)
    end
end

function handlers.on_callback_query(filter, func)
    return function(client)
        client:on_callback_query(filter, func)
    end
end

function handlers.on_inline_query(filter, func)
    return function(client)
        client:on_inline_query(filter, func)
    end
end

function handlers.on_edited_message(filter, func)
    return function(client)
        client:on_edited_message(filter, func)
    end
end

-- Handler class for more complex handler management
local Handler = {}
Handler.__index = Handler

function Handler.new()
    local self = setmetatable({}, Handler)
    self.handlers = {
        message = {},
        callback_query = {},
        inline_query = {},
        edited_message = {}
    }
    return self
end

function Handler:add_message_handler(filter, func, group)
    group = group or 0
    if not self.handlers.message[group] then
        self.handlers.message[group] = {}
    end
    
    table.insert(self.handlers.message[group], {
        filter = filter,
        func = func
    })
end

function Handler:add_callback_query_handler(filter, func, group)
    group = group or 0
    if not self.handlers.callback_query[group] then
        self.handlers.callback_query[group] = {}
    end
    
    table.insert(self.handlers.callback_query[group], {
        filter = filter,
        func = func
    })
end

function Handler:add_inline_query_handler(filter, func, group)
    group = group or 0
    if not self.handlers.inline_query[group] then
        self.handlers.inline_query[group] = {}
    end
    
    table.insert(self.handlers.inline_query[group], {
        filter = filter,
        func = func
    })
end

function Handler:add_edited_message_handler(filter, func, group)
    group = group or 0
    if not self.handlers.edited_message[group] then
        self.handlers.edited_message[group] = {}
    end
    
    table.insert(self.handlers.edited_message[group], {
        filter = filter,
        func = func
    })
end

function Handler:process_message(client, message)
    -- Process handlers in group order
    local groups = {}
    for group, _ in pairs(self.handlers.message) do
        table.insert(groups, group)
    end
    table.sort(groups)
    
    for _, group in ipairs(groups) do
        for _, handler in ipairs(self.handlers.message[group] or {}) do
            if handler.filter == nil or handler.filter(message) then
                local success, result = pcall(handler.func, client, message)
                if not success then
                    print("Error in message handler: " .. tostring(result))
                end
                
                -- Stop processing if handler returns false
                if result == false then
                    return
                end
            end
        end
    end
end

function Handler:process_callback_query(client, callback_query)
    local groups = {}
    for group, _ in pairs(self.handlers.callback_query) do
        table.insert(groups, group)
    end
    table.sort(groups)
    
    for _, group in ipairs(groups) do
        for _, handler in ipairs(self.handlers.callback_query[group] or {}) do
            if handler.filter == nil or handler.filter(callback_query) then
                local success, result = pcall(handler.func, client, callback_query)
                if not success then
                    print("Error in callback query handler: " .. tostring(result))
                end
                
                if result == false then
                    return
                end
            end
        end
    end
end

function Handler:process_inline_query(client, inline_query)
    local groups = {}
    for group, _ in pairs(self.handlers.inline_query) do
        table.insert(groups, group)
    end
    table.sort(groups)
    
    for _, group in ipairs(groups) do
        for _, handler in ipairs(self.handlers.inline_query[group] or {}) do
            if handler.filter == nil or handler.filter(inline_query) then
                local success, result = pcall(handler.func, client, inline_query)
                if not success then
                    print("Error in inline query handler: " .. tostring(result))
                end
                
                if result == false then
                    return
                end
            end
        end
    end
end

function Handler:process_edited_message(client, message)
    local groups = {}
    for group, _ in pairs(self.handlers.edited_message) do
        table.insert(groups, group)
    end
    table.sort(groups)
    
    for _, group in ipairs(groups) do
        for _, handler in ipairs(self.handlers.edited_message[group] or {}) do
            if handler.filter == nil or handler.filter(message) then
                local success, result = pcall(handler.func, client, message)
                if not success then
                    print("Error in edited message handler: " .. tostring(result))
                end
                
                if result == false then
                    return
                end
            end
        end
    end
end

handlers.Handler = Handler
handlers.new = Handler.new

return handlers
