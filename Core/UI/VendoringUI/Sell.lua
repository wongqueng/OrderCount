-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Sell = OC.UI.VendoringUI:NewPackage("Sell")
local L = OC.Include("Locale").GetTable()
local Money = OC.Include("Util.Money")
local TempTable = OC.Include("Util.TempTable")
local String = OC.Include("Util.String")
local Theme = OC.Include("Util.Theme")
local ItemInfo = OC.Include("Service.ItemInfo")
local Settings = OC.Include("Service.Settings")
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	settings = nil,
	filterText = "",
	query = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Sell.OnInitialize()
	private.settings = Settings.NewView()
		:AddKey("global", "vendoringUIContext", "sellScrollingTable")
	OC.UI.VendoringUI.RegisterTopLevelPage(L["Sell"], private.GetFrame)
end



-- ============================================================================
-- Sell UI
-- ============================================================================

function private.GetFrame()
	UIUtils.AnalyticsRecordPathChange("vendoring", "sell")
	private.filterText = ""
	if private.query then
		OC.Vendoring.Sell.ResetBagsQuery(private.query)
	else
		private.query = OC.Vendoring.Sell.CreateBagsQuery()
	end

	return UIElements.New("Frame", "sell")
		:SetLayout("VERTICAL")
		:AddChild(UIElements.New("Frame", "header")
			:SetLayout("VERTICAL")
			:SetPadding(8)
			:SetBackgroundColor("PRIMARY_BG_ALT")
			:AddChild(UIElements.New("Text", "ignoreText")
				:SetHeight(36)
				:SetMargin(0, 0, 0, 8)
				:SetFont("BODY_BODY3")
				:SetText(format(L["%sLeft-Click|r to ignore an item for this session. Hold %sShift|r to ignore permanently. You can remove items from permanent ignore in the Vendoring settings."], Theme.GetColor("INDICATOR"):GetTextColorPrefix(), Theme.GetColor("INDICATOR"):GetTextColorPrefix()))
			)
			:AddChild(UIElements.New("Frame", "filters")
				:SetLayout("HORIZONTAL")
				:SetHeight(24)
				:AddChild(UIElements.New("Input", "searchInput")
					:SetIconTexture("iconPack.18x18/Search")
					:SetClearButtonEnabled(true)
					:AllowItemInsert()
					:SetHintText(L["Search Bags"])
					:SetScript("OnValueChanged", private.InputOnValueChanged)
				)
				:AddChild(UIElements.New("Button", "filterBtn")
					:SetWidth("AUTO")
					:SetMargin(8, 8, 0, 0)
					:SetFont("BODY_BODY3_MEDIUM")
					:SetText(FILTERS)
					-- TODO
					-- :SetScript("OnClick", private.FilterButtonOnClick)
				)
				:AddChild(UIElements.New("Button", "filterBtnIcon")
					:SetBackgroundAndSize("iconPack.14x14/Filter")
					-- TODO
					-- :SetScript("OnClick", private.FilterButtonOnClick)
				)
			)
		)
		:AddChild(UIElements.New("QueryScrollingTable", "items")
			:SetSettingsContext(private.settings, "sellScrollingTable")
			:GetScrollingTableInfo()
				:NewColumn("item")
					:SetTitle(L["Item"])
					:SetIconSize(12)
					:SetFont("ITEM_BODY3")
					:SetJustifyH("LEFT")
					:SetTextInfo("itemString", private.GetItemText)
					:SetIconInfo("itemString", ItemInfo.GetTexture)
					:SetTooltipInfo("itemString")
					:SetSortInfo("name")
					:SetTooltipLinkingDisabled(true)
					:DisableHiding()
					:Commit()
				:NewColumn("vendorSell")
					:SetTitle(L["Vendor Sell"])
					:SetFont("TABLE_TABLE1")
					:SetJustifyH("RIGHT")
					:SetTextInfo("vendorSell", private.GetVendorSellText)
					:SetSortInfo("vendorSell")
					:Commit()
				:NewColumn("potential")
					:SetTitle(L["Potential"])
					:SetFont("TABLE_TABLE1")
					:SetJustifyH("RIGHT")
					:SetTextInfo("potentialValue", private.GetPotentialSellText)
					:SetSortInfo("potentialValue")
					:Commit()
				:SetCursor("BUY_CURSOR")
				:Commit()
			:SetQuery(private.query)
			:SetScript("OnRowClick", private.RowOnClick)
		)
		:AddChild(UIElements.New("HorizontalLine", "line"))
		:AddChild(UIElements.New("Frame", "footer")
			:SetLayout("HORIZONTAL")
			:SetHeight(40)
			:SetPadding(8)
			:SetBackgroundColor("PRIMARY_BG_ALT")
			:AddChild(UIElements.New("ActionButton", "sellTrashBtn")
				:SetWidth(128)
				:SetMargin(0, 8, 0, 0)
				:SetText(L["Sell Trash"])
				:SetScript("OnClick", private.SellTrashBtnOnClick)
			)
			:AddChild(UIElements.New("ActionButton", "sellBOEBtn")
				:SetWidth(128)
				:SetMargin(0, 8, 0, 0)
				:SetText(L["Sell BoEs"])
				:SetScript("OnClick", private.SellBOEBtnOnClick)
			)
			:AddChild(UIElements.New("ActionButton", "sellAllBtn")
				:SetText(L["Sell All"])
				:SetScript("OnClick", private.SellAllBtnOnClick)
			)
		)
end

function private.GetItemText(itemString)
	return UIUtils.GetDisplayItemName(itemString) or "?"
end

function private.GetPotentialSellText(value)
	return Money.ToString(value, nil, "OPT_RETAIL_ROUND")
end

function private.GetVendorSellText(vendorSell)
	return vendorSell > 0 and Money.ToString(vendorSell, nil, "OPT_RETAIL_ROUND") or ""
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.InputOnValueChanged(input)
	local text = input:GetValue()
	if text == private.filterText then
		return
	end
	private.filterText = text

	OC.Vendoring.Sell.ResetBagsQuery(private.query)
	if text ~= "" then
		private.query:Matches("name", String.Escape(text))
	end
	input:GetElement("__parent.__parent.__parent.items"):UpdateData(true)
end

function private.RowOnClick(_, row, mouseButton)
	local itemString = row:GetField("itemString")
	if mouseButton == "RightButton" then
		OC.Vendoring.Sell.SellItem(itemString)
	elseif IsShiftKeyDown() then
		OC.Vendoring.Sell.IgnoreItemPermanent(itemString)
	else
		OC.Vendoring.Sell.IgnoreItemSession(itemString)
	end
end

function private.SellTrashBtnOnClick(button)
	for _, row in private.query:Iterator() do
		local itemString, quality = row:GetFields("itemString", "quality")
		if quality == Enum.ItemQuality.Poor then
			OC.Vendoring.Sell.SellItem(itemString)
		end
	end
end

function private.SellBOEBtnOnClick(button)
	-- checking if an item is disenchantable might cause our query to change since it depends on the ItemInfo DB, so cache the list of items first
	local items = TempTable.Acquire()
	for _, row in private.query:Iterator() do
		tinsert(items, row:GetField("itemString"))
	end
	for _, itemString in ipairs(items) do
		if ItemInfo.IsDisenchantable(itemString) then
			OC.Vendoring.Sell.SellItem(itemString)
		end
	end
	TempTable.Release(items)
end

function private.SellAllBtnOnClick(button)
	for _, row in private.query:Iterator() do
		OC.Vendoring.Sell.SellItem(row:GetField("itemString"))
	end
end
