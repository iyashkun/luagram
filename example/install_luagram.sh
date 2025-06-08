#!/bin/bash

# Installation script for Luagram library
# This script installs Luagram from the parent directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Installing Luagram for Example Bot..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUAGRAM_DIR="$(dirname "$SCRIPT_DIR")"

print_status "Script directory: $SCRIPT_DIR"
print_status "Luagram directory: $LUAGRAM_DIR"

# Check if we're in the right place
if [ ! -f "$LUAGRAM_DIR/luagram/init.lua" ]; then
    print_error "Luagram source not found at $LUAGRAM_DIR/luagram/"
    print_error "Please ensure this script is in the example_bot directory"
    print_error "and that the luagram directory exists in the parent directory"
    exit 1
fi

print_success "Found Luagram source at $LUAGRAM_DIR/luagram/"

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    print_error "Lua is not installed!"
    echo ""
    echo "Please install Lua first:"
    echo "  Ubuntu/Debian: sudo apt-get install lua5.3"
    echo "  CentOS/RHEL: sudo yum install lua"
    echo "  macOS: brew install lua"
    exit 1
fi

print_success "Lua found: $(lua -v 2>&1 | head -n1)"

# Check if LuaRocks is available (optional)
if command -v luarocks &> /dev/null; then
    print_success "LuaRocks found: $(luarocks --version 2>&1 | head -n1)"
    HAVE_LUAROCKS=true
else
    print_warning "LuaRocks not found - will use manual installation"
    HAVE_LUAROCKS=false
fi

# Install dependencies
print_status "Installing dependencies..."

install_dependency() {
    local module=$1
    local package=$2
    
    if lua -e "require('$module')" 2>/dev/null; then
        print_success "$module is already installed"
        return 0
    fi
    
    if [ "$HAVE_LUAROCKS" = true ]; then
        print_status "Installing $package via LuaRocks..."
        if luarocks install "$package"; then
            print_success "Installed $package"
            return 0
        else
            print_error "Failed to install $package via LuaRocks"
            return 1
        fi
    else
        print_error "$module is not available and LuaRocks is not installed"
        echo "Please install $package manually or install LuaRocks"
        return 1
    fi
}

# Install required dependencies
deps_ok=true

if ! install_dependency "socket" "luasocket"; then
    deps_ok=false
fi

# Skip SSL dependency as we have our own HTTP client
print_status "Skipping luasec (using built-in HTTP client)"

# Skip JSON dependency as we have our own implementation
print_status "Skipping lua-cjson (using built-in JSON parser)"

# Even if socket fails, we can continue with manual installation
if [ "$deps_ok" = false ]; then
    print_warning "Some dependencies failed to install, but continuing with manual setup"
fi

# Install Luagram
print_status "Installing Luagram..."

if [ "$HAVE_LUAROCKS" = true ] && [ -f "$LUAGRAM_DIR/luagram-scm-1.rockspec" ]; then
    # Install via LuaRocks
    print_status "Installing Luagram via LuaRocks..."
    cd "$LUAGRAM_DIR"
    
    if luarocks make luagram-scm-1.rockspec; then
        print_success "Luagram installed via LuaRocks"
        LUAGRAM_INSTALLED=true
    else
        print_warning "LuaRocks installation failed, trying manual installation..."
        LUAGRAM_INSTALLED=false
    fi
    
    cd "$SCRIPT_DIR"
else
    LUAGRAM_INSTALLED=false
fi

if [ "$LUAGRAM_INSTALLED" = false ]; then
    # Manual installation - create symlink or copy
    print_status "Installing Luagram manually..."
    
    # Create local luagram directory
    if [ -d "luagram" ]; then
        print_status "Removing existing luagram directory..."
        rm -rf luagram
    fi
    
    # Create symlink if possible, otherwise copy
    if ln -sf "$LUAGRAM_DIR/luagram" . 2>/dev/null; then
        print_success "Created symlink to Luagram source"
    else
        print_status "Symlink failed, copying Luagram source..."
        cp -r "$LUAGRAM_DIR/luagram" .
        print_success "Copied Luagram source to local directory"
    fi
fi

# Test Luagram installation
print_status "Testing Luagram installation..."

if lua -e "require('luagram'); print('Luagram loaded successfully')" 2>/dev/null; then
    print_success "Luagram installation test passed"
else
    # Try with local path
    export LUA_PATH="./?.lua;$LUA_PATH"
    if lua -e "require('luagram'); print('Luagram loaded successfully')" 2>/dev/null; then
        print_success "Luagram installation test passed (using local path)"
        
        # Create a shell script to set the path
        cat > set_lua_path.sh << 'EOF'
#!/bin/bash
export LUA_PATH="./?.lua;$LUA_PATH"
EOF
        chmod +x set_lua_path.sh
        print_status "Created set_lua_path.sh to set LUA_PATH"
        
    else
        print_error "Luagram installation test failed"
        echo ""
        echo "Troubleshooting:"
        echo "1. Check if all dependencies are installed correctly"
        echo "2. Verify Luagram source files are present"
        echo "3. Try running: export LUA_PATH=\"./?.lua;\$LUA_PATH\""
        exit 1
    fi
fi

# Create example configuration if it doesn't exist
if [ ! -f "config.lua" ]; then
    print_warning "config.lua not found, this should have been created already"
fi

print_success "Luagram installation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Set your bot token: export BOT_TOKEN='your_bot_token_here'"
echo "2. Or edit config.lua and replace YOUR_BOT_TOKEN_HERE"
echo "3. Run the bot: bash run.sh"
echo ""
echo "For debug mode: bash run.sh --debug"
echo "For background mode: bash run.sh"
