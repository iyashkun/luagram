-- Luagram Utils - Utility functions
local utils = {}

-- String utilities
function utils.split(str, delimiter)
    delimiter = delimiter or "%s"
    local result = {}
    for match in str:gmatch("([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end
    return result
end

function utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

function utils.starts_with(str, prefix)
    return str:sub(1, #prefix) == prefix
end

function utils.ends_with(str, suffix)
    return str:sub(-#suffix) == suffix
end

function utils.escape_markdown(text)
    local special_chars = {"\\", "`", "*", "_", "{", "}", "[", "]", "(", ")", "#", "+", "-", ".", "!", "|"}
    for _, char in ipairs(special_chars) do
        text = text:gsub("%" .. char, "\\" .. char)
    end
    return text
end

function utils.escape_html(text)
    local replacements = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#x27;"
    }
    
    for char, replacement in pairs(replacements) do
        text = text:gsub(char, replacement)
    end
    return text
end

-- Table utilities
function utils.table_length(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function utils.table_keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

function utils.table_values(tbl)
    local values = {}
    for _, value in pairs(tbl) do
        table.insert(values, value)
    end
    return values
end

function utils.table_merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

function utils.table_deep_copy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    
    local copy = {}
    for key, value in pairs(tbl) do
        copy[utils.table_deep_copy(key)] = utils.table_deep_copy(value)
    end
    
    return setmetatable(copy, getmetatable(tbl))
end

-- File utilities
function utils.file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

function utils.read_file(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end
    return nil
end

function utils.write_file(path, content)
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

function utils.get_file_extension(filename)
    return filename:match("%.([^%.]+)$")
end

function utils.get_file_name(path)
    return path:match("([^/\\]+)$")
end

-- Time utilities
function utils.get_timestamp()
    return os.time()
end

function utils.format_time(timestamp, format)
    format = format or "%Y-%m-%d %H:%M:%S"
    return os.date(format, timestamp)
end

function utils.sleep(seconds)
    local socket = require("socket")
    socket.sleep(seconds)
end

-- Validation utilities
function utils.is_valid_chat_id(chat_id)
    return type(chat_id) == "number" or (type(chat_id) == "string" and chat_id:match("^@[%w_]+$"))
end

function utils.is_valid_user_id(user_id)
    return type(user_id) == "number" and user_id > 0
end

function utils.is_valid_message_id(message_id)
    return type(message_id) == "number" and message_id > 0
end

-- URL utilities
function utils.url_encode(str)
    if str then
        str = str:gsub("\n", "\r\n")
        str = str:gsub("([^%w %-%_%.%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = str:gsub(" ", "+")
    end
    return str
end

function utils.url_decode(str)
    if str then
        str = str:gsub("+", " ")
        str = str:gsub("%%(%x%x)", function(h)
            return string.char(tonumber(h, 16))
        end)
        str = str:gsub("\r\n", "\n")
    end
    return str
end

-- Parse utilities
function utils.parse_command(text)
    if not text or text:sub(1, 1) ~= "/" then
        return nil, nil
    end
    
    local parts = utils.split(text, " ")
    local command = parts[1]:sub(2)  -- Remove the '/' prefix
    local args = {}
    
    for i = 2, #parts do
        table.insert(args, parts[i])
    end
    
    return command, args
end

function utils.extract_mentions(text)
    if not text then return {} end
    
    local mentions = {}
    for mention in text:gmatch("@([%w_]+)") do
        table.insert(mentions, mention)
    end
    
    return mentions
end

function utils.extract_hashtags(text)
    if not text then return {} end
    
    local hashtags = {}
    for hashtag in text:gmatch("#([%w_]+)") do
        table.insert(hashtags, hashtag)
    end
    
    return hashtags
end

-- Logging utilities
function utils.log(level, message)
    level = level or "INFO"
    local timestamp = utils.format_time(utils.get_timestamp())
    print(string.format("[%s] %s: %s", timestamp, level, message))
end

function utils.log_info(message)
    utils.log("INFO", message)
end

function utils.log_error(message)
    utils.log("ERROR", message)
end

function utils.log_warning(message)
    utils.log("WARNING", message)
end

function utils.log_debug(message)
    utils.log("DEBUG", message)
end

return utils
