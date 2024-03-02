-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local DisenchantSearch = OC.Shopping:NewPackage("DisenchantSearch")
local L = OC.Include("Locale").GetTable()
local Log = OC.Include("Util.Log")
local Threading = OC.Include("Service.Threading")
local ItemInfo = OC.Include("Service.ItemInfo")
local CustomPrice = OC.Include("Service.CustomPrice")
local private = {
	itemList = {},
	scanThreadId = nil,
	searchContext = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function DisenchantSearch.OnInitialize()
	-- initialize thread
	private.scanThreadId = Threading.New("DISENCHANT_SEARCH", private.ScanThread)
	private.searchContext = OC.Shopping.ShoppingSearchContext(private.scanThreadId, private.MarketValueFunction)
end

function DisenchantSearch.GetSearchContext()
	return private.searchContext:SetScanContext(L["Disenchant Search"], nil, nil, L["Disenchant Value"])
end



-- ============================================================================
-- Scan Thread
-- ============================================================================

function private.ScanThread(auctionScan)
	if OC.AuctionDB.GetAppDataUpdateTimes() < time() - 60 * 60 * 12 then
		Log.PrintUser(L["No recent AuctionDB scan data found."])
		return false
	end

	-- create the list of items
	wipe(private.itemList)
	for itemString, minBuyout in OC.AuctionDB.LastScanIteratorThreaded() do
		if minBuyout and private.ShouldInclude(itemString, minBuyout) then
			tinsert(private.itemList, itemString)
		end
		Threading.Yield()
	end

	-- run the scan
	auctionScan:AddItemListQueriesThreaded(private.itemList)
	for _, query in auctionScan:QueryIterator() do
		query:AddCustomFilter(private.QueryFilter)
	end
	if not auctionScan:ScanQueriesThreaded() then
		Log.PrintUser(L["OC failed to scan some auctions. Please rerun the scan."])
	end

end

function private.ShouldInclude(itemString, minBuyout)
	if not ItemInfo.IsDisenchantable(itemString) then
		return false
	end

	local itemLevel = ItemInfo.GetItemLevel(itemString) or -1
	if itemLevel < OC.db.global.shoppingOptions.minDeSearchLvl or itemLevel > OC.db.global.shoppingOptions.maxDeSearchLvl then
		return false
	end

	if private.IsItemBuyoutTooHigh(itemString, minBuyout) then
		return false
	end

	return true
end

function private.QueryFilter(_, row)
	local itemString = row:GetItemString()
	if not itemString then
		return false
	end
	local _, itemBuyout = row:GetBuyouts()
	if not itemBuyout then
		return false
	end
	return private.IsItemBuyoutTooHigh(itemString, itemBuyout)
end

function private.IsItemBuyoutTooHigh(itemString, itemBuyout)
	local disenchantValue = CustomPrice.GetSourcePrice(itemString, "Destroy")
	return not disenchantValue or itemBuyout > OC.db.global.shoppingOptions.maxDeSearchPercent / 100 * disenchantValue
end

function private.MarketValueFunction(row)
	return CustomPrice.GetSourcePrice(row:GetItemString() or row:GetBaseItemString(), "Destroy")
end
