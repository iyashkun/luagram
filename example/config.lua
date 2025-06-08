-- Configuration file for example bot
local config = {}

-- Bot token from environment variable or default
config.BOT_TOKEN = os.getenv("BOT_TOKEN") or "YOUR_BOT_TOKEN_HERE"

-- Admin user IDs
config.ADMIN_IDS = {
    123456789,  -- Replace with actual admin user IDs
    987654321
}

-- Database configuration (if needed)
config.DATABASE = {
    host = os.getenv("DB_HOST") or "localhost",
    port = os.getenv("DB_PORT") or 5432,
    name = os.getenv("DB_NAME") or "telegram_bot",
    user = os.getenv("DB_USER") or "bot_user",
    password = os.getenv("DB_PASSWORD") or "bot_password"
}

-- Bot settings
config.SETTINGS = {
    welcome_message = "Welcome to our group!",
    max_file_size = 50 * 1024 * 1024,  -- 50MB
    allowed_file_types = {"jpg", "png", "pdf", "txt", "zip"},
    rate_limit = {
        messages_per_minute = 20,
        files_per_hour = 5
    }
}

-- Feature flags
config.FEATURES = {
    enable_admin_commands = true,
    enable_file_handling = true,
    enable_inline_queries = false,
    enable_webhooks = false,
    enable_logging = true
}

-- Logging configuration
config.LOGGING = {
    level = os.getenv("LOG_LEVEL") or "INFO",
    file = os.getenv("LOG_FILE") or "bot.log",
    max_size = 10 * 1024 * 1024,  -- 10MB
    backup_count = 5
}

-- Webhook configuration (if using webhooks)
config.WEBHOOK = {
    url = os.getenv("WEBHOOK_URL"),
    port = tonumber(os.getenv("WEBHOOK_PORT")) or 8443,
    cert_path = os.getenv("WEBHOOK_CERT"),
    key_path = os.getenv("WEBHOOK_KEY")
}

-- Custom commands configuration
config.COMMANDS = {
    start = {
        description = "Start the bot",
        usage = "/start",
        admin_only = false
    },
    help = {
        description = "Show help message",
        usage = "/help",
        admin_only = false
    },
    ban = {
        description = "Ban a user",
        usage = "/ban [reply to message]",
        admin_only = true
    },
    unban = {
        description = "Unban a user", 
        usage = "/unban [user_id]",
        admin_only = true
    },
    stats = {
        description = "Show bot statistics",
        usage = "/stats",
        admin_only = true
    }
}

-- Validate configuration
function config.validate()
    if config.BOT_TOKEN == "YOUR_BOT_TOKEN_HERE" then
        error("Please set BOT_TOKEN environment variable or update config.lua")
    end
    
    if #config.ADMIN_IDS == 0 then
        print("Warning: No admin users configured")
    end
    
    return true
end

return config
