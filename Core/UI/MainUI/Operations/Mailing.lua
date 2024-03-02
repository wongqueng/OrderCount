-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Mailing = OC.MainUI.Operations:NewPackage("Mailing")
local L = OC.Include("Locale").GetTable()
local TextureAtlas = OC.Include("Util.TextureAtlas")
local PlayerInfo = OC.Include("Service.PlayerInfo")
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	currentOperationName = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Mailing.OnInitialize()
	OC.MainUI.Operations.RegisterModule("Mailing", private.GetMailingOperationSettings)
end



-- ============================================================================
-- Mailing Operation Settings UI
-- ============================================================================

function private.GetMailingOperationSettings(operationName)
	UIUtils.AnalyticsRecordPathChange("main", "operations", "mailing")
	private.currentOperationName = operationName
	local operation = OC.Operations.GetSettings("Mailing", private.currentOperationName)
	return UIElements.New("ScrollFrame", "content")
		:SetPadding(8, 8, 8, 0)
		:AddChild(OC.MainUI.Operations.CreateExpandableSection("Mailing", "generalOptions", L["General Options"], L["Adjust how items are mailed."])
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("target", L["Target character"])
				:SetLayout("VERTICAL")
				:SetHeight(48)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Frame", "content")
					:SetLayout("HORIZONTAL")
					:AddChild(UIElements.New("Input", "input")
						:SetHeight(24)
						:SetMargin(0, 8, 0, 0)
						:SetHintText(L["Enter player name"])
						:SetAutoComplete(PlayerInfo.GetConnectedAlts())
						:SetClearButtonEnabled(true)
						:SetDisabled(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "target"))
						:SetSettingInfo(operation, "target")
					)
					:AddChild(UIElements.New("ActionButton", "contacts")
						:SetSize(152, 24)
						:SetFont("BODY_BODY2_MEDIUM")
						:SetText(L["Contacts"])
						:SetScript("OnClick", private.ContactsBtnOnClick)
					)
				)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("keepQty", L["Keep this amount"])
				:SetLayout("VERTICAL")
				:SetHeight(48)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Frame", "content")
					:SetLayout("HORIZONTAL")
					:SetHeight(24)
					:AddChild(UIElements.New("Input", "input")
						:SetMargin(0, 8, 0, 0)
						:SetBackgroundColor("ACTIVE_BG")
						:SetValidateFunc("NUMBER", "0:50000")
						:SetSettingInfo(operation, "keepQty")
						:SetDisabled(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "keepQty"))
					)
					:AddChild(UIElements.New("Text", "label")
						:SetWidth("AUTO")
						:SetFont("BODY_BODY3")
						:SetTextColor(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "keepQty") and "TEXT_DISABLED" or "TEXT")
						:SetFormattedText(L["Enter a value from %d - %d"], 0, 50000)
					)
				)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("maxQtyEnabled", L["Set max quantity"])
				:SetLayout("VERTICAL")
				:SetHeight(42)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("ToggleYesNo", "toggle")
					:SetHeight(18)
					:SetSettingInfo(operation, "maxQtyEnabled")
					:SetDisabled(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "maxQtyEnabled"))
					:SetScript("OnValueChanged", private.MaxQuantityToggleOnValueChanged)
				)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("maxQty", L["Max quantity"], not operation.maxQtyEnabled)
				:SetLayout("VERTICAL")
				:SetHeight(48)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Frame", "content")
					:SetLayout("HORIZONTAL")
					:SetHeight(24)
					:AddChild(UIElements.New("Input", "input")
						:SetMargin(0, 8, 0, 0)
						:SetBackgroundColor("ACTIVE_BG")
						:SetValidateFunc("NUMBER", "1:50000")
						:SetDisabled(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "maxQty") or not operation.maxQtyEnabled)
						:SetSettingInfo(operation, "maxQty")
					)
					:AddChild(UIElements.New("Text", "label")
						:SetWidth("AUTO")
						:SetFont("BODY_BODY3")
						:SetTextColor((OC.Operations.HasRelationship("Mailing", private.currentOperationName, "maxQty") or not operation.maxQtyEnabled) and "TEXT_DISABLED" or "TEXT")
						:SetFormattedText(L["Enter a value from %d - %d"], 1, 50000)
					)
				)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("restock", L["Restock target to max quantity"], not operation.maxQtyEnabled)
				:SetLayout("VERTICAL")
				:SetHeight(42)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("ToggleYesNo", "toggle")
					:SetHeight(18)
					:SetSettingInfo(operation, "restock")
					:SetDisabled(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "restock") or not operation.maxQtyEnabled)
					:SetScript("OnValueChanged", private.RestockToggleOnValueChanged)
				)
			)
			:AddChild(OC.MainUI.Operations.CreateLinkedSettingLine("restockSources", L["Sources to include for restock"], not operation.restock or not operation.maxQtyEnabled)
				:SetLayout("VERTICAL")
				:SetHeight(48)
				:AddChild(UIElements.New("MultiselectionDropdown", "dropdown")
					:SetHeight(24)
					:AddItem(BANK, "bank")
					:AddItem(GUILD, "guild")
					:SetSettingInfo(operation, "restockSources")
					:SetSelectionText(L["No Sources"], L["%d Sources"], L["All Sources"])
					:SetDisabled(OC.Operations.HasRelationship("Mailing", private.currentOperationName, "restockSources") or not operation.restock or not operation.maxQtyEnabled)
				)
			)
		)
		:AddChild(OC.MainUI.Operations.GetOperationManagementElements("Mailing", private.currentOperationName))
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.ContactsBtnOnClick(button)
	OC.UI.Util.Contacts.ShowDialog(button, button:GetElement("__parent.input"))
