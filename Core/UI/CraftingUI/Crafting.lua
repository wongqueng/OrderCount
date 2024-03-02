-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Crafting = OC.UI.CraftingUI:NewPackage("Crafting")
local Environment = OC.Include("Environment")
local L = OC.Include("Locale").GetTable()
local CraftString = OC.Include("Util.CraftString")
local Delay = OC.Include("Util.Delay")
local FSM = OC.Include("Util.FSM")
local TempTable = OC.Include("Util.TempTable")
local Money = OC.Include("Util.Money")
local String = OC.Include("Util.String")
local Log = OC.Include("Util.Log")
local Theme = OC.Include("Util.Theme")
local ItemString = OC.Include("Util.ItemString")
local RecipeString = OC.Include("Util.RecipeString")
local BagTracking = OC.Include("Service.BagTracking")
local ItemInfo = OC.Include("Service.ItemInfo")
local Settings = OC.Include("Service.Settings")
local ItemLinked = OC.Include("Service.ItemLinked")
local Profession = OC.Include("Service.Profession")
local Tooltip = OC.Include("UI.Tooltip")
local UIUtils = OC.Include("UI.UIUtils")
local UIElements = OC.Include("UI.UIElements")
local private = {
	settings = nil,
	fsm = nil,
	professions = {},
	professionsKeys = {},
	showDelayFrame = 0,
	filterText = "",
	dialogFilterText = "",
	haveSkillUp = false,
	haveMaterials = false,
	professionFrame = nil,
	craftDetails=nil,
	zhaKuangEndTimer=nil,
	cuoXianEndTimer=nil,
}
local SHOW_DELAY_FRAMES = 2
local KEY_SEP = "\001"



-- ============================================================================
-- Module Functions
-- ============================================================================

function Crafting.OnInitialize()
	private.settings = Settings.NewView()
		:AddKey("global", "craftingUIContext", "professionScrollingTable")
		:AddKey("global", "craftingUIContext", "professionDividedContainer")
		:AddKey("global", "craftingUIContext", "professionDividedContainerBottom")
		:AddKey("char", "craftingUIContext", "groupTree")
		:AddKey("factionrealm", "internalData", "isCraftFavorite")
	ItemLinked.RegisterCallback(private.ItemLinkedCallback, true)
	OC.UI.CraftingUI.RegisterTopLevelPage(L["Crafting"], private.GetCraftingFrame)
	private.FSMCreate()
end



-- ============================================================================
-- Crafting UI
-- ============================================================================

