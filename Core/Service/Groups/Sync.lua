-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local GroupsSync = OC.Groups:NewPackage("Sync")
local L = OC.Include("Locale").GetTable()
local TempTable = OC.Include("Util.TempTable")
local Math = OC.Include("Util.Math")
local Log = OC.Include("Util.Log")
local Sync = OC.Include("Service.Sync")
local private = {}



-- ============================================================================
-- New Modules Functions
-- ============================================================================

function GroupsSync.OnInitialize()
	Sync.RegisterRPC("CREATE_PROFILE", private.RPCCreateProfile)
end

function GroupsSync.SendCurrentProfile(targetPlayer)
	local profileName = OC.db:GetCurrentProfile()
	local data = TempTable.Acquire()
	data.groups = TempTable.Acquire()
	for groupPath, moduleOperations in pairs(OC.db:Get("profile", profileName, "userData", "groups")) do
		data.groups[groupPath] = {}
		for _, module in OC.Operations.ModuleIterator() do
			local operations = moduleOperations[module]
			if operations.override then
				data.groups[groupPath][module] = operations
			end
		end
	end
	data.items = OC.db:Get("profile", profileName, "userData", "items")
	data.operations = OC.db:Get("profile", profileName, "userData", "operations")
	local result, estimatedTime = Sync.CallRPC("CREATE_PROFILE", targetPlayer, private.RPCCreateProfileResultHandler, profileName, UnitName("player"), data)
	if result then
		estimatedTime = max(Math.Round(estimatedTime, 60), 60)
		Log.PrintfUser(L["Sending your '%s' profile to %s. Please keep both characters online until this completes. This will take approximately: %s"], profileName, targetPlayer, SecondsToTime(estimatedTime))
	else
		Log.PrintUser(L["Failed to send profile. Ensure both characters are online and try again."])
	end
	TempTable.Release(data.groups)
	TempTable.Release(data)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.CopyTable(srcTbl, dstTbl)
	for k, v in pairs(srcTbl) do
		dstTbl[k] = v
	end
end

function private.RPCCreateProfile(profileName, playerName, data)
	assert(OC.db:IsValidProfileName(profileName))
	if OC.db:ProfileExists(profileName) then
		return false, L["A profile with that name already exists on the target account. Rename it first and try again."]
	end

	-- create and switch to the new profile
	local currentProfile = OC.db:GetCurrentProfile()
	OC.db:SetProfile(profileName)

	-- copy all the data into this profile
	private.CopyTable(data.groups, OC.db.profile.userData.groups)
	private.CopyTable(data.items, OC.db.profile.userData.items)
	OC.Operations.ReplaceProfileOperations(data.operations)

	-- switch back to our previous profile
	OC.db:SetProfile(currentProfile)

	Log.PrintfUser(L["Added '%s' profile which was received from %s."], profileName, playerName)

	return true, profileName, UnitName("player")
end

function private.RPCCreateProfileResultHandler(_, _, success, ...)
	if success == nil then
		Log.PrintUser(L["Failed to send profile."].." "..L["Ensure both characters are online and try again."])
		return
	elseif not success then
		local errMsg = ...
		Log.PrintUser(L["Failed to send profile."].." "..errMsg)
		return
	end

	local profileName, targetPlayer = ...
	Log.PrintfUser(L["Successfully sent your '%s' profile to %s!"], profileName, targetPlayer)
end
