-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Inventory = OC.Init("Service.Inventory") ---@class Service.Inventory
local CustomPrice = OC.Include("Service.CustomPrice")
local AltTracking = OC.Include("Service.AltTracking")
local BagTracking = OC.Include("Service.BagTracking")
local AuctionTracking = OC.Include("Service.AuctionTracking")
local MailTracking = OC.Include("Service.MailTracking")
local private = {
	sources = {},
}



-- ============================================================================
-- Module Loading
-- ============================================================================

Inventory:OnSettingsLoad(function()
	tinsert(private.sources, "NumInventory")
	BagTracking.RegisterQuantityCallback(private.QuantityChangedCallback)
	AuctionTracking.RegisterQuantityCallback(private.QuantityChangedCallback)
	MailTracking.RegisterQuantityCallback(private.QuantityChangedCallback)
	AltTracking.RegisterQuantityCallback(private.QuantityChangedCallback)
end)



-- ============================================================================
-- Module Functions
-- ============================================================================

function Inventory.RegisterDependentCustomSource(source)
	tinsert(private.sources, source)
end

function Inventory.GetTotalQuantity(itemString)
	local total = 0
	total = total + BagTracking.GetBagQuantity(itemString)
	total = total + BagTracking.GetBankQuantity(itemString)
	total = total + BagTracking.GetReagentBankQuantity(itemString)
	total = total + MailTracking.GetQuantity(itemString)
	total = total + AuctionTracking.GetQuantity(itemString)
	total = total + AltTracking.GetTotalQuantity(itemString)
	total = total + AltTracking.GetTotalGuildQuantity(itemString)
	return total
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.QuantityChangedCallback(updatedItems)
	for _, source in ipairs(private.sources) do
		for itemString in pairs(updatedItems) do
			CustomPrice.OnSourceChange(source, itemString)
		end
	end
end
