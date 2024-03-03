-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local SlashCommands = OC.Init("Service.SlashCommands") ---@class Service.SlashCommands
local Log = OC.Include("Util.Log")
local L = OC.Include("Locale").GetTable()
local private = {
	commandInfo = {},
	commandOrder = {},
}
local CALLBACK_TIME_WARNING = 0.02



-- ============================================================================
-- Module Loading
-- ============================================================================

SlashCommands:OnModuleLoad(function()
	-- register the OC slash commands
	SlashCmdList["OC"] = private.OnChatCommand
	_G["SLASH_OC1"] = "/oc"
end)



-- ============================================================================
-- Module Functions
-- ============================================================================

function SlashCommands.Register(key, callback, label)
	assert(key and callback)
	local keyLower = strlower(key)
	private.commandInfo[keyLower] = {
		key = key,
		label = label,
		callback = callback,
	}
	tinsert(private.commandOrder, keyLower)
end

function SlashCommands.PrintHelp()
	Log.PrintUser(L["Slash Commands:"])
	for _, key in ipairs(private.commandOrder) do
		local info = private.commandInfo[key]
		if info.label then
			if info.key == "" then
				Log.PrintfUserRaw("|cffffaa00/oc|r - %s", info.label)
			else
				Log.PrintfUserRaw("|cffffaa00/oc %s|r - %s", info.key, info.label)
			end
		end
	end
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.OnChatCommand(input)
	input = strtrim(input)
	local cmd, args = strmatch(input, "^([^ ]*) ?(.*)$")
	cmd = strlower(cmd)
	if private.commandInfo[cmd] then
		local startTime = GetTimePreciseSec()
		private.commandInfo[cmd].callback(args)
		local timeTaken = GetTimePreciseSec() - startTime
		if timeTaken > CALLBACK_TIME_WARNING then
			Log.Warn("Handler for slash command (/oc%s) took %0.5fs", input ~= "" and " "..input or input, timeTaken)
		end
	else
		print("We weren't able to handle")
		-- We weren't able to handle this command so print out the help
		SlashCommands.PrintHelp()
	end
end
