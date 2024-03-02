-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Crafting = OC.MainUI.Operations:NewPackage("Crafting")
local L = OC.Include("Locale").GetTable()
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	currentOperationName = nil,
}
local CRAFT_VALUE_VALIDATE_CONTEXT = {
	badSources = {
		crafting = true,
	},
}
local RESTOCK_QUANTITY_VALIDATE_CONTEXT = {
	isNumber = true,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Crafting.OnInitialize()
	RESTOCK_QUANTITY_VALIDATE_CONTEXT.minValue, RESTOCK_QUANTITY_VALIDATE_CONTEXT.maxValue = OC.Operations.Crafting.GetRestockRange()
	OC.MainUI.Operations.RegisterModule("Crafting", private.GetCraftingOperationSettings)
end



-- ============================================================================
-- Crafting Operation Settings UI
-- ============================================================================

function private.GetCraftingOperationSettings(operationName)
	UIUtils.AnalyticsRecordPathChange("main", "operations", "crafting")
	private.currentOperationName = operationName
	local operation = OC.Operations.GetSettings("Crafting", private.currentOperationName)
	local frame = UIElements.New("ScrollFrame", "settings")
		:SetPadding(8, 8, 8, 0)
		:AddChild(OC.MainUI.Operations.CreateExpandableSection("Crafting", "restockQuantity", L["Restock Options"], L["Adjust how crafted items are restocked."])
			:AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("minRestock", L["Minimum restock quantity"], RESTOCK_QUANTITY_VALIDATE_CONTEXT)
				:SetMargin(0, 0, 0, 12)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("maxRestock", L["Maximum restock quantity"], RESTOCK_QUANTITY_VALIDATE_CONTEXT)
				:SetMargin(0, 0, 0, 12)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("minProfit", L["Set min profit"], nil, "minProfitToggle")
				:SetLayout("VERTICAL")
				:SetHeight(42)
				:AddChild(UIElements.New("ToggleYesNo", "toggle")
					:SetHeight(18)
					:SetValue(operation.minProfit ~= "")
					:SetDisabled(OC.Operations.HasRelationship("Crafting", private.currentOperationName, "minProfit"))
					:SetScript("OnValueChanged", private.MinProfitToggleOnValueChanged)
				)
			)
		)
		:AddChild(OC.MainUI.Operations.CreateExpandableSection("Crafting", "priceSettings", L["Crafting Value"], L["Adjust how OC values crafted items when calculating profit."])
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("craftPriceMethod", L["Override default craft value"], nil, "craftPriceMethodToggle")
				:SetLayout("VERTICAL")
				:SetHeight(42)
				:AddChild(UIElements.New("ToggleYesNo", "toggle")
					:SetHeight(18)
					:SetValue(operation.craftPriceMethod ~= "")
					:SetDisabled(OC.Operations.HasRelationship("Crafting", private.currentOperationName, "craftPriceMethod"))
					:SetScript("OnValueChanged", private.CraftPriceToggleOnValueChanged)
				)
			)
		)
		:AddChild(OC.MainUI.Operations.GetOperationManagementElements("Crafting", private.currentOperationName))

	if operation.minProfit ~= "" then
		frame:GetElement("restockQuantity.content.minProfitToggle"):SetMargin(0, 0, 0, 12)
		frame:GetElement("restockQuantity"):AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("minProfit", L["Min profit amount"]))
	end
	if operation.craftPriceMethod ~= "" then
		frame:GetElement("priceSettings.content.craftPriceMethodToggle"):SetMargin(0, 0, 0, 12)
		frame:GetElement("priceSettings"):AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("craftPriceMethod", L["Craft Value"], CRAFT_VALUE_VALIDATE_CONTEXT, OC.db.global.craftingOptions.defaultCraftPriceMethod))
	end

	return frame
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.MinProfitToggleOnValueChanged(toggle, value)
	local operation = OC.Operations.GetSettings("Crafting", private.currentOperationName)
	local defaultValue = OC.Operations.GetSettingDefault("Crafting", "minProfit")
	operation.minProfit = value and defaultValue or ""
	local settingsFrame = toggle:GetParentElement():GetParentElement()
	if value then
		settingsFrame:GetElement("minProfitToggle"):SetMargin(0, 0, 0, 12)
		settingsFrame:GetParentElement():AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("minProfit", L["Min profit amount"]))
	else
		settingsFrame:GetElement("minProfitToggle"):SetMargin(0, 0, 0, 0)
		settingsFrame:RemoveChild(settingsFrame:GetElement("minProfit"))
	end
	settingsFrame:GetParentElement():GetParentElement():Draw()
end

function private.CraftPriceToggleOnValueChanged(toggle, value)
	local operation = OC.Operations.GetSettings("Crafting", private.currentOperationName)
	operation.craftPriceMethod = value and OC.db.global.craftingOptions.defaultCraftPriceMethod or ""
	local settingsFrame = toggle:GetParentElement():GetParentElement()
	if value then
		settingsFrame:GetElement("craftPriceMethodToggle"):SetMargin(0, 0, 0, 12)
		settingsFrame:GetParentElement():AddChild(OC.MainUI.Operations.CreateLinkedPriceInput("craftPriceMethod", L["Craft Value"], CRAFT_VALUE_VALIDATE_CONTEXT, OC.db.global.craftingOptions.defaultCraftPriceMethod))
	else
		settingsFrame:GetElement("craftPriceMethodToggle"):SetMargin(0, 0, 0, 0)
		settingsFrame:RemoveChild(settingsFrame:GetElement("craftPriceMethod"))
	end
	settingsFrame:GetParentElement():GetParentElement():Draw()
end
