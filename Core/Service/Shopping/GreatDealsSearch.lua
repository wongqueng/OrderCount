-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local GreatDealsSearch = OC.Shopping:NewPackage("GreatDealsSearch")
local String = OC.Include("Util.String")
local ItemInfo = OC.Include("Service.ItemInfo")
local private = {
	filter = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function GreatDealsSearch.OnEnable()
	local appData = OC.AppHelper.GetShoppingData()
	if not appData then
		return
	end
	private.filter = assert(loadstring(appData))().greatDeals
	-- populate item info cache
	for item in String.SplitIterator(private.filter, ";") do
		item = strsplit("/", item)
		ItemInfo.FetchInfo(item)
	end
end

function GreatDealsSearch.GetFilter()
	return private.filter
end
