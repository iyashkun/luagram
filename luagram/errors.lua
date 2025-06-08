-- Luagram Errors - Error handling and custom exceptions
local errors = {}

-- Base error class
local LuagramError = {}
LuagramError.__index = LuagramError

function LuagramError.new(message, error_code)
    local self = setmetatable({}, LuagramError)
    self.message = message or "Unknown error"
    self.error_code = error_code
    return self
end

function LuagramError:__tostring()
    if self.error_code then
        return string.format("LuagramError [%s]: %s", self.error_code, self.message)
    else
        return string.format("LuagramError: %s", self.message)
    end
end

-- Telegram API error
local TelegramError = setmetatable({}, {__index = LuagramError})
TelegramError.__index = TelegramError

function TelegramError.new(message, error_code)
    local self = setmetatable(LuagramError.new(message, error_code), TelegramError)
    return self
end

function TelegramError:__tostring()
    if self.error_code then
        return string.format("TelegramError [%s]: %s", self.error_code, self.message)
    else
        return string.format("TelegramError: %s", self.message)
    end
end

-- Network error
local NetworkError = setmetatable({}, {__index = LuagramError})
NetworkError.__index = NetworkError

function NetworkError.new(message, error_code)
    local self = setmetatable(LuagramError.new(message, error_code), NetworkError)
    return self
end

function NetworkError:__tostring()
    return string.format("NetworkError: %s", self.message)
end

-- Authentication error
local AuthenticationError = setmetatable({}, {__index = TelegramError})
AuthenticationError.__index = AuthenticationError

function AuthenticationError.new(message)
    local self = setmetatable(TelegramError.new(message, 401), AuthenticationError)
    return self
end

function AuthenticationError:__tostring()
    return string.format("AuthenticationError: %s", self.message)
end

-- Bad request error
local BadRequestError = setmetatable({}, {__index = TelegramError})
BadRequestError.__index = BadRequestError

function BadRequestError.new(message)
    local self = setmetatable(TelegramError.new(message, 400), BadRequestError)
    return self
end

function BadRequestError:__tostring()
    return string.format("BadRequestError: %s", self.message)
end

-- Forbidden error
local ForbiddenError = setmetatable({}, {__index = TelegramError})
ForbiddenError.__index = ForbiddenError

function ForbiddenError.new(message)
    local self = setmetatable(TelegramError.new(message, 403), ForbiddenError)
    return self
end

function ForbiddenError:__tostring()
    return string.format("ForbiddenError: %s", self.message)
end

-- Not found error
local NotFoundError = setmetatable({}, {__index = TelegramError})
NotFoundError.__index = NotFoundError

function NotFoundError.new(message)
    local self = setmetatable(TelegramError.new(message, 404), NotFoundError)
    return self
end

function NotFoundError:__tostring()
    return string.format("NotFoundError: %s", self.message)
end

-- Rate limit error
local RateLimitError = setmetatable({}, {__index = TelegramError})
RateLimitError.__index = RateLimitError

function RateLimitError.new(message, retry_after)
    local self = setmetatable(TelegramError.new(message, 429), RateLimitError)
    self.retry_after = retry_after
    return self
end

function RateLimitError:__tostring()
    local msg = string.format("RateLimitError: %s", self.message)
    if self.retry_after then
        msg = msg .. string.format(" (retry after %d seconds)", self.retry_after)
    end
    return msg
end

-- Internal server error
local InternalServerError = setmetatable({}, {__index = TelegramError})
InternalServerError.__index = InternalServerError

function InternalServerError.new(message)
    local self = setmetatable(TelegramError.new(message, 500), InternalServerError)
    return self
end

function InternalServerError:__tostring()
    return string.format("InternalServerError: %s", self.message)
end

-- Session error
local SessionError = setmetatable({}, {__index = LuagramError})
SessionError.__index = SessionError

function SessionError.new(message)
    local self = setmetatable(LuagramError.new(message), SessionError)
    return self
end

function SessionError:__tostring()
    return string.format("SessionError: %s", self.message)
end

-- File error
local FileError = setmetatable({}, {__index = LuagramError})
FileError.__index = FileError

function FileError.new(message)
    local self = setmetatable(LuagramError.new(message), FileError)
    return self
end

function FileError:__tostring()
    return string.format("FileError: %s", self.message)
end

-- Error handler function
function errors.handle_api_error(response)
    if not response or not response.description then
        return TelegramError.new("Unknown API error")
    end
    
    local error_code = response.error_code
    local description = response.description
    
    -- Map error codes to specific error types
    if error_code == 400 then
        return BadRequestError.new(description)
    elseif error_code == 401 then
        return AuthenticationError.new(description)
    elseif error_code == 403 then
        return ForbiddenError.new(description)
    elseif error_code == 404 then
        return NotFoundError.new(description)
    elseif error_code == 429 then
        local retry_after = response.parameters and response.parameters.retry_after
        return RateLimitError.new(description, retry_after)
    elseif error_code == 500 then
        return InternalServerError.new(description)
    else
        return TelegramError.new(description, error_code)
    end
end

-- Export error classes
errors.LuagramError = LuagramError
errors.TelegramError = TelegramError
errors.NetworkError = NetworkError
errors.AuthenticationError = AuthenticationError
errors.BadRequestError = BadRequestError
errors.ForbiddenError = ForbiddenError
errors.NotFoundError = NotFoundError
errors.RateLimitError = RateLimitError
errors.InternalServerError = InternalServerError
errors.SessionError = SessionError
errors.FileError = FileError

return errors
