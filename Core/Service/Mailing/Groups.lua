-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Groups = OC.Mailing:NewPackage("Groups")
local L = OC.Include("Locale").GetTable()
local Log = OC.Include("Util.Log")
local TempTable = OC.Include("Util.TempTable")
local Threading = OC.Include("Service.Threading")
local PlayerInfo = OC.Include("Service.PlayerInfo")
local BagTracking = OC.Include("Service.BagTracking")
local Settings = OC.Include("Service.Settings")
local private = {
	thread = nil,
	settings = nil,
	sendDone = false,
	groupListTemp = {},
	numMailableTemp = {},
	usedTemp = {},
	keepTemp = {},
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Groups.OnInitialize()
	private.thread = Threading.New("MAIL_GROUPS", private.GroupsMailThread)
	private.settings = Settings.NewView()
		:AddKey("global", "mailingOptions", "resendDelay")
end

function Groups.KillThread()
	Threading.Kill(private.thread)
end

function Groups.StartSending(callback, groupList, sendRepeat, isDryRun)
	wipe(private.groupListTemp)
	for _, groupPath in ipairs(groupList) do
		-- TODO: Support the base group
		if groupPath ~= OC.CONST.ROOT_GROUP_PATH then
			tinsert(private.groupListTemp, groupPath)
		end
	end
	Threading.Kill(private.thread)
	Threading.SetCallback(private.thread, callback)
	Threading.Start(private.thread, private.groupListTemp, sendRepeat, isDryRun)
end



-- ============================================================================
-- Group Sending Thread
-- ============================================================================

function private.GroupsMailThread(groupList, sendRepeat, isDryRun)
	while true do
		local targets = Threading.AcquireSafeTempTable()
		assert(not next(private.numMailableTemp))
		for _, groupPath in ipairs(groupList) do
			assert(not next(private.usedTemp))
			assert(not next(private.keepTemp))
			for _, operationSettings in private.OperationIterator(groupPath) do
				local target = operationSettings.target
				local targetItems = targets[target] or Threading.AcquireSafeTempTable()
				for _, itemString in OC.Groups.ItemIterator(groupPath) do
					itemString = OC.Groups.TranslateItemString(itemString)
					private.usedTemp[itemString] = private.usedTemp[itemString] or 0
					private.keepTemp[itemString] = max(private.keepTemp[itemString] or 0, operationSettings.keepQty)
					private.numMailableTemp[itemString] = private.numMailableTemp[itemString] or BagTracking.GetNumMailable(itemString)
					local numAvailable = private.numMailableTemp[itemString] - private.usedTemp[itemString] - private.keepTemp[itemString]
					local quantity = OC.Operations.Mailing.GetNumToSend(itemString, operationSettings, numAvailable)
					assert(quantity >= 0)
					if PlayerInfo.IsPlayer(target) then
						private.keepTemp[itemString] = max(private.keepTemp[itemString], quantity)
					else
						private.usedTemp[itemString] = private.usedTemp[itemString] + quantity
						if quantity > 0 then
							targetItems[itemString] = quantity
						end
					end
				end
				if next(targetItems) then
					targets[target] = targetItems
				else
					Threading.ReleaseSafeTempTable(targetItems)
				end
			end
			wipe(private.usedTemp)
			wipe(private.keepTemp)
		end
		wipe(private.numMailableTemp)

		if not next(targets) then
			Log.PrintUser(L["Nothing to send."])
		end
		for name, items in pairs(targets) do
			private.SendItems(name, items, isDryRun)
			Threading.ReleaseSafeTempTable(items)
			Threading.Sleep(0.5)
		end

		Threading.ReleaseSafeTempTable(targets)

		if sendRepeat then
			Threading.Sleep(private.settings.resendDelay * 60)
		else
			break
		end
	end
end

function private.OperationIterator(groupPath)
	local result = TempTable.Acquire()
	for _, _, operationSettings in OC.Operations.GroupOperationIterator("Mailing", groupPath) do
		if operationSettings.target ~= "" then
			tinsert(result, operationSettings)
		end
	end
	return TempTable.Iterator(result)
end

function private.SendItems(target, items, isDryRun)
	private.sendDone = false
	OC.Mailing.Send.StartSending(private.SendCallback, target, "", "", 0, items, true, isDryRun)
	while not private.sendDone do
		Threading.Yield(true)
	end
end

function private.SendCallback()
	private.sendDone = true
end
