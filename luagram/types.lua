-- Luagram Types - Telegram Bot API type definitions
local types = {}

-- Base type class
local BaseType = {}
BaseType.__index = BaseType

function BaseType.new(data)
    local self = setmetatable({}, BaseType)
    if data then
        for key, value in pairs(data) do
            self[key] = value
        end
    end
    return self
end

function BaseType.from_dict(data)
    return BaseType.new(data)
end

-- User type
local User = setmetatable({}, {__index = BaseType})
User.__index = User

function User.new(data)
    local self = setmetatable(BaseType.new(data), User)
    return self
end

function User.from_dict(data)
    if not data then return nil end
    return User.new(data)
end

-- Chat type
local Chat = setmetatable({}, {__index = BaseType})
Chat.__index = Chat

function Chat.new(data)
    local self = setmetatable(BaseType.new(data), Chat)
    return self
end

function Chat.from_dict(data)
    if not data then return nil end
    return Chat.new(data)
end

-- Message type
local Message = setmetatable({}, {__index = BaseType})
Message.__index = Message

function Message.new(data)
    local self = setmetatable(BaseType.new(data), Message)
    
    -- Parse nested objects
    if self.from then
        self.from = User.from_dict(self.from)
    end
    if self.chat then
        self.chat = Chat.from_dict(self.chat)
    end
    if self.reply_to_message then
        self.reply_to_message = Message.from_dict(self.reply_to_message)
    end
    if self.forward_from then
        self.forward_from = User.from_dict(self.forward_from)
    end
    if self.forward_from_chat then
        self.forward_from_chat = Chat.from_dict(self.forward_from_chat)
    end
    
    return self
end

function Message.from_dict(data)
    if not data then return nil end
    return Message.new(data)
end

-- CallbackQuery type
local CallbackQuery = setmetatable({}, {__index = BaseType})
CallbackQuery.__index = CallbackQuery

function CallbackQuery.new(data)
    local self = setmetatable(BaseType.new(data), CallbackQuery)
    
    if self.from then
        self.from = User.from_dict(self.from)
    end
    if self.message then
        self.message = Message.from_dict(self.message)
    end
    
    return self
end

function CallbackQuery.from_dict(data)
    if not data then return nil end
    return CallbackQuery.new(data)
end

-- InlineQuery type
local InlineQuery = setmetatable({}, {__index = BaseType})
InlineQuery.__index = InlineQuery

function InlineQuery.new(data)
    local self = setmetatable(BaseType.new(data), InlineQuery)
    
    if self.from then
        self.from = User.from_dict(self.from)
    end
    if self.location then
        self.location = Location.from_dict(self.location)
    end
    
    return self
end

function InlineQuery.from_dict(data)
    if not data then return nil end
    return InlineQuery.new(data)
end

-- Update type
local Update = setmetatable({}, {__index = BaseType})
Update.__index = Update

function Update.new(data)
    local self = setmetatable(BaseType.new(data), Update)
    
    if self.message then
        self.message = Message.from_dict(self.message)
    end
    if self.edited_message then
        self.edited_message = Message.from_dict(self.edited_message)
    end
    if self.callback_query then
        self.callback_query = CallbackQuery.from_dict(self.callback_query)
    end
    if self.inline_query then
        self.inline_query = InlineQuery.from_dict(self.inline_query)
    end
    
    return self
end

function Update.from_dict(data)
    if not data then return nil end
    return Update.new(data)
end

-- Location type
local Location = setmetatable({}, {__index = BaseType})
Location.__index = Location

function Location.new(data)
    local self = setmetatable(BaseType.new(data), Location)
    return self
end

function Location.from_dict(data)
    if not data then return nil end
    return Location.new(data)
end

-- Keyboard types
local InlineKeyboardButton = setmetatable({}, {__index = BaseType})
InlineKeyboardButton.__index = InlineKeyboardButton

function InlineKeyboardButton.new(text, options)
    options = options or {}
    local self = setmetatable(BaseType.new(), InlineKeyboardButton)
    self.text = text
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local InlineKeyboardMarkup = setmetatable({}, {__index = BaseType})
InlineKeyboardMarkup.__index = InlineKeyboardMarkup

function InlineKeyboardMarkup.new(keyboard)
    local self = setmetatable(BaseType.new(), InlineKeyboardMarkup)
    self.inline_keyboard = keyboard or {}
    return self
end

local KeyboardButton = setmetatable({}, {__index = BaseType})
KeyboardButton.__index = KeyboardButton

function KeyboardButton.new(text, options)
    options = options or {}
    local self = setmetatable(BaseType.new(), KeyboardButton)
    self.text = text
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local ReplyKeyboardMarkup = setmetatable({}, {__index = BaseType})
ReplyKeyboardMarkup.__index = ReplyKeyboardMarkup

function ReplyKeyboardMarkup.new(keyboard, options)
    options = options or {}
    local self = setmetatable(BaseType.new(), ReplyKeyboardMarkup)
    self.keyboard = keyboard or {}
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local ReplyKeyboardRemove = setmetatable({}, {__index = BaseType})
ReplyKeyboardRemove.__index = ReplyKeyboardRemove

