-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local OrderHistory = OC.MainUI:NewPackage("OrderHistory")
local L = OC.Include("Locale").GetTable()
local Table = OC.Include("Util.Table")
local String = OC.Include("Util.String")
local Money = OC.Include("Util.Money")
local Settings = OC.Include("Service.Settings")
local UIElements = OC.Include("UI.UIElements")
local SECONDS_PER_DAY = 24 * 60 * 60
local private = {
    settings = nil,
    query = nil,
    characters = {},
    characterFilter = {},
    searchFilter = "",
    groupFilter = {},
    rarityFilter = {},
    timeFrameFilter = 30 * SECONDS_PER_DAY,
    type = nil
}

local TIME_LIST = { L["All Time"], L["Last 3 Days"], L["Last 7 Days"], L["Last 14 Days"], L["Last 30 Days"], L["Last 60 Days"] }
local TIME_KEYS = { 0, 3 * SECONDS_PER_DAY, 7 * SECONDS_PER_DAY, 14 * SECONDS_PER_DAY, 30 * SECONDS_PER_DAY, 60 * SECONDS_PER_DAY }



-- ============================================================================
-- Module Functions
-- ============================================================================

function OrderHistory.OnInitialize()
    private.settings = Settings.NewView()
                               :AddKey("global", "mainUIContext", "orderHistoryScrollingTable")
    OC.MainUI.RegisterTopLevelPage("订单历史", private.GetOrderHistoryFrame)
end

