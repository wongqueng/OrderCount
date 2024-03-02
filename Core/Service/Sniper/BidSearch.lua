-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local BidSearch = OC.Sniper:NewPackage("BidSearch")
local Environment = OC.Include("Environment")
local Threading = OC.Include("Service.Threading")
local private = {
	scanThreadId = nil,
	searchContext = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function BidSearch.OnInitialize()
	private.scanThreadId = Threading.New("SNIPER_BID_SEARCH", private.ScanThread)
	private.searchContext = OC.Sniper.SniperSearchContext(private.scanThreadId, private.MarketValueFunction, "BID")
end

function BidSearch.GetSearchContext()
	assert(not Environment.IsRetail())
	return private.searchContext
end



-- ============================================================================
-- Scan Thread
-- ============================================================================

function private.ScanThread(auctionScan)
	assert(not Environment.IsRetail())
	local numQueries = auctionScan:GetNumQueries()
	if numQueries == 0 then
		auctionScan:NewQuery()
			:AddCustomFilter(private.QueryFilter)
			:SetPage("FIRST")
	else
		assert(numQueries == 1)
	end
	-- don't care if the scan fails for sniper since it's rerun constantly
	auctionScan:ScanQueriesThreaded()
	return true
end

function private.QueryFilter(_, subRow)
	local itemString = subRow:GetItemString()
	if not itemString or not subRow:IsSubRow() or not subRow:HasRawData() then
		-- can only filter complete subRows
		return false
	end
	local maxPrice = OC.Operations.Sniper.GetBelowPrice(itemString) or nil
	if not maxPrice then
		-- no Shopping operation applies to this item, so filter it out
		return true
	end

	local _, itemDisplayedBid = subRow:GetDisplayedBids()
	return itemDisplayedBid > maxPrice
end

function private.MarketValueFunction(row)
	local itemString = row:GetItemString()
	return itemString and OC.Operations.Sniper.GetBelowPrice(itemString) or nil
end