function ReplyKeyboardRemove.new(selective)
    local self = setmetatable(BaseType.new(), ReplyKeyboardRemove)
    self.remove_keyboard = true
    if selective ~= nil then
        self.selective = selective
    end
    return self
end

-- File types
local PhotoSize = setmetatable({}, {__index = BaseType})
PhotoSize.__index = PhotoSize

function PhotoSize.new(data)
    local self = setmetatable(BaseType.new(data), PhotoSize)
    return self
end

function PhotoSize.from_dict(data)
    if not data then return nil end
    return PhotoSize.new(data)
end

local Document = setmetatable({}, {__index = BaseType})
Document.__index = Document

function Document.new(data)
    local self = setmetatable(BaseType.new(data), Document)
    if self.thumb then
        self.thumb = PhotoSize.from_dict(self.thumb)
    end
    return self
end

function Document.from_dict(data)
    if not data then return nil end
    return Document.new(data)
end

local Audio = setmetatable({}, {__index = BaseType})
Audio.__index = Audio

function Audio.new(data)
    local self = setmetatable(BaseType.new(data), Audio)
    if self.thumb then
        self.thumb = PhotoSize.from_dict(self.thumb)
    end
    return self
end

function Audio.from_dict(data)
    if not data then return nil end
    return Audio.new(data)
end

local Video = setmetatable({}, {__index = BaseType})
Video.__index = Video

function Video.new(data)
    local self = setmetatable(BaseType.new(data), Video)
    if self.thumb then
        self.thumb = PhotoSize.from_dict(self.thumb)
    end
    return self
end

function Video.from_dict(data)
    if not data then return nil end
    return Video.new(data)
end

-- Inline types
local InlineQueryResultArticle = setmetatable({}, {__index = BaseType})
InlineQueryResultArticle.__index = InlineQueryResultArticle

function InlineQueryResultArticle.new(id, title, input_message_content, options)
    options = options or {}
    local self = setmetatable(BaseType.new(), InlineQueryResultArticle)
    
    self.type = "article"
    self.id = id
    self.title = title
    self.input_message_content = input_message_content
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local InputTextMessageContent = setmetatable({}, {__index = BaseType})
InputTextMessageContent.__index = InputTextMessageContent

function InputTextMessageContent.new(message_text, options)
    options = options or {}
    local self = setmetatable(BaseType.new(), InputTextMessageContent)
    
    self.message_text = message_text
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

-- Chat Member type
local ChatMember = setmetatable({}, {__index = BaseType})
ChatMember.__index = ChatMember

function ChatMember.new(data)
    local self = setmetatable(BaseType.new(data), ChatMember)
    if self.user then
        self.user = User.from_dict(self.user)
    end
    return self
end

function ChatMember.from_dict(data)
    if not data then return nil end
    return ChatMember.new(data)
end

-- Chat Invite Link type
local ChatInviteLink = setmetatable({}, {__index = BaseType})
ChatInviteLink.__index = ChatInviteLink

function ChatInviteLink.new(data)
    local self = setmetatable(BaseType.new(data), ChatInviteLink)
    if self.creator then
        self.creator = User.from_dict(self.creator)
    end
    return self
end

function ChatInviteLink.from_dict(data)
    if not data then return nil end
    return ChatInviteLink.new(data)
end

-- Sticker type
local Sticker = setmetatable({}, {__index = BaseType})
Sticker.__index = Sticker

function Sticker.new(data)
    local self = setmetatable(BaseType.new(data), Sticker)
    if self.thumb then
        self.thumb = PhotoSize.from_dict(self.thumb)
    end
    return self
end

function Sticker.from_dict(data)
    if not data then return nil end
    return Sticker.new(data)
end

-- Voice type
local Voice = setmetatable({}, {__index = BaseType})
Voice.__index = Voice

function Voice.new(data)
    local self = setmetatable(BaseType.new(data), Voice)
    return self
end

function Voice.from_dict(data)
    if not data then return nil end
    return Voice.new(data)
end

-- Video Note type
local VideoNote = setmetatable({}, {__index = BaseType})
VideoNote.__index = VideoNote

function VideoNote.new(data)
    local self = setmetatable(BaseType.new(data), VideoNote)
    if self.thumb then
        self.thumb = PhotoSize.from_dict(self.thumb)
    end
    return self
end

function VideoNote.from_dict(data)
    if not data then return nil end
    return VideoNote.new(data)
end

-- Animation type
local Animation = setmetatable({}, {__index = BaseType})
Animation.__index = Animation

function Animation.new(data)
    local self = setmetatable(BaseType.new(data), Animation)
    if self.thumb then
        self.thumb = PhotoSize.from_dict(self.thumb)
    end
    return self
end

function Animation.from_dict(data)
    if not data then return nil end
    return Animation.new(data)
end

