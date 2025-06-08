# Luagram API Documentation

Luagram is a comprehensive Telegram Bot API wrapper for Lua that mirrors Pyrogram's functionality. This document covers the complete API reference.

## Table of Contents

- [Client](#client)
- [Types](#types)
- [Filters](#filters)
- [Handlers](#handlers)
- [API Methods](#api-methods)
- [File Operations](#file-operations)
- [Error Handling](#error-handling)

## Client

The `Client` class is the main interface for interacting with the Telegram Bot API.

### Constructor

```lua
local luagram = require("luagram")
local bot = luagram.Client.new(bot_token, options)