function private.GetCraftingFrame()
	UIUtils.AnalyticsRecordPathChange("crafting", "crafting")
	private.filterText = ""
	local craftdetails=UIElements.New("CraftDetails", "details")
								 :SetCraftableQuantityFunction(OC.Crafting.ProfessionUtil.GetNumCraftableRecipeString)
								 :SetDFCraftingMatsFunction(OC.Crafting.DFCrafting.GetOptionalMats)
								 :SetCostsFunctions(OC.Crafting.Cost.GetCostsByRecipeString, OC.Crafting.Cost.GetCostsByCraftString)
								 :SetScript("OnQueueButtonClick", private.QueueBtnOnClick)
								 :SetScript("OnCraftButtonMouseDown", private.CraftBtnOnMouseDown)
								 :SetScript("OnCraftButtonClick", private.CraftBtnOnClick)
								 :SetScript("OnZhaKuangEnd", private.ZhaKuangEnd)
								 :SetScript("OnCuoXianEnd", private.CuoXianEnd)
	local frame = UIElements.New("DividedContainer", "crafting")
		:SetMinWidth(200, Environment.IsRetail() and 189 or 147)
		:SetVertical()
		:HideDivider()
		:SetSettingsContext(private.settings, "professionDividedContainerBottom")
		:SetTopChild(UIElements.New("DividedContainer", "top")
			:SetMinWidth(400, 200)
			:HideDivider()
			:SetMargin(0, 0, 0, 2)
			:SetBackgroundColor("FRAME_BG")
			:SetSettingsContext(private.settings, "professionDividedContainer")
			:SetLeftChild(UIElements.New("Frame", "left")
				:SetLayout("VERTICAL")
				:SetMargin(0, 2, 0, 0)
				:AddChild(UIElements.New("Frame", "controls")
					:SetLayout("HORIZONTAL")
					:SetHeight(24)
					:SetMargin(0, 0, 0, 4)
					:AddChild(UIElements.New("SelectionDropdown", "professionDropdown")
						:SetWidth(205)
						:SetMargin(0, 4, 0, 0)
						:SetHintText(L["No Profession Opened"])
						:SetScript("OnSelectionChanged", private.ProfessionDropdownOnSelectionChanged)
					)
					:AddChild(UIElements.New("Input", "filterInput")
						:SetMargin(0, 4, 0, 0)
						:SetIconTexture("iconPack.18x18/Search")
						:SetClearButtonEnabled(true)
						:SetHintText(L["Search Patterns"])
						:SetScript("OnValueChanged", private.FilterInputOnValueChanged)
					)
					:AddChild(UIElements.New("Frame", "buttons")
						:SetLayout("HORIZONTAL")
						:SetSize(48, 24)
						:SetRoundedBackgroundColor("PRIMARY_BG_ALT")
						:AddChild(UIElements.New("Button", "groupsBtn")
							:SetMargin(4, 10, 0, 0)
							:SetBackgroundAndSize("iconPack.14x14/Groups")
							:SetScript("OnClick", private.CreateProfessionBtnOnClick)
							:SetTooltip(L["Create Profession Groups"])
						)
						:AddChild(UIElements.New("Button", "filterBtn")
							:SetBackgroundAndSize("iconPack.14x14/Filter")
							:SetHighlightLocked(private.haveSkillUp or private.haveMaterials)
							:SetScript("OnClick", private.FilterButtonOnClick)
						)
					)
				)
				:AddChild(UIElements.New("Frame", "content")
					:SetLayout("VERTICAL")
					:SetPadding(1)
					:SetBackgroundColor("PRIMARY_BG")
					:SetBorderColor("ACTIVE_BG", 1)
					:AddChild(UIElements.New("ProfessionScrollingTable", "recipeList")
						:SetFavoritesContext(private.settings.isCraftFavorite)
						:SetSettingsContext(private.settings, "professionScrollingTable")
						:SetScript("OnSelectionChanged", private.RecipeListOnSelectionChanged)
						:SetScript("OnRowClick", private.RecipeListOnRowClick)
					)
				)
			)
			:SetRightChild(UIElements.New("Frame", "right")
				:SetLayout("VERTICAL")
				:SetMargin(2, 0, 0, 0)
				:AddChild(UIElements.New("ActionButton", "restockDialog")
					:SetMargin(0, 0, 0, 4)
					:SetHeight(24)
					:SetText(L["Restock Groups"])
					:SetScript("OnClick", private.RestockShowDialog)
				)
				:AddChild(UIElements.New("Frame", "queue")
					:SetLayout("VERTICAL")
					:SetBackgroundColor("PRIMARY_BG")
					:SetPadding(1)
					:SetBorderColor("ACTIVE_BG", 1)
					:AddChild(UIElements.New("Frame", "header")
						:SetLayout("HORIZONTAL")
						:SetHeight(20)
						:SetPadding(4, 4, 0, 0)
						:SetBackgroundColor("PRIMARY_BG_ALT")
						:AddChild(UIElements.New("Text", "title")
							:SetFont("BODY_BODY3_MEDIUM")
							:SetText(format(L["Queue (%d)"], 0))
						)
						:AddChild(UIElements.New("Spacer", "spacer"))
						:AddChild(UIElements.New("Button", "info")
							:SetSize(12, 12)
							:SetBackground("iconPack.12x12/Attention")
							:SetTooltip(private.QueueTooltipFunc)
						)
					)
					:AddChild(UIElements.New("HorizontalLine", "line")
						:SetMargin(0, 0, 0, 4)
					)
					:AddChild(UIElements.New("CraftingQueueList", "queueList")
						:SetQuery(OC.Crafting.CreateQueueQuery())
						:SetScript("OnRowMouseDown", private.QueueOnRowMouseDown)
						:SetScript("OnRowClick", private.QueueOnRowClick)
					)
					:AddChild(UIElements.New("HorizontalLine", "line2"))
					:AddChild(UIElements.New("Frame", "footer")
						:SetLayout("HORIZONTAL")
						:SetHeight(24)
						:SetMargin(8, 8, 8, 8)
						:AddChild(UIElements.NewNamed("ActionButton", "craftNextBtn", "OCCraftingBtn")
							:SetMargin(0, 8, 0, 0)
							:SetText(L["Craft Next"])
							:SetScript("OnClick", private.CraftNextOnClick)
						)
						:AddChild(UIElements.New("Button", "clearBtn")
							:SetWidth(70)
							:SetFont("BODY_BODY3_MEDIUM")
							:SetText(L["Clear All"])
							:SetTextColor("INDICATOR")
							:SetScript("OnClick", private.ClearOnClick)
						)
					)
				)
			)
		)
		:SetBottomChild(
			craftdetails
		)
		:SetScript("OnUpdate", private.FrameOnUpdate)
		:SetScript("OnHide", private.FrameOnHide)
	private.craftDetails=craftdetails
	private.professionFrame = frame
	return frame
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.FrameOnUpdate(frame)
	-- delay the FSM event by a few frames to give textures a chance to load
	if private.showDelayFrame == SHOW_DELAY_FRAMES then
		frame:SetScript("OnUpdate", nil)
		private.fsm:ProcessEvent("EV_FRAME_SHOW", frame)
	else
		private.showDelayFrame = private.showDelayFrame + 1
	end
end

function private.FrameOnHide()
	assert(private.professionFrame)
	private.professionFrame = nil
	private.craftDetails = nil
	private.showDelayFrame = 0
	private.fsm:ProcessEvent("EV_FRAME_HIDE")
end

function private.CreateProfessionBtnOnClick(button)
	local profName = Profession.GetCurrentProfession()
	if not profName then
		Log.PrintUser(L["There is currently no profession open, so cannot create profession groups."])
		return
	end
	local items = profName..OC.CONST.GROUP_SEP..L["Items"]
	local mats = profName..OC.CONST.GROUP_SEP..L["Materials"]
	if OC.Groups.Exists(profName) then
		if not OC.Groups.Exists(items) then
			OC.Groups.Create(items)
		end
		if not OC.Groups.Exists(mats) then
			OC.Groups.Create(mats)
		end
	else
		OC.Groups.Create(profName)
		OC.Groups.Create(items)
		OC.Groups.Create(mats)
	end

	local numMats, numItems = 0, 0
	local query = OC.Crafting.CreateRawMatItemQuery()
		:Matches("professions", profName)
		:Select("itemString")

	for _, itemString in query:IteratorAndRelease() do
		local classId = ItemInfo.GetClassId(itemString)
		if itemString and not OC.Groups.IsItemInGroup(itemString) and not ItemInfo.IsSoulbound(itemString) and classId ~= Enum.ItemClass.Weapon and classId ~= Enum.ItemClass.Armor then
			OC.Groups.SetItemGroup(itemString, mats)
			numMats = numMats + 1
		end
	end

	query = Profession.CreateScannerQuery()
		:Select("craftString")

	for _, craftString in query:IteratorAndRelease() do
		local itemString = OC.Crafting.GetItemString(craftString)
		if itemString and not OC.Groups.IsItemInGroup(itemString) and not ItemInfo.IsSoulbound(itemString) then
			OC.Groups.SetItemGroup(itemString, items)
			numItems = numItems + 1
		end
	end

	if numMats > 0 or numItems > 0 then
		Log.PrintfUser(L["%s group updated with %d items and %d materials."], profName, numItems, numMats)
	else
		Log.PrintfUser(L["%s group is already up to date."], profName)
	end
