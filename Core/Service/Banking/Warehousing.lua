-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Warehousing = OC.Banking:NewPackage("Warehousing")
local TempTable = OC.Include("Util.TempTable")
local Math = OC.Include("Util.Math")
local BagTracking = OC.Include("Service.BagTracking")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Warehousing.MoveGroupsToBank(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromBags(items, groups, private.GetNumToMoveToBank)
	OC.Banking.MoveToBank(items, callback)
	TempTable.Release(items)
end

function Warehousing.MoveGroupsToBags(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromOpenBank(items, groups, private.GetNumToMoveToBags)
	OC.Banking.MoveToBag(items, callback)
	TempTable.Release(items)
end

function Warehousing.RestockBags(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromOpenBank(items, groups, private.GetNumToMoveRestock)
	OC.Banking.MoveToBag(items, callback)
	TempTable.Release(items)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.GetNumToMoveToBank(itemString, numToMove)
	local _, operationSettings = OC.Operations.GetFirstOperationByItem("Warehousing", itemString)
	if not operationSettings then
		return 0
	end
	if operationSettings.keepBagQuantity ~= 0 then
		numToMove = max(numToMove - operationSettings.keepBagQuantity, 0)
	end
	if operationSettings.moveQuantity ~= 0 then
		numToMove = min(numToMove, operationSettings.moveQuantity)
	end
	return numToMove
end

function private.GetNumToMoveToBags(itemString, numToMove)
	local _, operationSettings = OC.Operations.GetFirstOperationByItem("Warehousing", itemString)
	if not operationSettings then
		return 0
	end
	if operationSettings.keepBankQuantity ~= 0 then
		numToMove = max(numToMove - operationSettings.keepBankQuantity, 0)
	end
	if operationSettings.moveQuantity ~= 0 then
		numToMove = min(numToMove, operationSettings.moveQuantity)
	end
	return Math.Floor(numToMove, operationSettings.stackSize ~= 0 and operationSettings.stackSize or 1)
end

function private.GetNumToMoveRestock(itemString, numToMove)
	local _, operationSettings = OC.Operations.GetFirstOperationByItem("Warehousing", itemString)
	if not operationSettings then
		return 0
	end
	local numInBags = BagTracking.CreateQueryBagsItem(itemString)
		:VirtualField("autoBaseItemString", "string", OC.Groups.TranslateItemString, "itemString")
		:Equal("autoBaseItemString", itemString)
		:SumAndRelease("quantity")
	if operationSettings.restockQuantity == 0 or numInBags >= operationSettings.restockQuantity then
		return 0
	end
	if operationSettings.restockKeepBankQuantity ~= 0 then
		numToMove = max(numToMove - operationSettings.restockKeepBankQuantity, 0)
	end
	numToMove = min(numToMove, operationSettings.restockQuantity - numInBags)
	return Math.Floor(numToMove, operationSettings.restockStackSize ~= 0 and operationSettings.restockStackSize or 1)
end
