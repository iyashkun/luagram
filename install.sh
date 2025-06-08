#!/bin/bash

# Luagram Installation Script
# This script installs Luagram and its dependencies

set -e

echo "Installing Luagram - Telegram Bot API Library for Lua"
echo "=================================================="

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    echo "Error: Lua is not installed. Please install Lua 5.1 or higher."
    exit 1
fi

echo "✓ Lua found: $(lua -v)"

# Check if LuaRocks is installed
if ! command -v luarocks &> /dev/null; then
    echo "Error: LuaRocks is not installed. Please install LuaRocks."
    exit 1
fi

echo "✓ LuaRocks found: $(luarocks --version | head -n1)"

# Install dependencies
echo ""
echo "Installing dependencies..."

# Install luasocket
if ! luarocks show luasocket &> /dev/null; then
    echo "Installing luasocket..."
    luarocks install luasocket
else
    echo "✓ luasocket already installed"
fi

# Install luasec
if ! luarocks show luasec &> /dev/null; then
    echo "Installing luasec..."
    luarocks install luasec
else
    echo "✓ luasec already installed"
fi

# Install lua-cjson
if ! luarocks show lua-cjson &> /dev/null; then
    echo "Installing lua-cjson..."
    luarocks install lua-cjson
else
    echo "✓ lua-cjson already installed"
fi

# Install Luagram
echo ""
echo "Installing Luagram..."

if [ -f "luagram-scm-1.rockspec" ]; then
    # Local installation
    luarocks make luagram-scm-1.rockspec
    echo "✓ Luagram installed from local source"
else
    # Remote installation (if published)
    luarocks install luagram
    echo "✓ Luagram installed from LuaRocks"
fi

echo ""
echo "Installation completed successfully!"
echo ""
echo "You can now use Luagram in your projects:"
echo 'local luagram = require("luagram")'
echo ""
echo "Check out the examples in the example/ directory to get started."
echo ""
echo "Documentation is available in the docs/ directory."