end

function private.ProfessionDropdownOnSelectionChanged(dropdown)
	local key = dropdown:GetSelectedItemKey()
	if not key then
		-- nothing selected
		return
	end
	local player, profession, skillId = strsplit(KEY_SEP, key)
	if not profession then
		-- the current linked / guild / NPC profession was re-selected, so just ignore this change
		return
	end
	-- TODO: support showing of other player's professions?
	assert(player == UnitName("player"))
	Profession.Open(not Environment.IsRetail() and profession or tonumber(skillId))
end

function private.FilterInputOnValueChanged(input)
	local text = input:GetValue()
	if text == private.filterText then
		return
	end
	private.filterText = text

	private.fsm:ProcessEvent("EV_RECIPE_FILTER_CHANGED", private.filterText)
end

function private.RecipeListOnSelectionChanged(list)
	local selection = list:GetSelection()
	if selection and CraftFrame_SetSelection and Profession.IsClassicCrafting() then
		CraftFrame_SetSelection(Profession.GetIndexByCraftString(selection))
	end

	private.fsm:ProcessEvent("EV_RECIPE_SELECTION_CHANGED")
end

function private.RestockShowDialog(groupTree)
	groupTree:GetBaseElement():ShowDialogFrame(UIElements.New("Frame", "frame")
		:SetLayout("VERTICAL")
		:SetSize(540, 420)
		:SetPadding(8)
		:AddAnchor("CENTER")
		:SetRoundedBackgroundColor("FRAME_BG")
		:SetMouseEnabled(true)
		:AddChild(UIElements.New("Frame", "header")
			:SetLayout("HORIZONTAL")
			:SetHeight(24)
			:SetMargin(0, 0, 0, 8)
			:AddChild(UIElements.New("Text", "title")
				:SetMargin(32, 8, 0, 0)
				:SetFont("BODY_BODY1_BOLD")
				:SetJustifyH("CENTER")
				:SetText(L["Restock OC Groups"])
			)
			:AddChild(UIElements.New("Button", "closeBtn")
				:SetBackgroundAndSize("iconPack.24x24/Close/Default")
				:SetScript("OnClick", private.DialogCloseBtnOnClick)
			)
		)
		:AddChild(UIElements.New("Frame", "container")
			:SetLayout("VERTICAL")
			:SetPadding(2)
			:SetBackgroundColor("PRIMARY_BG")
			:SetBorderColor("ACTIVE_BG")
			:AddChild(UIElements.New("Frame", "header")
				:SetLayout("HORIZONTAL")
				:SetHeight(24)
				:SetMargin(8)
				:AddChild(UIElements.New("Input", "input")
					:AllowItemInsert(true)
					:SetIconTexture("iconPack.18x18/Search")
					:SetClearButtonEnabled(true)
					:SetHintText(L["Search Groups"])
					:SetScript("OnValueChanged", private.DialogFilterOnValueChanged)
				)
				:AddChild(UIElements.New("Button", "expandAllBtn")
					:SetSize(24, 24)
					:SetMargin(8, 0, 0, 0)
					:SetBackground("iconPack.18x18/Expand All")
					:SetScript("OnClick", private.ExpandAllGroupsOnClick)
					:SetTooltip(L["Expand / Collapse All Groups"])
				)
				:AddChild(UIElements.New("Button", "selectAllBtn")
					:SetSize(24, 24)
					:SetMargin(8, 0, 0, 0)
					:SetBackground("iconPack.18x18/Select All")
					:SetScript("OnClick", private.SelectAllGroupsOnClick)
					:SetTooltip(L["Select / Deselect All Groups"])
				)
			)
			:AddChild(UIElements.New("ApplicationGroupTree", "groupTree")
				:SetSettingsContext(private.settings, "groupTree")
				:SetQuery(OC.Groups.CreateQuery(), "Crafting")
				:SetSearchString(private.dialogFilterText)
				:SetScript("OnGroupSelectionChanged", private.GroupTreeOnGroupSelectionChanged)
			)
		)
		:AddChild(UIElements.New("Frame", "footer")
			:SetLayout("HORIZONTAL")
			:SetHeight(26)
			:SetBackgroundColor("PRIMARY_BG")
			:AddChild(UIElements.New("Spacer", "spacer"))
			:AddChild(UIElements.New("Text", "groupsText")
				:SetFont("BODY_BODY2_MEDIUM")
				:SetJustifyH("RIGHT")
				:SetText(format(L["%d Groups Selected"], 0))
			)
			:AddChild(UIElements.New("Texture", "vline")
				:SetWidth(1)
				:SetMargin(8, 8, 2, 2)
				:SetColor("ACTIVE_BG_ALT")
			)
			:AddChild(UIElements.New("Text", "itemsText")
				:SetWidth("AUTO")
				:SetMargin(0, 8, 0, 0)
				:SetFont("BODY_BODY2_MEDIUM")
				:SetJustifyH("RIGHT")
				:SetText(L["Total Items"]..": ".."0")
			)
		)
		:AddChild(UIElements.New("ActionButton", "restockBtn")
			:SetHeight(24)
			:SetMargin(0, 0, 8, 0)
			:SetText(L["Restock Groups"])
			:SetScript("OnClick", private.RestockGroupsOnClick)
		)
		:SetScript("OnUpdate", private.DialogFrameOnUpdate)
	)
end

function private.DialogFrameOnUpdate(frame)
	frame:SetScript("OnUpdate", nil)
	private.DialogFilterOnValueChanged(frame:GetElement("container.header.input"))
	private.GroupTreeOnGroupSelectionChanged(frame:GetElement("container.groupTree"))
end

function private.DialogCloseBtnOnClick(button)
	button:GetBaseElement():HideDialog()
end

