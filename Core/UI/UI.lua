-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local UI = OC:NewPackage("UI")
local UIUtils = OC.Include("UI.UIUtils")
local ANALYTICS_UI_NAMES = {
	"auction",
	"banking",
	"crafting",
	"destroying",
	"mailing",
	"main",
	"task_list",
	"vendoring",
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function UI.OnInitialize()
	for _, uiName in ipairs(ANALYTICS_UI_NAMES) do
		UIUtils.RegisterUIForAnalytics(uiName)
	end
end
