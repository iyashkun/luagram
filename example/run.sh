#!/bin/bash

# Run script for Luagram Example Bot
# This script starts the bot with proper error handling and logging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_status "Starting Luagram Example Bot..."

# Check if bot token is set
if [ -z "$BOT_TOKEN" ]; then
    print_warning "BOT_TOKEN environment variable not set"
    print_status "Checking config.lua for bot token..."
    
    if grep -q "YOUR_BOT_TOKEN_HERE" config.lua; then
        print_error "Bot token not configured!"
        echo ""
        echo "Please set your bot token in one of these ways:"
        echo "1. Set environment variable: export BOT_TOKEN='your_bot_token_here'"
        echo "2. Edit config.lua and replace YOUR_BOT_TOKEN_HERE with your actual token"
        echo ""
        echo "To get a bot token:"
        echo "1. Message @BotFather on Telegram"
        echo "2. Send /newbot command"
        echo "3. Follow the instructions to create your bot"
        echo "4. Copy the token and use it here"
        exit 1
    fi
else
    print_success "Bot token found in environment variable"
fi

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    print_error "Lua is not installed!"
    echo ""
    echo "Please install Lua:"
    echo "  Ubuntu/Debian: sudo apt-get install lua5.3"
    echo "  CentOS/RHEL: sudo yum install lua"
    echo "  macOS: brew install lua"
    exit 1
fi

print_success "Lua found: $(lua -v 2>&1 | head -n1)"

# Check if required Lua modules are available
print_status "Checking required Lua modules..."

check_lua_module() {
    local module=$1
    if lua -e "require('$module')" 2>/dev/null; then
        print_success "Module '$module' is available"
        return 0
    else
        print_error "Module '$module' is not available"
        return 1
    fi
}

modules_ok=true

if ! check_lua_module "socket"; then
    modules_ok=false
fi

if ! check_lua_module "ssl"; then
    modules_ok=false
fi

if ! check_lua_module "cjson"; then
    modules_ok=false
fi

if ! check_lua_module "luagram"; then
    print_warning "Luagram module not found in system path"
    print_status "Trying to install Luagram..."
    
    if [ -f "install_luagram.sh" ]; then
        bash install_luagram.sh
        if ! check_lua_module "luagram"; then
            modules_ok=false
        fi
    else
        print_error "install_luagram.sh not found"
        modules_ok=false
    fi
fi

if [ "$modules_ok" = false ]; then
    print_error "Some required modules are missing!"
    echo ""
    echo "Please install missing modules:"
    echo "  luarocks install luasocket"
    echo "  luarocks install luasec"
    echo "  luarocks install lua-cjson"
    echo ""
    echo "For Luagram, run: bash install_luagram.sh"
    exit 1
fi

# Check if bot.lua exists
if [ ! -f "bot.lua" ]; then
    print_error "bot.lua not found in current directory"
    exit 1
fi

# Create logs directory if it doesn't exist
if [ ! -d "logs" ]; then
    mkdir -p logs
    print_status "Created logs directory"
fi

# Set log file with timestamp
LOG_FILE="logs/bot_$(date '+%Y%m%d_%H%M%S').log"

# Function to handle cleanup
cleanup() {
    print_warning "Received interrupt signal, shutting down bot..."
    if [ ! -z "$BOT_PID" ]; then
        kill $BOT_PID 2>/dev/null || true
        wait $BOT_PID 2>/dev/null || true
    fi
    print_success "Bot shutdown complete"
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Export environment variables
export LUA_PATH="./?.lua;$LUA_PATH"

print_status "Starting bot with logging to $LOG_FILE"
print_status "Press Ctrl+C to stop the bot"
echo ""

# Start the bot
if [ "$1" = "--debug" ]; then
    print_status "Running in debug mode (output to console)"
    lua bot.lua
else
    print_status "Running in background mode (check logs for output)"
    lua bot.lua > "$LOG_FILE" 2>&1 &
    BOT_PID=$!
    
    print_success "Bot started with PID: $BOT_PID"
    print_status "Log file: $LOG_FILE"
    print_status "To view logs in real-time: tail -f $LOG_FILE"
    
    wait $BOT_PID
fi

print_success "Bot process ended"