function private.DialogFilterOnValueChanged(input)
	local text = strlower(input:GetValue())
	if text == private.dialogFilterText then
		return
	end
	private.dialogFilterText = text

	input:GetElement("__parent.__parent.groupTree")
		:SetSearchString(private.dialogFilterText)
		:Draw()
end

function private.ExpandAllGroupsOnClick(button)
	button:GetElement("__parent.__parent.groupTree")
		:ToggleExpandAll()
end

function private.SelectAllGroupsOnClick(button)
	button:GetElement("__parent.__parent.groupTree")
		:ToggleSelectAll()
end

function private.GroupTreeOnGroupSelectionChanged(groupTree)
	groupTree:GetElement("__parent.__parent.restockBtn")
		:SetDisabled(groupTree:IsSelectionCleared())
		:Draw()

	local numGroups, numItems = 0, 0
	for _, groupPath in groupTree:SelectedGroupsIterator() do
		numGroups = numGroups + 1
		if groupPath == OC.CONST.ROOT_GROUP_PATH then
			-- TODO
		else
			for _ in OC.Groups.ItemIterator(groupPath) do
				numItems = numItems + 1
			end
		end
	end
	groupTree:GetElement("__parent.__parent.footer.groupsText")
		:SetText(format(L["%d Groups Selected"], numGroups))
	groupTree:GetElement("__parent.__parent.footer.itemsText")
		:SetText(L["Total Items"]..": "..numItems)

	groupTree:GetElement("__parent.__parent.footer")
		:Draw()
end

function private.RestockGroupsOnClick(button)
	local groups = TempTable.Acquire()
	for _, groupPath in button:GetElement("__parent.container.groupTree"):SelectedGroupsIterator() do
		tinsert(groups, groupPath)
	end
	OC.Crafting.Queue.RestockGroups(groups)
	TempTable.Release(groups)
	button:GetBaseElement():HideDialog()
end

function private.RecipeListOnRowClick(list, data, mouseButton)
	if mouseButton ~= "LeftButton" then
		return
	end
	if IsShiftKeyDown() then
		ChatEdit_InsertLink(Profession.GetRecipeLink(data))
	end
end

function private.QueueBtnOnClick(_, recipeString, quantity)
	private.fsm:ProcessEvent("EV_QUEUE_BUTTON_CLICKED", recipeString, quantity)
end

function private.CraftBtnOnMouseDown(_, recipeString, quantity, isVellum, salvageItemLocation)
	private.fsm:ProcessEvent("EV_CRAFT_BUTTON_MOUSE_DOWN", recipeString, isVellum and math.huge or quantity, salvageItemLocation)
end

function private.CraftBtnOnClick(_, recipeString, quantity, isVellum, salvageItemLocation)
	private.fsm:ProcessEvent("EV_CRAFT_BUTTON_CLICKED", recipeString, isVellum and math.huge or quantity, salvageItemLocation)
end
function private.ZhaKuangEnd()
	private.zhaKuangEndTimer:RunForFrames(1)
end
function private.CuoXianEnd()
	private.cuoXianEndTimer:RunForFrames(1)
end

function private.QueueTooltipFunc()
	local tooltipLines = TempTable.Acquire()
	tinsert(tooltipLines, Theme.GetColor("INDICATOR"):ColorText(L["Queue Summary"]))
	local totalCost, totalProfit, totalCastTime = OC.Crafting.Queue.GetTotals()
	local totalCostStr = totalCost and Money.ToString(totalCost, nil, "OPT_RETAIL_ROUND") or "---"
	local totalProfitStr =  totalProfit and Money.ToString(totalProfit, Theme.GetColor(totalProfit >= 0 and "FEEDBACK_GREEN" or "FEEDBACK_RED"):GetTextColorPrefix(), "OPT_RETAIL_ROUND") or "---"
	local totalCastTimeStr = totalCastTime and SecondsToTime(totalCastTime) or "---"
	tinsert(tooltipLines, L["Crafting Cost"]..":"..Tooltip.GetSepChar()..totalCostStr)
	tinsert(tooltipLines, L["Estimated Profit"]..":"..Tooltip.GetSepChar()..totalProfitStr)
	tinsert(tooltipLines, L["Estimated Time"]..":"..Tooltip.GetSepChar()..totalCastTimeStr)
	return strjoin("\n", TempTable.UnpackAndRelease(tooltipLines)), true, 16
end

function private.QueueOnRowMouseDown(button, data, mouseButton)
	if not private.IsPlayerProfession() or mouseButton ~= "LeftButton" then
		return
	end
	local recipeString = data:GetField("recipeString")
	local craftString = CraftString.FromRecipeString(recipeString)
	local level = CraftString.GetLevel(craftString)
	if Profession.HasCraftString(craftString) then
		OC.Crafting.ProfessionUtil.PrepareToCraft(craftString, recipeString, OC.Crafting.Queue.GetNum(recipeString), level)
	end
end

function private.QueueOnRowClick(button, data, mouseButton)
	if not private.IsPlayerProfession() then
		return
	end
	local recipeString = data:GetField("recipeString")
	local craftString = CraftString.FromRecipeString(recipeString)
	if mouseButton == "RightButton" then
		private.fsm:ProcessEvent("EV_QUEUE_RIGHT_CLICKED", craftString)
	elseif Profession.HasCraftString(craftString) then
		private.fsm:ProcessEvent("EV_CRAFT_NEXT_BUTTON_CLICKED", craftString, recipeString, OC.Crafting.Queue.GetNum(recipeString))
	end
end

function private.CraftNextOnClick(button)
	button:SetPressed(true)
	button:Draw()
	local recipeString = button:GetElement("__parent.__parent.queueList"):GetFirstData():GetField("recipeString")
	local craftString = CraftString.FromRecipeString(recipeString)
	private.fsm:ProcessEvent("EV_CRAFT_NEXT_BUTTON_CLICKED", craftString, recipeString, OC.Crafting.Queue.GetNum(recipeString))
end

