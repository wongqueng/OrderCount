-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Util = OC.Banking:NewPackage("Util")
local TempTable = OC.Include("Util.TempTable")
local BagTracking = OC.Include("Service.BagTracking")
local GuildTracking = OC.Include("Service.GuildTracking")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Util.BagIterator(autoBaseItems)
	local query = BagTracking.CreateQueryBags()
		:OrderBy("slotId", true)
	if autoBaseItems then
		query:VirtualField("autoBaseItemString", "string", OC.Groups.TranslateItemString, "itemString")
			:Select("bag", "slot", "autoBaseItemString", "quantity")
	else
		query:Select("bag", "slot", "itemString", "quantity")
	end
	if OC.Banking.IsGuildBankOpen() then
		query:Equal("isBoP", false)
			:Equal("isBoA", false)
	end
	return query:IteratorAndRelease()
end

function Util.OpenBankIterator(autoBaseItems)
	if OC.Banking.IsGuildBankOpen() then
		local query = GuildTracking.CreateQuery()
		if autoBaseItems then
			query:VirtualField("autoBaseItemString", "string", OC.Groups.TranslateItemString, "itemString")
				:Select("tab", "slot", "autoBaseItemString", "quantity")
		else
			query:Select("tab", "slot", "itemString", "quantity")
		end
		return query:IteratorAndRelease()
	else
		local query = BagTracking.CreateQueryBank()
			:OrderBy("slotId", true)
		if autoBaseItems then
			query:VirtualField("autoBaseItemString", "string", OC.Groups.TranslateItemString, "itemString")
				:Select("bag", "slot", "autoBaseItemString", "quantity")
		else
			query:Select("bag", "slot", "itemString", "quantity")
		end
		return query:IteratorAndRelease()
	end
end

function Util.PopulateGroupItemsFromBags(items, groups, getNumFunc, ...)
	local itemQuantity = TempTable.Acquire()
	for _, _, _, itemString, quantity in Util.BagIterator(true) do
		if private.InGroups(itemString, groups) then
			itemQuantity[itemString] = (itemQuantity[itemString] or 0) + quantity
		end
	end
	for itemString, numHave in pairs(itemQuantity) do
		local numToMove = getNumFunc(itemString, numHave, ...)
		if numToMove > 0 then
			items[itemString] = numToMove
		end
	end
	TempTable.Release(itemQuantity)
end

function Util.PopulateGroupItemsFromOpenBank(items, groups, getNumFunc, ...)
	local itemQuantity = TempTable.Acquire()
	for _, _, _, itemString, quantity in Util.OpenBankIterator(true) do
		if private.InGroups(itemString, groups) then
			itemQuantity[itemString] = (itemQuantity[itemString] or 0) + quantity
		end
	end
	for itemString, numHave in pairs(itemQuantity) do
		local numToMove = getNumFunc(itemString, numHave, ...)
		if numToMove > 0 then
			items[itemString] = numToMove
		end
	end
	TempTable.Release(itemQuantity)
end

function Util.PopulateItemsFromBags(items, getNumFunc, ...)
	local itemQuantity = TempTable.Acquire()
	for _, _, _, itemString, quantity in Util.BagIterator(true) do
		itemQuantity[itemString] = (itemQuantity[itemString] or 0) + quantity
	end
	for itemString, numHave in pairs(itemQuantity) do
		local numToMove = getNumFunc(itemString, numHave, ...)
		if numToMove > 0 then
			items[itemString] = numToMove
		end
	end
	TempTable.Release(itemQuantity)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.InGroups(itemString, groups)
	local groupPath = OC.Groups.GetPathByItem(itemString)
	-- TODO: support the base group
	return groupPath and groupPath ~= OC.CONST.ROOT_GROUP_PATH and groups[groupPath]
end
