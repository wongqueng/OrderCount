-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Shopping = OC.MainUI.Operations:NewPackage("Shopping")
local L = OC.Include("Locale").GetTable()
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	currentOperationName = nil,
}
local RESTOCK_SOURCES = { L["Alts"], L["Auctions"], BANK, GUILD }
local RESTOCK_SOURCES_KEYS = { "alts", "auctions", "bank", "guild" }
local MAX_QUANTITY_VALIDATE_CONTEXT = {
	isNumber = true,
}
local MAX_PRICE_VALIDATE_CONTEXT = {
	badSources = {
		shoppingopmax = true,
	}
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Shopping.OnInitialize()
	MAX_QUANTITY_VALIDATE_CONTEXT.minValue, MAX_QUANTITY_VALIDATE_CONTEXT.maxValue = OC.Operations.Shopping.GetRestockRange()
	OC.MainUI.Operations.RegisterModule("Shopping", private.GetShoppingOperationSettings)
end



-- ============================================================================
-- Shopping Operation Settings UI
-- ============================================================================

function private.GetShoppingOperationSettings(operationName)
	UIUtils.AnalyticsRecordPathChange("main", "operations", "shopping")
	private.currentOperationName = operationName
	local operation = OC.Operations.GetSettings("Shopping", private.currentOperationName)
	return UIElements.New("ScrollFrame", "settings")
		:SetPadding(8, 8, 8, 0)
		:SetBackgroundColor("PRIMARY_BG")
		:AddChild(OC.MainUI.Operations.CreateExpandableSection("Shopping", "generalOptions", L["General Options"], L["Set what items are shown during a Shopping scan."])
			:AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("maxPrice", L["Maximum auction price"], MAX_PRICE_VALIDATE_CONTEXT))
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("showAboveMaxPrice", L["Show auctions above max price"])
				:SetLayout("VERTICAL")
				:SetHeight(48)
				:SetMargin(0, 0, 12, 12)
				:AddChild(UIElements.New("ToggleYesNo", "toggle")
					:SetHeight(18)
					:SetSettingInfo(operation, "showAboveMaxPrice")
					:SetDisabled(OC.Operations.HasRelationship("Shopping", private.currentOperationName, "showAboveMaxPrice"))
				)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("restockQuantity", L["Maximum restock quantity"], MAX_QUANTITY_VALIDATE_CONTEXT)
				:SetMargin(0, 0, 0, 12)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("restockSources", L["Sources to include for restock"])
				:SetLayout("VERTICAL")
				:SetHeight(48)
				:AddChild(UIElements.New("MultiselectionDropdown", "dropdown")
					:SetHeight(24)
					:SetItems(RESTOCK_SOURCES, RESTOCK_SOURCES_KEYS)
					:SetSettingInfo(operation, "restockSources")
					:SetSelectionText(L["No Sources"], L["%d Sources"], L["All Sources"])
					:SetDisabled(OC.Operations.HasRelationship("Shopping", private.currentOperationName, "restockSources"))
				)
			)
		)
		:AddChild(OC.MainUI.Operations.GetOperationManagementElements("Shopping", private.currentOperationName))
end