function private.ClearOnClick(button)
	OC.Crafting.Queue.Clear()
	button:GetElement("__parent.__parent.header.title")
		:SetText(format(L["Queue (%d)"], 0))
		:Draw()
	button:GetElement("__parent.craftNextBtn")
		:SetDisabled(true)
		:Draw()
end

function private.FilterButtonOnClick(button)
	button:GetBaseElement():ShowMenuDialog(button._frame, private.FilterDialogIterator, button:GetBaseElement(), private.FilterDialogButtonOnClick, true)
end

function private.FilterDialogButtonOnClick(button, self, index1, index2, extra)
	assert(not extra and index1)
	if index1 == "SKILLUP" then
		private.haveSkillUp = not private.haveSkillUp
		button:SetText(Theme.GetColor(private.haveSkillUp and "TEXT" or "TEXT+DISABLED"):ColorText(L["Have Skill Ups"]))
			:Draw()
		private.fsm:ProcessEvent("EV_RECIPE_FILTER_CHANGED", private.filterText)
	elseif index1 == "MATS" then
		private.haveMaterials = not private.haveMaterials
		button:SetText(Theme.GetColor(private.haveMaterials and "TEXT" or "TEXT+DISABLED"):ColorText(L["Have Mats"]))
			:Draw()
		private.fsm:ProcessEvent("EV_RECIPE_FILTER_CHANGED", private.filterText)
	elseif index1 == "RESET" then
		self:GetBaseElement():HideDialog()
		private.haveSkillUp = false
		private.haveMaterials = false
		private.fsm:ProcessEvent("EV_RECIPE_FILTER_CHANGED", private.filterText)
	else
		error("Unexpected index1: "..tostring(index1))
	end
end

function private.FilterDialogIterator(self, prevIndex)
	if prevIndex == nil then
		return "SKILLUP", Theme.GetColor(private.haveSkillUp and "TEXT" or "TEXT+DISABLED"):ColorText(L["Have Skill Ups"])
	elseif prevIndex == "SKILLUP" then
		return "MATS", Theme.GetColor(private.haveMaterials and "TEXT" or "TEXT+DISABLED"):ColorText(L["Have Mats"])
	elseif prevIndex == "MATS" then
		return "RESET", L["Reset Filters"]
	end
end



-- ============================================================================
-- FSM
-- ============================================================================

