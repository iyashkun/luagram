# Luagram - Telegram Bot API Library for Lua

Luagram is a comprehensive Telegram Bot API wrapper for Lua, inspired by Pyrogram. It provides all the functionality needed to create powerful Telegram bots with a clean and intuitive API.

## Features

- **Pyrogram-inspired Design**: Familiar API for Pyrogram users
- **Event Handling**: Robust event handling system with filters
- **File Operations**: Upload and download files with ease
- **Session Management**: Persistent session storage
- **Plugin System**: Extensible plugin architecture
- **Error Handling**: Comprehensive error handling and logging
- **Type Safety**: Full type definitions for all Telegram objects

## Installation

### Via Git (Recommended)

```bash
--Install dependencies first
luarocks install luasocket
luarocks install luasec
luarocks install lua-cjson

--Install Luagram from Git
git clone https://github.com/iYashKun/luagram.git
cd luagram
luarocks make
