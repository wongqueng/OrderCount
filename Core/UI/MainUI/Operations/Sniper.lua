-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Sniper = OC.MainUI.Operations:NewPackage("Sniper")
local L = OC.Include("Locale").GetTable()
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	currentOperationName = nil,
}
local MAX_PRICE_VALIDATE_CONTEXT = {
	badSources = {
		sniperopmax = true,
	}
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Sniper.OnInitialize()
	OC.MainUI.Operations.RegisterModule("Sniper", private.GetSniperOperationSettings)
end



-- ============================================================================
-- Sniper Operation Settings UI
-- ============================================================================

function private.GetSniperOperationSettings(operationName)
	UIUtils.AnalyticsRecordPathChange("main", "operations", "sniper")
	private.currentOperationName = operationName
	return UIElements.New("ScrollFrame", "settings")
		:SetPadding(8, 8, 8, 0)
		:SetBackgroundColor("PRIMARY_BG")
		:AddChild(OC.MainUI.Operations.CreateExpandableSection("Sniper", "settings", L["General Options"], L["Set what items are shown during a Sniper scan."])
			:AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("belowPrice", L["Maximum price"], MAX_PRICE_VALIDATE_CONTEXT))
		)
		:AddChild(OC.MainUI.Operations.GetOperationManagementElements("Sniper", private.currentOperationName))
end
