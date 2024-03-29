-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Accounting = OC.MainUI.Settings:NewPackage("Accounting")
local L = OC.Include("Locale").GetTable()
local Log = OC.Include("Util.Log")
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Accounting.OnInitialize()
	OC.MainUI.Settings.RegisterSettingPage(L["Accounting"], "middle", private.GetAccountingSettingsFrame)
end



-- ============================================================================
-- Accounting Settings UI
-- ============================================================================

function private.GetAccountingSettingsFrame()
	UIUtils.AnalyticsRecordPathChange("main", "settings", "accounting")
	return UIElements.New("ScrollFrame", "accountingSettings")
		:SetPadding(8, 8, 8, 0)
		:AddChild(OC.MainUI.Settings.CreateExpandableSection("Accounting", "accounting", L["General Options"], L["Some general Accounting options are below."])
			:AddChild(UIElements.New("Frame", "check1")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Checkbox", "tradeCheckbox")
					:SetWidth("AUTO")
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Track Sales / Purchases via trade"])
					:SetSettingInfo(OC.db.global.accountingOptions, "trackTrades")
				)
				:AddChild(UIElements.New("Spacer", "spacer"))
			)
			:AddChild(UIElements.New("Frame", "check2")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:AddChild(UIElements.New("Checkbox", "tradePromptCheckbox")
					:SetWidth("AUTO")
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Don't prompt to record trades"])
					:SetSettingInfo(OC.db.global.accountingOptions, "autoTrackTrades")
				)
				:AddChild(UIElements.New("Spacer", "spacer"))
			)
		)
		:AddChild(OC.MainUI.Settings.CreateExpandableSection("Accounting", "accounting", L["Clear Old Data"], L["You can clear old Accounting data for the current realm below to keep things running smoothly."])
			:AddChild(UIElements.New("Text", "daysOldLabel")
				:SetHeight(20)
				:SetMargin(0, 0, 0, 4)
				:SetFont("BODY_BODY2_MEDIUM")
				:SetText(L["Remove Data Older Than (Days)"])
			)
			:AddChild(UIElements.New("Frame", "daysOld")
				:SetLayout("HORIZONTAL")
				:SetHeight(24)
				:AddChild(UIElements.New("Input", "input")
					:SetMargin(0, 8, 0, 0)
					:SetHintText(L["Number of days"])
					:SetValidateFunc("NUMBER", "0:10000")
					:SetValue("365")
					:SetScript("OnValidationChanged", private.InputOnValidationChanged)
				)
				:AddChild(UIElements.New("ActionButton", "clearBtn")
					:SetWidth(107)
					:SetText(L["Clear Data"])
					:SetScript("OnClick", private.ClearBtnOnClick)
				)
			)
		)
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.InputOnValidationChanged(input)
	input:GetElement("__parent.clearBtn")
		:SetDisabled(not input:IsValid())
		:Draw()
end

function private.ClearBtnOnClick(button)
	local days = tonumber(button:GetElement("__parent.input"):GetValue())
	local desc = format(L["Are you sure you want to clear accounting data older than %d days for the currenet realm?"], days)
	button:GetBaseElement():ShowConfirmationDialog(L["Clear Old Data?"], desc, private.ClearDataConfirmed, days)
end

function private.ClearDataConfirmed(days)
	Log.PrintfUser(L["Removed a total of %s old records."], OC.Accounting.Transactions.RemoveOldData(days) + OC.Accounting.Money.RemoveOldData(days) + OC.Accounting.Auctions.RemoveOldData(days))
end
