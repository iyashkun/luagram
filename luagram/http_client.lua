-- Luagram HTTP Client - Simple HTTP client without external SSL dependencies
local socket = require("luagram.simple_socket")

local HttpClient = {}
HttpClient.__index = HttpClient

function HttpClient.new()
    local self = setmetatable({}, HttpClient)
    return self
end

-- Simple HTTP request function
function HttpClient:request(method, url, headers, body)
    local protocol, host, port, path = self:parse_url(url)
    
    if not host then
        return false, "Invalid URL"
    end
    
    -- Default ports
    if not port then
        port = (protocol == "https") and 443 or 80
    end
    
    -- Create socket connection
    local sock = socket.tcp()
    sock:settimeout(30)
    
    local success, err = sock:connect(host, port)
    if not success then
        sock:close()
        return false, "Connection failed: " .. (err or "Unknown error")
    end
    
    -- Build HTTP request
    local request = self:build_request(method, path, host, headers, body)
    
    -- Send request
    local sent, err = sock:send(request)
    if not sent then
        sock:close()
        return false, "Send failed: " .. (err or "Unknown error")
    end
    
    -- Read response
    local response = ""
    while true do
        local data, err, partial = sock:receive("*l")
        if data then
            response = response .. data .. "\n"
            if data == "" then -- End of headers
                break
            end
        elseif err == "closed" then
            break
        elseif partial then
            response = response .. partial
        else
            sock:close()
            return false, "Receive failed: " .. (err or "Unknown error")
        end
    end
    
    -- Parse headers to get content length
    local content_length = response:match("Content%-Length:%s*(%d+)")
    if content_length then
        content_length = tonumber(content_length)
        local body_data = ""
        while #body_data < content_length do
            local data, err = sock:receive(content_length - #body_data)
            if data then
                body_data = body_data .. data
            else
                break
            end
        end
        response = response .. body_data
    else
        -- Read until connection closes
        while true do
            local data, err = sock:receive("*a")
            if data and #data > 0 then
                response = response .. data
            else
                break
            end
        end
    end
    
    sock:close()
    
    -- Parse response
    local status_line = response:match("^HTTP/[%d%.]+%s+(%d+)")
    local status_code = tonumber(status_line)
    local body_start = response:find("\r?\n\r?\n")
    local body = body_start and response:sub(body_start + 2) or ""
    
    return true, {
        status = status_code,
        body = body,
        headers = self:parse_response_headers(response)
    }
end

function HttpClient:parse_url(url)
    local protocol, host, port, path = url:match("^(https?)://([^:/]+):?(%d*)(.*)$")
    if not protocol then
        return nil
    end
    
    port = port and tonumber(port) or nil
    path = path == "" and "/" or path
    
    return protocol, host, port, path
end

function HttpClient:build_request(method, path, host, headers, body)
    headers = headers or {}
    body = body or ""
    
    local request_lines = {
        string.format("%s %s HTTP/1.1", method, path),
        string.format("Host: %s", host),
        "User-Agent: Luagram/1.0",
        "Connection: close"
    }
    
    -- Add custom headers
    for key, value in pairs(headers) do
        table.insert(request_lines, string.format("%s: %s", key, value))
    end
    
    -- Add content length if body exists
    if body and #body > 0 then
        table.insert(request_lines, string.format("Content-Length: %d", #body))
    end
    
    -- End of headers
    table.insert(request_lines, "")
    
    -- Add body
    if body and #body > 0 then
        table.insert(request_lines, body)
    end
    
    return table.concat(request_lines, "\r\n")
end

function HttpClient:parse_response_headers(response)
    local headers = {}
    for line in response:gmatch("([^\r\n]+)") do
        local key, value = line:match("^([^:]+):%s*(.+)$")
        if key and value then
            headers[key:lower()] = value
        end
    end
    return headers
end

return HttpClient
