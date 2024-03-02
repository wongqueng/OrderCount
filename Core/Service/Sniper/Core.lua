-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Sniper = OC:NewPackage("Sniper")
local Environment = OC.Include("Environment")
local Threading = OC.Include("Service.Threading")
local SniperSearchContext = OC.Include("LibOCClass").DefineClass("SniperSearchContext")
OC.Sniper.SniperSearchContext = SniperSearchContext



-- ============================================================================
-- Module Methods
-- ============================================================================

function Sniper.PopulateItemList(itemList)
	local baseHasOperation = false
	for _ in OC.Operations.GroupOperationIterator("Sniper", OC.CONST.ROOT_GROUP_PATH) do
		baseHasOperation = true
	end
	if baseHasOperation and not Environment.IsRetail() then
		return false
	end

	-- add all the items from groups with Sniper operations
	for _, groupPath in OC.Groups.GroupIterator() do
		local hasOperations = false
		for _ in OC.Operations.GroupOperationIterator("Sniper", groupPath) do
			hasOperations = true
		end
		if hasOperations then
			for _, itemString in OC.Groups.ItemIterator(groupPath) do
				if OC.Operations.Sniper.IsOperationValid(itemString) then
					tinsert(itemList, itemString)
				end
			end
		end
	end
	return true
end



-- ============================================================================
-- SniperSearchContext - Public Class Methods
-- ============================================================================

function SniperSearchContext.__init(self, threadId, marketValueFunc, scanType)
	assert(threadId and marketValueFunc and (scanType == "BUYOUT" or scanType == "BID"))
	self._threadId = threadId
	self._marketValueFunc = marketValueFunc
	self._scanType = scanType
end

function SniperSearchContext.StartThread(self, callback, auctionScan)
	Threading.SetCallback(self._threadId, callback)
	Threading.Start(self._threadId, auctionScan)
end

function SniperSearchContext.KillThread(self)
	Threading.Kill(self._threadId)
end

function SniperSearchContext.GetMarketValueFunc(self)
	return self._marketValueFunc
end

function SniperSearchContext.GetGatheringResultsFunc(self)
	return nil
end

function SniperSearchContext.IsBuyoutScan(self)
	return self._scanType == "BUYOUT"
end

function SniperSearchContext.IsBidScan(self)
	return self._scanType == "BID"
end
