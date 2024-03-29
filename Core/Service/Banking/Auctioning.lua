-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Auctioning = OC.Banking:NewPackage("Auctioning")
local Environment = OC.Include("Environment")
local TempTable = OC.Include("Util.TempTable")
local BagTracking = OC.Include("Service.BagTracking")
local AltTracking = OC.Include("Service.AltTracking")
local AuctionTracking = OC.Include("Service.AuctionTracking")
local MailTracking = OC.Include("Service.MailTracking")
local Settings = OC.Include("Service.Settings")
local ItemInfo = OC.Include("Service.ItemInfo")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Auctioning.MoveGroupsToBank(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromBags(items, groups, private.GroupsGetNumToMoveToBank)
	OC.Banking.MoveToBank(items, callback)
	TempTable.Release(items)
end

function Auctioning.PostCapToBags(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromOpenBank(items, groups, private.GetNumToMoveToBags)
	OC.Banking.MoveToBag(items, callback)
	TempTable.Release(items)
end

function Auctioning.ShortfallToBags(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromOpenBank(items, groups, private.GetNumToMoveToBags, true)
	OC.Banking.MoveToBag(items, callback)
	TempTable.Release(items)
end

function Auctioning.MaxExpiresToBank(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromBags(items, groups, private.MaxExpiresGetNumToMoveToBank)
	OC.Banking.MoveToBank(items, callback)
	TempTable.Release(items)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.GroupsGetNumToMoveToBank(itemString, numHave)
	-- move everything
	return numHave
end

function private.GetNumToMoveToBags(itemString, numHave, includeAH)
	local totalNumToMove = 0
	local numAvailable = numHave
	local numInBags = BagTracking.CreateQueryBagsItem(itemString)
		:VirtualField("autoBaseItemString", "string", OC.Groups.TranslateItemString, "itemString")
		:Equal("autoBaseItemString", itemString)
		:SumAndRelease("quantity")
	if includeAH then
		numInBags = numInBags + AuctionTracking.GetQuantity(itemString) + MailTracking.GetQuantity(itemString)
		-- include alt auctions on connected realms
		local isCommodity = ItemInfo.IsCommodity(itemString)
		for _, factionrealm, character, _, isConnected in Settings.ConnectedFactionrealmAltCharacterIterator() do
			if isCommodity or isConnected then
				numInBags = numInBags + AltTracking.GetAuctionQuantity(itemString, character, factionrealm)
			end
		end
	end

	for _, _, operationSettings in OC.Operations.GroupOperationIterator("Auctioning", OC.Groups.GetPathByItem(itemString)) do
		local maxExpires = OC.Auctioning.Util.GetPrice("maxExpires", operationSettings, itemString)
		local operationHasExpired = false
		if maxExpires and maxExpires > 0 then
			local numExpires = OC.Accounting.Auctions.GetNumExpiresSinceSale(itemString)
			if numExpires and numExpires > maxExpires then
				operationHasExpired = true
			end
		end

		local postCap = OC.Auctioning.Util.GetPrice("postCap", operationSettings, itemString)
		local stackSize = private.GetOperationStackSize(operationSettings, itemString)
		if not operationHasExpired and postCap and stackSize then
			local numNeeded = stackSize * postCap
			if numInBags > numNeeded then
				-- we can satisfy this operation from the bags
				numInBags = numInBags - numNeeded
				numNeeded = 0
			elseif numInBags > 0 then
				-- we can partially satisfy this operation from the bags
				numNeeded = numNeeded - numInBags
				numInBags = 0
			end

			local numToMove = min(numAvailable, numNeeded)
			if numToMove > 0 then
				numAvailable = numAvailable - numToMove
				totalNumToMove = totalNumToMove + numToMove
			end
		end
	end

	return totalNumToMove
end

function private.MaxExpiresGetNumToMoveToBank(itemString, numHave)
	local numToKeepInBags = 0
	for _, _, operationSettings in OC.Operations.GroupOperationIterator("Auctioning", OC.Groups.GetPathByItem(itemString)) do
		local maxExpires = OC.Auctioning.Util.GetPrice("maxExpires", operationSettings, itemString)
		local operationHasExpired = false
		if maxExpires and maxExpires > 0 then
			local numExpires = OC.Accounting.Auctions.GetNumExpiresSinceSale(itemString)
			if numExpires and numExpires > maxExpires then
				operationHasExpired = true
			end
		end
		local postCap = OC.Auctioning.Util.GetPrice("postCap", operationSettings, itemString)
		local stackSize = private.GetOperationStackSize(operationSettings, itemString)
		if not operationHasExpired and postCap and stackSize then
			numToKeepInBags = numToKeepInBags + stackSize * postCap
		end
	end
	return max(numHave - numToKeepInBags, 0)
end

function private.GetOperationStackSize(operationSettings, itemString)
	if Environment.HasFeature(Environment.FEATURES.AH_STACKS) then
		return OC.Auctioning.Util.GetPrice("stackSize", operationSettings, itemString)
	else
		return 1
	end
end
