-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local ItemTooltip = OC.Init("Service.ItemTooltip") ---@class Service.ItemTooltip
local Builder = OC.Include("Service.ItemTooltipClasses.Builder")
local Wrapper = OC.Include("Service.ItemTooltipClasses.Wrapper")



-- ============================================================================
-- Module Functions
-- ============================================================================

function ItemTooltip.CreateBuilder()
	return Builder.Create()
end

function ItemTooltip.SetWrapperPopulateFunction(func)
	Wrapper.SetPopulateFunction(func)
end
