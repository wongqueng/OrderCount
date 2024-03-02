-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Sniper = OC.Tooltip:NewPackage("Sniper")
local L = OC.Include("Locale").GetTable()
local ItemString = OC.Include("Util.ItemString")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Sniper.OnInitialize()
	OC.Tooltip.Register(OC.Tooltip.CreateInfo()
		:SetHeadings(L["OC Sniper"])
		:SetSettingsModule("Sniper")
		:AddSettingEntry("belowPrice", false, private.PopulateBelowPriceLine)
	)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.PopulateBelowPriceLine(tooltip, itemString)
	local belowPrice = nil
	if itemString == ItemString.GetPlaceholder() then
		-- example tooltip
		belowPrice = 35
	else
		belowPrice = OC.Operations.Sniper.GetBelowPrice(itemString)
	end
	if belowPrice then
		tooltip:AddItemValueLine(L["Sniper Below Price"], belowPrice)
	end
end
