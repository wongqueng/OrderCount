print("hehe")
OrderDB={}

local OC = select(2, ...) ---@type OC
local Log = OC.Include("Util.Log")
local SlashCommands = OC.Include("Service.SlashCommands")
local Threading = OC.Include("Service.Threading")
local Settings = OC.Include("Service.Settings")
local L = OC.Include("Locale").GetTable()
local private = {
    settings = nil,
    itemInfoPublisher = nil,  --luacheck: ignore 1004 - just stored for GC reasons
    oribosExchangeTemp = {},
}
local LOGOUT_TIME_WARNING_THRESHOLD = 0.02

-- ============================================================================
-- Module Functions
-- ============================================================================

function OC.OnInitialize()
    print(" OC.OnInitialize")
    -- Load settings
    OC.db = Settings.GetDB()
    private.settings = Settings.NewView()
                               :AddKey("global", "coreOptions", "chatFrame")
                               :AddKey("global", "debug", "chatLoggingEnabled")
                               :AddKey("global", "internalData", "lastCharacter")
                               :AddKey("sync", "internalData", "classKey")
    -- Set the last character we logged into for display in the app
    private.settings.lastCharacter = UnitName("player").." - "..GetRealmName()

    -- Configure the logger
    Log.SetChatFrame(private.settings.chatFrame)
    Log.SetLoggingToChatEnabled(private.settings.chatLoggingEnabled)
    Log.SetCurrentThreadNameFunction(Threading.GetCurrentThreadName)

    -- Store the class of this character
    private.settings.classKey = select(2, UnitClass("player"))
    -- Slash commands
    SlashCommands.Register("", OC.MainUI.Toggle, L["Toggles the main OC window"])

    local frame = CreateFrame("Frame")
    --frame:RegisterEvent("ADDON_LOADED")
    --frame:RegisterEvent("CHAT_MSG_SYSTEM")
    --frame:RegisterEvent("CHAT_MSG_MONEY")
    --frame:RegisterEvent("CHAT_MSG_SAY")
    --frame:RegisterEvent("CHAT_MSG_TRADESKILLS")
    --frame:RegisterEvent("CHAT_MSG_GUILD")
    --frame:RegisterEvent("CRAFTING_HOUSE_DISABLED")
    --frame:RegisterEvent("CRAFTINGORDERS_CAN_REQUEST")
    --frame:RegisterEvent("CRAFTINGORDERS_CLAIM_ORDER_RESPONSE")
    --frame:RegisterEvent("CRAFTINGORDERS_CLAIMED_ORDER_ADDED")
    --frame:RegisterEvent("CRAFTINGORDERS_CLAIMED_ORDER_REMOVED")
    --frame:RegisterEvent("CRAFTINGORDERS_CLAIMED_ORDER_UPDATED")
    --frame:RegisterEvent("CRAFTINGORDERS_CUSTOMER_FAVORITES_CHANGED")
    --frame:RegisterEvent("CRAFTINGORDERS_CUSTOMER_OPTIONS_PARSED")
    frame:RegisterEvent("CRAFTINGORDERS_DISPLAY_CRAFTER_FULFILLED_MSG")
    --frame:RegisterEvent("CRAFTINGORDERS_FULFILL_ORDER_RESPONSE")
    --frame:RegisterEvent("CRAFTING_HOUSE_DISABLED")
    --frame:RegisterEvent("CRAFTINGORDERS_HIDE_CRAFTER")
    --frame:RegisterEvent("CRAFTINGORDERS_HIDE_CUSTOMER")
    --frame:RegisterEvent("CRAFTINGORDERS_ORDER_CANCEL_RESPONSE")
    --frame:RegisterEvent("CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE")
    --frame:RegisterEvent("CRAFTINGORDERS_REJECT_ORDER_RESPONSE")
    --frame:RegisterEvent("CRAFTINGORDERS_RELEASE_ORDER_RESPONSE")
    --frame:RegisterEvent("CRAFTINGORDERS_SHOW_CRAFTER")
    --frame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
    --frame:RegisterEvent("CRAFTINGORDERS_UNEXPECTED_ERROR")
    --frame:RegisterEvent("CRAFTINGORDERS_UPDATE_CUSTOMER_NAME")
    --frame:RegisterEvent("CRAFTINGORDERS_UPDATE_ORDER_COUNT")
    --frame:RegisterEvent("CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS")
    frame:SetScript("OnEvent", function(event, ...)
        --print(...)
        local args = { ... }
        local msg_type = args[1]
        print(args[1]) --消息类型
        print(args[2]) --订单类型，个人还是公开
        print(args[3])  --商品
        print(args[4])  --客户名
        print(args[5])  --税后佣金  铜计价
        print(args[6])  --数量
        if msg_type == "ADDON_LOADED" and args[2]=="OrderCount" then

        elseif msg_type == "CRAFTINGORDERS_DISPLAY_CRAFTER_FULFILLED_MSG" then
            print("pre  insert data")
            print(OC.OrderLog.InsertRecord)
            OC.OrderLog.InsertRecord(args[3],args[2],args[4],args[5],args[6],time())
        end


    end)
    print("oc load")

    -- force a garbage collection
    collectgarbage()
end









