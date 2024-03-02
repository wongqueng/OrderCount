-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Mailing = OC.Banking:NewPackage("Mailing")
local TempTable = OC.Include("Util.TempTable")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Mailing.MoveGroupsToBank(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromBags(items, groups, private.GroupsGetNumToMoveToBank)
	OC.Banking.MoveToBank(items, callback)
	TempTable.Release(items)
end

function Mailing.NongroupToBank(callback)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateItemsFromBags(items, private.NongroupGetNumToBank)
	OC.Banking.MoveToBank(items, callback)
	TempTable.Release(items)
end

function Mailing.TargetShortfallToBags(callback, groups)
	local items = TempTable.Acquire()
	OC.Banking.Util.PopulateGroupItemsFromOpenBank(items, groups, OC.Operations.Mailing.TargetShortfallGetNumToBags)
	OC.Banking.MoveToBag(items, callback)
	TempTable.Release(items)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.GroupsGetNumToMoveToBank(itemString, numHave)
	-- move everything
	return numHave
end

function private.NongroupGetNumToBank(itemString, numHave)
	local hasOperations = false
	for _ in OC.Operations.GroupOperationIterator("Mailing", OC.Groups.GetPathByItem(itemString)) do
		hasOperations = true
	end
	return not hasOperations and numHave or 0
end
