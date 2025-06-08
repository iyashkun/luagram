# Luagram Examples

This document provides comprehensive examples of using Luagram to create Telegram bots. From basic functionality to advanced features, these examples will help you build powerful bots.

## Table of Contents

- [Basic Examples](#basic-examples)
- [Message Handling](#message-handling)
- [Interactive Elements](#interactive-elements)
- [File Operations](#file-operations)
- [Admin Commands](#admin-commands)
- [Advanced Features](#advanced-features)
- [Plugin Development](#plugin-development)
- [Best Practices](#best-practices)

## Basic Examples

### A Simple Luagram Bot

The simplest possible bot that responds to the `/start` command:

```lua
local luagram = require("luagram")

-- Create the bot client
local bot = luagram.Client.new(os.getenv("BOT_TOKEN"))

-- Handle /start command
bot:on_message(luagram.filters.command("start"), function(client, message)
    client:send_message(message.chat.id, "Hello, welcome to luagram!")
end)

-- Start the bot
bot:start()