-- Contact type
local Contact = setmetatable({}, {__index = BaseType})
Contact.__index = Contact

function Contact.new(data)
    local self = setmetatable(BaseType.new(data), Contact)
    return self
end

function Contact.from_dict(data)
    if not data then return nil end
    return Contact.new(data)
end

-- WebApp type
local WebApp = setmetatable({}, {__index = BaseType})
WebApp.__index = WebApp

function WebApp.new(data)
    local self = setmetatable(BaseType.new(data), WebApp)
    return self
end

function WebApp.from_dict(data)
    if not data then return nil end
    return WebApp.new(data)
end

-- Pre Checkout Query type
local PreCheckoutQuery = setmetatable({}, {__index = BaseType})
PreCheckoutQuery.__index = PreCheckoutQuery

function PreCheckoutQuery.new(data)
    local self = setmetatable(BaseType.new(data), PreCheckoutQuery)
    if self.from then
        self.from = User.from_dict(self.from)
    end
    return self
end

function PreCheckoutQuery.from_dict(data)
    if not data then return nil end
    return PreCheckoutQuery.new(data)
end

-- Input Media types
local InputMedia = setmetatable({}, {__index = BaseType})
InputMedia.__index = InputMedia

function InputMedia.new(data)
    local self = setmetatable(BaseType.new(data), InputMedia)
    return self
end

local InputMediaPhoto = setmetatable({}, {__index = InputMedia})
InputMediaPhoto.__index = InputMediaPhoto

function InputMediaPhoto.new(media, options)
    options = options or {}
    local self = setmetatable(InputMedia.new(), InputMediaPhoto)
    self.type = "photo"
    self.media = media
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local InputMediaVideo = setmetatable({}, {__index = InputMedia})
InputMediaVideo.__index = InputMediaVideo

function InputMediaVideo.new(media, options)
    options = options or {}
    local self = setmetatable(InputMedia.new(), InputMediaVideo)
    self.type = "video"
    self.media = media
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local InputMediaAudio = setmetatable({}, {__index = InputMedia})
InputMediaAudio.__index = InputMediaAudio

function InputMediaAudio.new(media, options)
    options = options or {}
    local self = setmetatable(InputMedia.new(), InputMediaAudio)
    self.type = "audio"
    self.media = media
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local InputMediaDocument = setmetatable({}, {__index = InputMedia})
InputMediaDocument.__index = InputMediaDocument

function InputMediaDocument.new(media, options)
    options = options or {}
    local self = setmetatable(InputMedia.new(), InputMediaDocument)
    self.type = "document"
    self.media = media
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

local InputMediaAnimation = setmetatable({}, {__index = InputMedia})
InputMediaAnimation.__index = InputMediaAnimation

function InputMediaAnimation.new(media, options)
    options = options or {}
    local self = setmetatable(InputMedia.new(), InputMediaAnimation)
    self.type = "animation"
    self.media = media
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

-- Login URL type
local LoginUrl = setmetatable({}, {__index = BaseType})
LoginUrl.__index = LoginUrl

function LoginUrl.new(url, options)
    options = options or {}
    local self = setmetatable(BaseType.new(), LoginUrl)
    self.url = url
    
    for key, value in pairs(options) do
        self[key] = value
    end
    
    return self
end

-- Force Reply type
local ForceReply = setmetatable({}, {__index = BaseType})
ForceReply.__index = ForceReply

function ForceReply.new(selective)
    local self = setmetatable(BaseType.new(), ForceReply)
    self.force_reply = true
    if selective ~= nil then
        self.selective = selective
    end
    return self
end

-- Export all types
types.BaseType = BaseType
types.User = User
types.Chat = Chat
types.Message = Message
types.CallbackQuery = CallbackQuery
types.InlineQuery = InlineQuery
types.Update = Update
types.Location = Location
types.InlineKeyboardButton = InlineKeyboardButton
types.InlineKeyboardMarkup = InlineKeyboardMarkup
types.KeyboardButton = KeyboardButton
types.ReplyKeyboardMarkup = ReplyKeyboardMarkup
types.ReplyKeyboardRemove = ReplyKeyboardRemove
types.PhotoSize = PhotoSize
types.Document = Document
types.Audio = Audio
types.Video = Video
types.InlineQueryResultArticle = InlineQueryResultArticle
types.InputTextMessageContent = InputTextMessageContent
types.ChatMember = ChatMember
types.ChatInviteLink = ChatInviteLink
types.Sticker = Sticker
types.Voice = Voice
types.VideoNote = VideoNote
types.Animation = Animation
types.Contact = Contact
types.WebApp = WebApp
types.PreCheckoutQuery = PreCheckoutQuery
types.InputMedia = InputMedia
types.InputMediaPhoto = InputMediaPhoto
types.InputMediaVideo = InputMediaVideo
types.InputMediaAudio = InputMediaAudio
types.InputMediaDocument = InputMediaDocument
types.InputMediaAnimation = InputMediaAnimation
types.LoginUrl = LoginUrl
types.ForceReply = ForceReply

return types
