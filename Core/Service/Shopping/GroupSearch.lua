-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local GroupSearch = OC.Shopping:NewPackage("GroupSearch")
local L = OC.Include("Locale").GetTable()
local Log = OC.Include("Util.Log")
local TempTable = OC.Include("Util.TempTable")
local ItemString = OC.Include("Util.ItemString")
local Threading = OC.Include("Service.Threading")
local ItemInfo = OC.Include("Service.ItemInfo")
local GroupSearchContext = OC.Include("LibOCClass").DefineClass("GroupSearchContext", OC.Shopping.ShoppingSearchContext)
local private = {
	groups = {},
	itemList = {},
	maxQuantity = {},
	scanThreadId = nil,
	seenMaxPrice = {},
	searchContext = nil,
	queries = {},
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function GroupSearch.OnInitialize()
	-- initialize thread
	private.scanThreadId = Threading.New("GROUP_SEARCH", private.ScanThread)
	private.searchContext = GroupSearchContext(private.scanThreadId, private.MarketValueFunction)
end

function GroupSearch.GetSearchContext(groupList)
	return private.searchContext:SetScanContext(L["Group Search"], groupList, nil, L["Max Price"])
end



-- ============================================================================
-- Scan Thread
-- ============================================================================

function private.ScanThread(auctionScan, groupList)
	wipe(private.seenMaxPrice)

	-- create the list of items, and add filters for them
	wipe(private.itemList)
	wipe(private.maxQuantity)
	wipe(private.queries)
	for _, groupPath in ipairs(groupList) do
		private.groups[groupPath] = true
		for _, itemString in OC.Groups.ItemIterator(groupPath) do
			local isValid, maxQuantityOrErr = OC.Operations.Shopping.ValidateAndGetRestockQuantity(itemString)
			if isValid then
				private.maxQuantity[itemString] = maxQuantityOrErr
				tinsert(private.itemList, itemString)
			elseif maxQuantityOrErr then
				Log.PrintfUser(L["Invalid custom price source for %s. %s"], ItemInfo.GetLink(itemString), maxQuantityOrErr)
			end
		end
		Threading.Yield()
	end
	if #private.itemList == 0 then
		return false
	end

	auctionScan:AddItemListQueriesThreaded(private.itemList)
	for _, query in auctionScan:QueryIterator() do
		query:SetIsBrowseDoneFunction(private.QueryIsBrowseDoneFunction)
		query:AddCustomFilter(private.QueryFilter)
		tinsert(private.queries, query)
	end

	-- run the scan
	if not auctionScan:ScanQueriesThreaded() then
		Log.PrintUser(L["OC failed to scan some auctions. Please rerun the scan."])
	end
	return true
end



-- ============================================================================
-- GroupSearchContext Class
-- ============================================================================

function GroupSearchContext.GetMaxCanBuy(self, itemString)
	return private.maxQuantity[itemString]
end

function GroupSearchContext.OnBuy(self, itemString, quantity)
	self.__super:OnBuy(itemString, quantity)
	if not private.maxQuantity[itemString] then
		return
	end

	private.maxQuantity[itemString] = private.maxQuantity[itemString] - quantity
	if private.maxQuantity[itemString] <= 0 then
		private.maxQuantity[itemString] = nil
		local toRemove = TempTable.Acquire()
		for _, query in ipairs(private.queries) do
			for _, row in query:BrowseResultsIterator() do
				if row:HasItemInfo() then
					for _, subRow in row:SubRowIterator() do
						if subRow:GetItemString() == itemString then
							tinsert(toRemove, subRow)
						end
					end
					for _, subRow in ipairs(toRemove) do
						row:RemoveSubRow(subRow)
					end
					wipe(toRemove)
				end
			end
		end
		TempTable.Release(toRemove)
	end
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.QueryIsBrowseDoneFunction(query)
	local isDone = true
	for itemString in query:ItemIterator() do
		if OC.Operations.Shopping.ShouldShowAboveMaxPrice(itemString) then
			-- need to scan all the auctions
			isDone = false
		elseif not private.seenMaxPrice[itemString] then
			-- we haven't seen any auctions above the max price, so need to keep scanning
			isDone = false
		end
	end
	return isDone
end

function private.QueryFilter(query, row)
	local baseItemString = row:GetBaseItemString()
	local itemString = row:GetItemString()
	local _, itemBuyout, minItemBuyout = row:GetBuyouts()
	itemBuyout = itemBuyout or minItemBuyout
	if not itemBuyout then
		return false
	elseif itemBuyout == 0 then
		return true
	end
	if itemString then
		local isFiltered, aboveMax = OC.Operations.Shopping.IsFiltered(itemString, itemBuyout)
		private.seenMaxPrice[itemString] = private.seenMaxPrice[itemString] or aboveMax
		return isFiltered
	else
		local allFiltered = true
		for queryItemString in query:ItemIterator() do
			if ItemString.GetBaseFast(queryItemString) == baseItemString and not OC.Operations.Shopping.IsFiltered(queryItemString, itemBuyout) then
				allFiltered = false
			end
		end
		return allFiltered
	end
end

function private.MarketValueFunction(row)
	local itemString = row:GetItemString()
	return itemString and OC.Operations.Shopping.GetMaxPrice(itemString) or nil
end