end


function private.MaxQuantityToggleOnValueChanged(toggle, value)
	local settingsFrame = toggle:GetElement("__parent.__parent")
	local restockValue = settingsFrame:GetElement("restock.toggle"):GetValue()
	local relationshipSet, linkTexture, textColor = OC.Operations.GetRelationshipColors("Mailing", private.currentOperationName, "maxQty", value)
	settingsFrame:GetElement("maxQty.line.linkBtn")
		:SetBackground(linkTexture)
		:SetDisabled(not value)
	settingsFrame:GetElement("maxQty.line.label")
		:SetTextColor(textColor)
	settingsFrame:GetElement("maxQty.content.label")
		:SetTextColor(textColor)
	settingsFrame:GetElement("maxQty.content.input")
		:SetDisabled(relationshipSet or not value)

	relationshipSet, linkTexture, textColor = OC.Operations.GetRelationshipColors("Mailing", private.currentOperationName, "restock", value)
	settingsFrame:GetElement("restock.line.linkBtn")
		:SetBackground(linkTexture)
		:SetDisabled(not value)
	settingsFrame:GetElement("restock.line.label")
		:SetTextColor(textColor)
	settingsFrame:GetElement("restock.toggle")
		:SetDisabled(relationshipSet or not value)

	relationshipSet = OC.Operations.HasRelationship("Mailing", private.currentOperationName, "restockSources")
	if relationshipSet and value and restockValue then
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "INDICATOR")
	elseif (relationshipSet and not value and restockValue) or (relationshipSet and value and not restockValue) or (relationshipSet and not value and not restockValue) then
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "INDICATOR_DISABLED")
	elseif (value and not restockValue) or (not value and restockValue) or (not value and not restockValue) then
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "TEXT_DISABLED")
	else
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "TEXT")
	end
	settingsFrame:GetElement("restockSources.line.linkBtn")
		:SetBackground(linkTexture)
		:SetDisabled(not value)
	settingsFrame:GetElement("restockSources.line.label")
		:SetTextColor(relationshipSet and "TEXT_DISABLED" or ((value and restockValue) and "TEXT" or "TEXT_DISABLED"))
	settingsFrame:GetElement("restockSources.dropdown")
		:SetDisabled(relationshipSet or not value or not restockValue)
	settingsFrame:Draw()
end

function private.RestockToggleOnValueChanged(toggle, value)
	local settingsFrame = toggle:GetElement("__parent.__parent")
	local maxQtyEnabled = settingsFrame:GetElement("maxQtyEnabled.toggle"):GetValue()
	local relationshipSet = OC.Operations.HasRelationship("Mailing", private.currentOperationName, "restockSources")
	local linkTexture = nil
	if relationshipSet and value and maxQtyEnabled then
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "INDICATOR")
	elseif (relationshipSet and not value and maxQtyEnabled) or (relationshipSet and value and not maxQtyEnabled) or (relationshipSet and not value and not maxQtyEnabled) then
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "INDICATOR_DISABLED")
	elseif (value and not maxQtyEnabled) or (not value and maxQtyEnabled) or (not value and not maxQtyEnabled) then
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "TEXT_DISABLED")
	else
		linkTexture = TextureAtlas.GetColoredKey("iconPack.14x14/Link", "TEXT")
	end
	settingsFrame:GetElement("restockSources.line.linkBtn")
		:SetBackground(linkTexture)
		:SetDisabled(not value)
	settingsFrame:GetElement("restockSources.line.label")
		:SetTextColor(relationshipSet and "TEXT_DISABLED" or ((value and maxQtyEnabled) and "TEXT" or "TEXT_DISABLED"))
	settingsFrame:GetElement("restockSources.dropdown")
		:SetDisabled(relationshipSet or not value or not maxQtyEnabled)
	settingsFrame:Draw()
end
