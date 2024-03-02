-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Auctioning = OC.Tooltip:NewPackage("Auctioning")
local Environment = OC.Include("Environment")
local L = OC.Include("Locale").GetTable()
local ItemString = OC.Include("Util.ItemString")
local ItemInfo = OC.Include("Service.ItemInfo")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Auctioning.OnInitialize()
	OC.Tooltip.Register(OC.Tooltip.CreateInfo()
		:SetHeadings(L["OC Auctioning"])
		:SetSettingsModule("Auctioning")
		:AddSettingEntry("postQuantity", false, private.PopulatePostQuantityLine)
		:AddSettingEntry("operationPrices", false, private.PopulatePricesLine)
	)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.PopulatePostQuantityLine(tooltip, itemString)
	local postCap, stackSize = nil, nil
	if itemString == ItemString.GetPlaceholder() then
		postCap = 5
		stackSize = Environment.HasFeature(Environment.FEATURES.AH_STACKS) and 200 or nil
	elseif ItemInfo.IsSoulbound(itemString) then
		return
	else
		itemString = OC.Groups.TranslateItemString(itemString)
		local _, operation = OC.Operations.GetFirstOperationByItem("Auctioning", itemString)
		if not operation then
			return
		end

		postCap = OC.Auctioning.Util.GetPrice("postCap", operation, itemString)
		stackSize = Environment.HasFeature(Environment.FEATURES.AH_STACKS) and OC.Auctioning.Util.GetPrice("stackSize", operation, itemString) or nil
	end
	if Environment.HasFeature(Environment.FEATURES.AH_STACKS) then
		tooltip:AddTextLine(L["Post Quantity"], postCap and stackSize and postCap.."x"..stackSize or "---")
	else
		tooltip:AddTextLine(L["Post Quantity"], postCap or "---")
	end
end

function private.PopulatePricesLine(tooltip, itemString)
	local minPrice, normalPrice, maxPrice = nil, nil, nil
	if itemString == ItemString.GetPlaceholder() then
		minPrice = 20
		normalPrice = 24
		maxPrice = 29
	elseif ItemInfo.IsSoulbound(itemString) then
		return
	else
		itemString = OC.Groups.TranslateItemString(itemString)
		local _, operation = OC.Operations.GetFirstOperationByItem("Auctioning", itemString)
		if not operation then
			return
		end

		minPrice = OC.Auctioning.Util.GetPrice("minPrice", operation, itemString)
		normalPrice = OC.Auctioning.Util.GetPrice("normalPrice", operation, itemString)
		maxPrice = OC.Auctioning.Util.GetPrice("maxPrice", operation, itemString)
	end
	tooltip:AddItemValuesLine(L["Min/Normal/Max Prices"], minPrice, normalPrice, maxPrice)
end
