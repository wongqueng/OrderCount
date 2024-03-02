-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Shopping = OC.Tooltip:NewPackage("Shopping")
local L = OC.Include("Locale").GetTable()
local ItemString = OC.Include("Util.ItemString")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Shopping.OnInitialize()
	OC.Tooltip.Register(OC.Tooltip.CreateInfo()
		:SetHeadings(L["OC Shopping"])
		:SetSettingsModule("Shopping")
		:AddSettingEntry("maxPrice", false, private.PopulateMaxPriceLine)
	)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.PopulateMaxPriceLine(tooltip, itemString)
	local maxPrice = nil
	if itemString == ItemString.GetPlaceholder() then
		-- example tooltip
		maxPrice = 37
	else
		maxPrice = OC.Operations.Shopping.GetMaxPrice(itemString)
	end
	if maxPrice then
		tooltip:AddItemValueLine(L["Max Shopping Price"], maxPrice)
	end
end
