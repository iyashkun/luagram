-- Simple JSON encoder/decoder for Luagram
-- Fallback implementation when lua-cjson is not available

local json = {}

-- JSON encode function
function json.encode(value)
    local function encode_value(val)
        local val_type = type(val)
        
        if val_type == "nil" then
            return "null"
        elseif val_type == "boolean" then
            return val and "true" or "false"
        elseif val_type == "number" then
            return tostring(val)
        elseif val_type == "string" then
            return '"' .. val:gsub('["\\]', '\\%1'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
        elseif val_type == "table" then
            -- Check if it's an array
            local is_array = true
            local max_index = 0
            for k, v in pairs(val) do
                if type(k) ~= "number" or k ~= math.floor(k) or k <= 0 then
                    is_array = false
                    break
                end
                max_index = math.max(max_index, k)
            end
            
            -- Check for consecutive indices starting from 1
            if is_array then
                for i = 1, max_index do
                    if val[i] == nil then
                        is_array = false
                        break
                    end
                end
            end
            
            if is_array then
                -- Encode as array
                local parts = {}
                for i = 1, max_index do
                    table.insert(parts, encode_value(val[i]))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                -- Encode as object
                local parts = {}
                for k, v in pairs(val) do
                    table.insert(parts, encode_value(tostring(k)) .. ":" .. encode_value(v))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        else
            error("Cannot encode value of type " .. val_type)
        end
    end
    
    return encode_value(value)
end

-- JSON decode function
function json.decode(str)
    local pos = 1
    
    local function skip_whitespace()
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end
    
    local function decode_value()
        skip_whitespace()
        
        if pos > #str then
            error("Unexpected end of JSON input")
        end
        
        local char = str:sub(pos, pos)
        
        if char == '"' then
            -- String
            pos = pos + 1
            local start = pos
            while pos <= #str do
                char = str:sub(pos, pos)
                if char == '"' then
                    local result = str:sub(start, pos - 1)
                    pos = pos + 1
                    return result:gsub('\\(.)', function(c)
                        if c == 'n' then return '\n'
                        elseif c == 'r' then return '\r'
                        elseif c == 't' then return '\t'
                        else return c end
                    end)
                elseif char == '\\' then
                    pos = pos + 2
                else
                    pos = pos + 1
                end
            end
            error("Unterminated string")
            
        elseif char == '{' then
            -- Object
            pos = pos + 1
            local result = {}
            skip_whitespace()
            
            if pos <= #str and str:sub(pos, pos) == '}' then
                pos = pos + 1
                return result
            end
            
            while true do
                local key = decode_value()
                skip_whitespace()
                
                if pos > #str or str:sub(pos, pos) ~= ':' then
                    error("Expected ':' after key")
                end
                pos = pos + 1
                
                local value = decode_value()
                result[key] = value
                
                skip_whitespace()
                if pos > #str then
                    error("Expected '}' or ','")
                end
                
                char = str:sub(pos, pos)
                if char == '}' then
                    pos = pos + 1
                    return result
                elseif char == ',' then
                    pos = pos + 1
                else
                    error("Expected '}' or ','")
                end
            end
            
        elseif char == '[' then
            -- Array
            pos = pos + 1
            local result = {}
            skip_whitespace()
            
            if pos <= #str and str:sub(pos, pos) == ']' then
                pos = pos + 1
                return result
            end
            
            while true do
                table.insert(result, decode_value())
                skip_whitespace()
                
                if pos > #str then
                    error("Expected ']' or ','")
                end
                
                char = str:sub(pos, pos)
                if char == ']' then
                    pos = pos + 1
                    return result
                elseif char == ',' then
                    pos = pos + 1
                else
                    error("Expected ']' or ','")
                end
            end
            
        elseif char == 't' then
            -- true
            if str:sub(pos, pos + 3) == "true" then
                pos = pos + 4
                return true
            else
                error("Invalid token")
            end
            
        elseif char == 'f' then
            -- false
            if str:sub(pos, pos + 4) == "false" then
                pos = pos + 5
                return false
            else
                error("Invalid token")
            end
            
        elseif char == 'n' then
            -- null
            if str:sub(pos, pos + 3) == "null" then
                pos = pos + 4
                return nil
            else
                error("Invalid token")
            end
            
        elseif char:match("[%-0-9]") then
            -- Number
            local start = pos
            if char == '-' then
                pos = pos + 1
            end
            
            while pos <= #str and str:sub(pos, pos):match("[0-9]") do
                pos = pos + 1
            end
            
            if pos <= #str and str:sub(pos, pos) == '.' then
                pos = pos + 1
                while pos <= #str and str:sub(pos, pos):match("[0-9]") do
                    pos = pos + 1
                end
            end
            
            if pos <= #str and str:sub(pos, pos):lower() == 'e' then
                pos = pos + 1
                if pos <= #str and str:sub(pos, pos):match("[+-]") then
                    pos = pos + 1
                end
                while pos <= #str and str:sub(pos, pos):match("[0-9]") do
                    pos = pos + 1
                end
            end
            
            local num_str = str:sub(start, pos - 1)
            return tonumber(num_str)
            
        else
            error("Unexpected character: " .. char)
        end
    end
    
    return decode_value()
end

return json