function private.FSMCreate()
	local fsmContext = {
		frame = nil,
		recipeQuery = nil,
		professionQuery = nil,
		page = "profession",
		selectedCraftString = nil,
		queueQuery = nil,
		recipeString = nil,
		craftingType = nil,
		craftingQuantity = nil,
	}

	Profession.RegisterStateCallback(function()
		if Profession.GetCurrentProfession() and Environment.IsVanillaClassic() and CraftCreateButton then
			if Profession.IsClassicCrafting() then
				CraftCreateButton:Show()
			else
				CraftCreateButton:Hide()
			end
		end
		private.fsm:ProcessEvent("EV_PROFESSION_STATE_UPDATE")
	end)
	Profession.RegisterHasScannedCallback(function()
		private.fsm:ProcessEvent("EV_PROFESSION_STATE_UPDATE")
	end)

	local fsmPrivate = {
		success = nil,
		isDone = nil,
		recipeString=nil,
		quantity=nil,
		salvageItemLocation=nil,
		craftTimer=nil,
		continueCraftTimer=nil,
		trueCraftTimer=nil,
	}
	BagTracking.RegisterQuantityCallback(function()
		private.fsm:ProcessEvent("EV_BAG_UPDATE_DELAYED")
	end)
	fsmPrivate.craftTimer = Delay.CreateTimer("CRAFTING_CRAFT", function()
		private.fsm:ProcessEvent("EV_SPELLCAST_COMPLETE", fsmPrivate.success, fsmPrivate.isDone)
		fsmPrivate.success = nil
		fsmPrivate.isDone = nil
	end)
	fsmPrivate.continueCraftTimer = Delay.CreateTimer("CONTINUE_CRAFTING_CRAFT", function()
		private.fsm:ProcessEvent("CONTINUE_CRAFTING")
	end)
	fsmPrivate.trueCraftTimer = Delay.CreateTimer("TRUE_CRAFTING_CRAFT", function()
		private.fsm:ProcessEvent("TRUE_CRAFTING_CRAFT",fsmPrivate.recipeString, fsmPrivate.quantity, fsmPrivate.salvageItemLocation)
	end)
	private.zhaKuangEndTimer = Delay.CreateTimer("zhaKuangEndTimer", function()
		private.fsm:ProcessEvent("EV_ZHA_KUANG_END")
	end)
	private.cuoXianEndTimer = Delay.CreateTimer("cuoXianEndTimer", function()
		private.fsm:ProcessEvent("EV_CUO_XIAN_END")
	end)
	function fsmPrivate.CraftCallback(success, isDone)
		fsmPrivate.success = success
		fsmPrivate.isDone = isDone
		fsmPrivate.craftTimer:RunForFrames(1)
	end
	function fsmPrivate.QueueUpdateCallback()
		private.fsm:ProcessEvent("EV_QUEUE_UPDATE")
	end
	function fsmPrivate.SkillUpdateCallback()
		private.fsm:ProcessEvent("EV_SKILL_UPDATE")
	end
	function fsmPrivate.UpdateMaterials(context)
		context.frame:GetElement("top.left.content.recipeList")
			:UpdateData(true)
		fsmPrivate.UpdateCraftButtons(context)
	end
	function fsmPrivate.UpdateProfessionsDropdown(context)
		-- update the professions dropdown info
		local dropdownSelection = nil
		local currentProfession = Profession.GetCurrentProfession()
		local isCurrentProfessionPlayer = private.IsPlayerProfession()
		wipe(private.professions)
		wipe(private.professionsKeys)
		if currentProfession and not isCurrentProfessionPlayer then
			assert(not Environment.IsVanillaClassic())
			local playerName = nil
			local linked, linkedName = Profession.IsLinked()
			if linked then
				playerName = linkedName or "?"
			elseif Profession.IsNPC() then
				playerName = L["NPC"]
			elseif Profession.IsGuild() then
				playerName = L["Guild"]
			end
			assert(playerName)
			tinsert(private.professions, currentProfession)
			local key = currentProfession
			tinsert(private.professionsKeys, key)
			dropdownSelection = key
		end

		for _, player, profession, skillId, level, maxLevel in OC.Crafting.PlayerProfessions.Iterator() do
			if player == UnitName("player") then
				tinsert(private.professions, format("%s (%d/%d)", profession, level, maxLevel))
				local key = player..KEY_SEP..profession..KEY_SEP..skillId
				tinsert(private.professionsKeys, key)
				if isCurrentProfessionPlayer and profession == currentProfession then
					assert(not dropdownSelection)
					dropdownSelection = key
				end
			end
		end

		context.frame:GetElement("top.left.controls.professionDropdown")
			:SetItems(private.professions, private.professionsKeys)
			:SetSelectedItemByKey(dropdownSelection, true)
			:Draw()
	end
	function fsmPrivate.UpdateSkills(context)
		fsmPrivate.UpdateProfessionsDropdown(context)
	end
	function fsmPrivate.UpdateFilter(context)
		context.frame:GetElement("top.left.controls.buttons.filterBtn"):SetHighlightLocked(private.haveSkillUp or private.haveMaterials, "INDICATOR")
			:Draw()
	end
	function fsmPrivate.UpdateContentPage(context)
		fsmPrivate.UpdateProfessionsDropdown(context)

		if not private.IsProfessionLoaded() then
			return
		end

		local recipeList = context.frame:GetElement("top.left.content.recipeList")
		recipeList:SetQuery(fsmContext.recipeQuery)
		context.selectedCraftString = recipeList:GetSelection()
		local details = context.frame:GetElement("details")
		details:SetSpellId(context.selectedCraftString and CraftString.GetSpellId(context.selectedCraftString) or nil)
		if context.selectedCraftString then
			details:SetState(context.recipeString and context.craftingType or "", nil)
		end
		details:Draw()
	end
	function fsmPrivate.UpdateQueueFrame(context, noDataUpdate)
		local queueFrame = context.frame:GetElement("top.right.queue")
		queueFrame:GetElement("header.title")
			:SetText(format(L["Queue (%d)"], OC.Crafting.Queue.GetNumItems()))
		if not noDataUpdate then
			queueFrame:GetElement("queueList"):UpdateData()
		end

		local professionLoaded = private.IsProfessionLoaded()
		local nextCraftRecord = queueFrame:GetElement("queueList"):GetFirstData()
		local nextRecipeString = nextCraftRecord and nextCraftRecord:GetField("recipeString")
		local nextCraftString = nextCraftRecord and CraftString.FromRecipeString(nextRecipeString)
		if nextCraftRecord and (not professionLoaded or not Profession.HasCraftString(nextCraftString) or OC.Crafting.ProfessionUtil.GetNumCraftableRecipeString(nextRecipeString) == 0) then
			nextCraftRecord = nil
		end
		local canCraftFromQueue = professionLoaded and private.IsPlayerProfession()
		queueFrame:GetElement("footer.craftNextBtn")
			:SetDisabled(not canCraftFromQueue or not nextCraftRecord or context.recipeString)
			:SetPressed(context.recipeString and context.craftingType == "queue")
		if nextCraftRecord and canCraftFromQueue then
			local level = CraftString.GetLevel(nextCraftString)
			OC.Crafting.ProfessionUtil.PrepareToCraft(nextCraftString, nextRecipeString, nextCraftRecord:GetField("num"), level)
		end
		queueFrame:Draw()
	end
	function fsmPrivate.UpdateCraftButtons(context)
		if private.IsProfessionLoaded() and context.selectedCraftString then
			local details = context.frame:GetElement("details")
			local craftString = context.recipeString and CraftString.FromRecipeString(context.recipeString)
			local craftingQuantity = craftString and craftString == context.selectedCraftString and context.craftingQuantity or 1
			local craftingType = context.recipeString and context.craftingType
			details:SetState(craftingType or "", craftingType and craftingQuantity or nil)
			details:Draw()
		end

		local professionLoaded = private.IsProfessionLoaded()
		local nextCraftRecord = context.frame:GetElement("top.right.queue.queueList"):GetFirstData()
		local nextRecipeString = nextCraftRecord and nextCraftRecord:GetField("recipeString")
		local nextCraftString = nextCraftRecord and CraftString.FromRecipeString(nextRecipeString)
		if nextCraftRecord and (not professionLoaded or not Profession.HasCraftString(nextCraftString) or OC.Crafting.ProfessionUtil.GetNumCraftableRecipeString(nextRecipeString) == 0) then
			nextCraftRecord = nil
		end
		local canCraftFromQueue = professionLoaded and private.IsPlayerProfession()
		context.frame:GetElement("top.right.queue.footer.craftNextBtn")
			:SetDisabled(not canCraftFromQueue or not nextCraftRecord or context.recipeString)
			:SetPressed(context.recipeString and context.craftingType == "queue")
			:Draw()
	end
	function fsmPrivate.StartCraft(context, recipeString, quantity, salvageItemLocation)
		local craftString = CraftString.FromRecipeString(recipeString)
		local numCrafted = OC.Crafting.ProfessionUtil.Craft(craftString, recipeString, quantity, context.craftingType ~= "craft", salvageItemLocation, fsmPrivate.CraftCallback)
		Log.Info("Crafting %d (requested %s) of %s", numCrafted, quantity == math.huge and "all" or quantity, recipeString)
		if numCrafted == 0 then
			return
		end
		context.recipeString = recipeString
		context.craftingQuantity = numCrafted
		fsmPrivate.UpdateCraftButtons(context)
	end

	private.fsm = FSM.New("CRAFTING_UI_CRAFTING")
		:AddState(FSM.NewState("ST_FRAME_CLOSED")
			:SetOnEnter(function(context)
				context.frame = nil
				context.recipeString = nil
				context.craftingQuantity = nil
				context.craftingType = nil
				context.selectedCraftString = nil
			end)
			:AddTransition("ST_FRAME_CLOSED")
			:AddTransition("ST_FRAME_OPEN_NO_PROFESSION")
			:AddTransition("ST_FRAME_OPEN_WITH_PROFESSION")
			:AddEvent("EV_FRAME_SHOW", function(context, frame)
				context.frame = frame
				if private.IsProfessionLoaded() then
					return "ST_FRAME_OPEN_WITH_PROFESSION"
				else
					return "ST_FRAME_OPEN_NO_PROFESSION"
				end
			end)
		)
		:AddState(FSM.NewState("ST_FRAME_OPEN_NO_PROFESSION")
			:SetOnEnter(function(context)
				context.recipeString = nil
				context.craftingQuantity = nil
				context.craftingType = nil
				context.selectedCraftString = nil
				if not context.queueQuery then
					context.queueQuery = OC.Crafting.Queue.CreateQuery()
					context.queueQuery:SetUpdateCallback(fsmPrivate.QueueUpdateCallback)
				end
				fsmPrivate.UpdateContentPage(context)
				fsmPrivate.UpdateQueueFrame(context)
			end)
			:AddTransition("ST_FRAME_OPEN_NO_PROFESSION")
			:AddTransition("ST_FRAME_OPEN_WITH_PROFESSION")
			:AddTransition("ST_FRAME_CLOSED")
			:AddEvent("EV_PROFESSION_STATE_UPDATE", function(context)
				if private.IsProfessionLoaded() then
					return "ST_FRAME_OPEN_WITH_PROFESSION"
				end
				fsmPrivate.UpdateContentPage(context)
			end)
			:AddEvent("EV_QUEUE_UPDATE", function(context)
				fsmPrivate.UpdateQueueFrame(context, true)
			end)
		)
		:AddState(FSM.NewState("ST_FRAME_OPEN_WITH_PROFESSION")
			:SetOnEnter(function(context)
				context.recipeQuery = Profession.CreateScannerQuery()
					:Select("craftString", "categoryId")
					:OrderBy("index", true)
					:VirtualField("matNames", "string", OC.Crafting.GetMatNames, "craftString")
					:Equal("level", 1)
				context.professionQuery = OC.Crafting.PlayerProfessions.CreateQuery()
				context.professionQuery:SetUpdateCallback(fsmPrivate.SkillUpdateCallback)
				context.frame:GetElement("top.left.controls.filterInput")
					:SetValue("")
					:Draw()
				private.filterText = ""
				local recipeList = context.frame:GetElement("top.left.content.recipeList")
				recipeList:SetQuery(context.recipeQuery)
					:UpdateData(true)
				if context.selectedCraftString and Profession.GetIndexByCraftString(context.selectedCraftString) then
					recipeList:SetSelection(context.selectedCraftString)
				end
				fsmPrivate.UpdateContentPage(context)
				fsmPrivate.UpdateCraftButtons(context)
				fsmPrivate.UpdateFilter(context)
				fsmPrivate.UpdateQueueFrame(context)
				if not context.queueQuery then
					context.queueQuery = OC.Crafting.Queue.CreateQuery()
					context.queueQuery:SetUpdateCallback(fsmPrivate.QueueUpdateCallback)
				end
			end)
			:SetOnExit(function(context)
				private.haveSkillUp = false
				private.haveMaterials = false
				context.recipeQuery:Release()
				context.recipeQuery = nil
				context.professionQuery:Release()
				context.professionQuery = nil
				context.selectedCraftString = nil
			end)
			:AddTransition("ST_FRAME_OPEN_NO_PROFESSION")
			:AddTransition("ST_FRAME_CLOSED")
			:AddEvent("EV_PROFESSION_STATE_UPDATE", function(context)
				if not private.IsProfessionLoaded() then
					return "ST_FRAME_OPEN_NO_PROFESSION"
				end
				fsmPrivate.UpdateContentPage(context)
			end)
			:AddEvent("EV_RECIPE_FILTER_CHANGED", function(context, filter)
				local recipeList = context.frame:GetElement("top.left.content.recipeList")
				local prevSelection = recipeList:GetSelection()
				context.recipeQuery:Reset()
					:Select("craftString", "categoryId")
					:OrderBy("index", true)
					:VirtualField("matNames", "string", OC.Crafting.GetMatNames, "craftString")
					:Equal("level", 1)
				if filter ~= "" then
					filter = String.Escape(filter)
					context.recipeQuery
						:Or()
							:Matches("name", filter)
							:Matches("matNames", filter)
						:End()
				end
				if private.haveSkillUp then
					context.recipeQuery:NotEqual("difficulty", Environment.IsRetail() and Enum.TradeskillRelativeDifficulty.Trivial or "trivial")
				end
				if private.haveMaterials then
					context.recipeQuery:Custom(private.HaveMaterialsFilterHelper)
				end
				recipeList:UpdateData(true)
				fsmPrivate.UpdateFilter(context)
				if recipeList:GetSelection() ~= prevSelection then
					fsmPrivate.UpdateContentPage(context)
				end
			end)
			:AddEvent("EV_QUEUE_BUTTON_CLICKED", function(context, recipeString, quantity)
				OC.Crafting.Queue.Add(recipeString, quantity)
				fsmPrivate.UpdateQueueFrame(context, true)
			end)
			:AddEvent("EV_QUEUE_RIGHT_CLICKED", function(context, craftString)
				if OC.Crafting.GetProfession(craftString) ~= Profession.GetCurrentProfession() then
					return
				end
				local recipeList = context.frame:GetElement("top.left.content.recipeList")
				if not recipeList:IsCraftStringVisible(craftString) then
					return
				end
				recipeList:SetSelection(craftString)
				fsmPrivate.UpdateContentPage(context)
			end)
			:AddEvent("EV_RECIPE_SELECTION_CHANGED", function(context)
				fsmPrivate.UpdateContentPage(context)
				fsmPrivate.UpdateCraftButtons(context)
			end)
			:AddEvent("EV_BAG_UPDATE_DELAYED", function(context)
				fsmPrivate.UpdateQueueFrame(context)
				fsmPrivate.UpdateMaterials(context)
			end)
			:AddEvent("EV_QUEUE_UPDATE", function(context)
				fsmPrivate.UpdateQueueFrame(context, true)
			end)
			:AddEvent("EV_SKILL_UPDATE", function(context)
				fsmPrivate.UpdateSkills(context)
			end)
			:AddEvent("EV_CRAFT_BUTTON_MOUSE_DOWN", function(context, recipeString, quantity, salvageItemLocation)
				context.craftingType = quantity == math.huge and "all" or "craft"
				local craftString = CraftString.FromRecipeString(recipeString)
				OC.Crafting.ProfessionUtil.PrepareToCraft(craftString, recipeString, quantity, RecipeString.GetLevel(recipeString), salvageItemLocation)
			end)
			:AddEvent("EV_ZHA_KUANG_END", function(context)
				local recipeList = context.frame:GetElement("top.left.content.recipeList")
				recipeList:SetSelection("c:395696")
				fsmPrivate.UpdateContentPage(context)
			end)
			:AddEvent("EV_CUO_XIAN_END", function(context)
				local recipeList = context.frame:GetElement("top.left.content.recipeList")
				recipeList:SetSelection("c:376509:q5")
				fsmPrivate.UpdateContentPage(context)
			end)
			:AddEvent("EV_CRAFT_BUTTON_CLICKED", function(context, recipeString, quantity, salvageItemLocation)
				context.craftingType = quantity == math.huge and "all" or "craft"
				fsmPrivate.StartCraft(context, recipeString, quantity, salvageItemLocation)
				--context.craftingType = quantity == math.huge and "all" or "craft"
				--local craftString = CraftString.FromRecipeString(recipeString)
				--OC.Crafting.ProfessionUtil.PrepareToCraft(craftString, recipeString, quantity, RecipeString.GetLevel(recipeString), salvageItemLocation)
				--fsmPrivate.recipeString=recipeString
				--fsmPrivate.quantity=quantity
				--fsmPrivate.salvageItemLocation=salvageItemLocation
				--fsmPrivate.trueCraftTimer:RunForFrames(3)
			end)
			:AddEvent("TRUE_CRAFTING_CRAFT", function(context, recipeString, quantity, salvageItemLocation)

			end)
			:AddEvent("EV_CRAFT_NEXT_BUTTON_CLICKED", function(context, craftString, recipeString, quantity)
				if context.recipeString then
					-- already crafting something
					return
				end
				if Profession.NeededTools(craftString) or OC.Crafting.ProfessionUtil.GetNumCraftableRecipeString(recipeString) == 0 or Profession.GetRemainingCooldown(craftString) then
					-- can't craft this
					return
				end
				context.craftingType = "queue"
				fsmPrivate.StartCraft(context, recipeString, quantity)
			end)
			:AddEvent("EV_SPELLCAST_COMPLETE", function(context, success, isDone)
				if success and context.recipeString then
					Log.Info("Crafted %s", context.recipeString)
					OC.Crafting.Queue.Remove(context.recipeString, 1)
					context.craftingQuantity = context.craftingQuantity - 1
					assert(context.craftingQuantity >= 0)
					if context.craftingQuantity == 0 then
						assert(isDone)
						context.recipeString = nil
						context.craftingQuantity = nil
						context.craftingType = nil
						--fsmPrivate.continueCraftTimer:RunForTime(1)
					end
				else
					context.recipeString = nil
					context.craftingQuantity = nil
					context.craftingType = nil
				end
				fsmPrivate.UpdateCraftButtons(context)
				fsmPrivate.UpdateQueueFrame(context, true)
			end)
			:AddEvent("CONTINUE_CRAFTING",function(context)
				local quantity=max(tonumber(private.professionFrame:GetElement("details.content.buttons.quantity.input"):GetValue()), 1)
				context.craftingType = quantity == math.huge and "all" or "craft"
				local recipeString=private.craftDetails:GetRecipeString();
				local salvageItemLocation=private.professionFrame:GetElement("details.content.selection.content.itemSelector"):GetNextSalvageSlotId()
				local craftString = CraftString.FromRecipeString(recipeString)
				OC.Crafting.ProfessionUtil.PrepareToCraft(craftString, recipeString, quantity, RecipeString.GetLevel(recipeString), salvageItemLocation)
				fsmPrivate.StartCraft(context,recipeString,
						quantity,salvageItemLocation
				)
			end)
		)
		:AddDefaultEventTransition("EV_FRAME_HIDE", "ST_FRAME_CLOSED")
		:Init("ST_FRAME_CLOSED", fsmContext)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.IsProfessionLoaded()
	return not Profession.IsClosed() and Profession.GetCurrentProfession() and Profession.HasScanned() and Profession.ScannerHasSkills()
end

function private.IsPlayerProfession()
	return not (Profession.IsNPC() or Profession.IsLinked() or Profession.IsGuild())
end

function private.HaveMaterialsFilterHelper(row)
	return OC.Crafting.ProfessionUtil.IsCraftable(row:GetField("craftString"))
end

function private.ItemLinkedCallback(name, itemLink)
	if not private.professionFrame then
		return
	end
	local input = private.professionFrame:GetElement("top.left.controls.filterInput")
	input:SetValue(ItemInfo.GetName(ItemString.GetBase(itemLink)))
		:SetFocused(false)
		:Draw()

	private.FilterInputOnValueChanged(input)
	return true
end