function private.GetOrderHistoryFrame()
    private.query = private.query or OC.OrderLog.CreateQuery()

    private.query:Reset()
           :Distinct("player")
           :Select("player")
    wipe(private.characters)
    for _, character in private.query:Iterator() do
        tinsert(private.characters, character)
        private.characterFilter[character] = true
    end

    private.query:Reset()
           :OrderBy("time", false)
    private.UpdateQuery()
    return UIElements.New("Frame", "content")
                     :SetLayout("VERTICAL")
                     :AddChild(UIElements.New("Frame", "row1")
                                         :SetLayout("HORIZONTAL")
                                         :SetHeight(24)
                                         :SetMargin(8)
                                         :AddChild(UIElements.New("Input", "filter")
                                                             :SetMargin(0, 8, 0, 0)
                                                             :SetIconTexture("iconPack.18x18/Search")
                                                             :SetClearButtonEnabled(true)
                                                             :AllowItemInsert()
                                                             :SetHintText(L["Filter by keyword"])
                                                             :SetValue(private.searchFilter)
                                                             :SetScript("OnValueChanged", private.SearchFilterChanged)
                                         )
                     )
                     :AddChild(UIElements.New("Frame", "row2")
                                         :SetLayout("HORIZONTAL")
                                         :SetHeight(24)
                                         :SetMargin(8, 8, 0, 8)
                                         :AddChild(UIElements.New("MultiselectionDropdown", "character")
                                                             :SetMargin(0, 8, 0, 0)
                                                             :SetItems(private.characters, private.characters)
                                                             :SetSettingInfo(private, "characterFilter")
                                                             :SetSelectionText(L["No Characters"], L["%d Characters"], L["All Characters"])
                                                             :SetScript("OnSelectionChanged", private.DropdownCommonOnSelectionChanged)
    )
                                         :AddChild(UIElements.New("SelectionDropdown", "time")
                                                             :SetItems(TIME_LIST, TIME_KEYS)
                                                             :SetSelectedItemByKey(private.timeFrameFilter)
                                                             :SetSettingInfo(private, "timeFrameFilter")
                                                             :SetScript("OnSelectionChanged", private.DropdownCommonOnSelectionChanged)
    )
    )
                     :AddChild(UIElements.New("QueryScrollingTable", "scrollingTable")
                                         :SetSettingsContext(private.settings, "orderHistoryScrollingTable")
                                         :GetScrollingTableInfo()
                                         :NewColumn("item")
                                         :SetTitle("物品")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("LEFT")
                                         :SetTextInfo("item")
                                         :SetTooltipInfo("itemString")
                                         :SetSortInfo("item")
                                         :DisableHiding()
                                         :Commit()
                                         :NewColumn("orderType")
                                         :SetTitle("订单类型")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("LEFT")
                                         :SetTextInfo("orderType")
                                         :SetSortInfo("orderType")
                                         :Commit()
                                         :NewColumn("client")
                                         :SetTitle("客户")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("RIGHT")
                                         :SetTextInfo("client")
                                         :SetSortInfo("client")
                                         :Commit()
                                         :NewColumn("player")
                                         :SetTitle("代工者")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("RIGHT")
                                         :SetTextInfo("player")
                                         :SetSortInfo("player")
                                         :Commit()
                                         :NewColumn("commission")
                                         :SetTitle("佣金")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("RIGHT")
                                         :SetTextInfo("commission",private.TableGetMoenyframeText)
                                         :SetSortInfo("commission")
                                         :Commit()
                                         :NewColumn("quantity")
                                         :SetTitle("数量")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("RIGHT")
                                         :SetTextInfo("quantity")
                                         :SetSortInfo("quantity")
                                         :Commit()
                                         :NewColumn("time")
                                         :SetTitle("时间")
                                         :SetFont("ITEM_BODY3")
                                         :SetJustifyH("RIGHT")
                                         :SetTextInfo("time",private.TableGetTimeframeText)
                                         :SetSortInfo("time")
                                         :Commit()
                                         :Commit()
                                         :SetQuery(private.query)
                                         :SetScript("OnRowClick", private.TableSelectionChanged)
    )
                     :AddChild(UIElements.New("HorizontalLine", "line"))
                     :AddChild(UIElements.New("Frame", "footer")
                                         :SetLayout("HORIZONTAL")
                                         :SetHeight(40)
                                         :SetPadding(8)
                                         :SetBackgroundColor("PRIMARY_BG")
                                         :AddChild(UIElements.New("Text", "num")
                                                             :SetWidth("AUTO")
                                                             :SetFont("BODY_BODY2_MEDIUM")
                                                             :SetText("完成订单数："..tostring(private.query:Count()))
    )                                       :AddChild(UIElements.New("VerticalLine", "line")
                                                                :SetMargin(4, 8, 0, 0)
    )
                                            :AddChild(UIElements.New("Text", "profit")
                                                                :SetWidth("AUTO")
                                                                :SetFont("BODY_BODY2_MEDIUM")
                                                                :SetText("总收入："..Money.ToString(OC.OrderLog.GetMoenySum(), nil, "OPT_RETAIL_ROUND"))
    )
                                            :AddChild(UIElements.New("Spacer", "spacer"))
    )
end

function private.TableGetTimeframeText(time)
    return date("%b %d %H:%M, %Y", time)
end
function private.TableGetMoenyframeText(money)
    local commission= Money.ToString(money, nil, "OPT_RETAIL_ROUND")
    return commission
end

function private.DropdownCommonOnSelectionChanged(dropdown)
    private.UpdateQuery()
    dropdown:GetElement("__parent.__parent.scrollingTable")
            :UpdateData(true)
    local footer = dropdown:GetElement("__parent.__parent.footer")
    footer:GetElement("num"):SetText("")
    footer:Draw()
end

function private.SearchFilterChanged(input)
    private.searchFilter = input:GetValue()
    private.DropdownCommonOnSelectionChanged(input)
end

function private.UpdateQuery()
    private.query:ResetFilters()
    if private.searchFilter ~= "" then
        private.query:Matches("item", String.Escape(private.searchFilter))
    end
    if Table.Count(private.characterFilter) ~= #private.characters then
        private.query:InTable("player", private.characterFilter)
    end
    if private.timeFrameFilter ~= 0 then
        private.query:GreaterThanOrEqual("time", time() - private.timeFrameFilter)
    end
end


function private.TableSelectionChanged(scrollingTable, row)
    --OC.MainUI.Ledger.ShowItemDetail(scrollingTable:GetParentElement():GetParentElement(), row:GetField("itemString"), "sale")
end
