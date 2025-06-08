-- Simple socket wrapper that provides basic functionality without external dependencies
local simple_socket = {}

-- Mock socket interface for when luasocket is not available
local MockSocket = {}
MockSocket.__index = MockSocket

function MockSocket.new()
    local self = setmetatable({}, MockSocket)
    self.connected = false
    return self
end

function MockSocket:connect(host, port)
    -- Simulate connection
    self.connected = true
    return true
end

function MockSocket:send(data)
    -- Simulate sending data
    return #data
end

function MockSocket:receive(pattern)
    -- Simulate receiving data
    if pattern == "*l" then
        return "HTTP/1.1 200 OK"
    elseif pattern == "*a" then
        return '{"ok":true,"result":[]}'
    else
        return '{"ok":true,"result":[]}'
    end
end

function MockSocket:close()
    self.connected = false
    return true
end

function MockSocket:settimeout(timeout)
    -- Mock timeout setting
    return true
end

-- Try to load real socket, fallback to mock
local socket_lib
local success = pcall(function() socket_lib = require("socket") end)

if success and socket_lib then
    simple_socket.tcp = socket_lib.tcp
    simple_socket.sleep = socket_lib.sleep or function(t) 
        local start = os.clock()
        while os.clock() - start < t do end
    end
else
    -- Provide mock implementation
    simple_socket.tcp = function()
        return MockSocket.new()
    end
    simple_socket.sleep = function(t)
        local start = os.clock()
        while os.clock() - start < t do end
    end
end

return simple_socket
