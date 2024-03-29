-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local General = OC.MainUI.Settings:NewPackage("General")
local Environment = OC.Include("Environment")
local L = OC.Include("Locale").GetTable()
local Log = OC.Include("Util.Log")
local TempTable = OC.Include("Util.TempTable")
local Table = OC.Include("Util.Table")
local Theme = OC.Include("Util.Theme")
local Wow = OC.Include("Util.Wow")
local Settings = OC.Include("Service.Settings")
local Sync = OC.Include("Service.Sync")
local PlayerInfo = OC.Include("Service.PlayerInfo")
local Tooltip = OC.Include("UI.Tooltip")
local UIElements = OC.Include("UI.UIElements")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	settings = nil,
	frame = nil,
	characterList = {},
	characterKeys = {},
	guildList = {},
	chatFrameList = {},
}
local CHARACTER_SEP = "\001"



-- ============================================================================
-- Module Functions
-- ============================================================================

function General.OnInitialize()
	private.settings = Settings.NewView()
		:AddKey("global", "coreOptions", "regionWide")
		:AddKey("global", "coreOptions", "globalOperations")
		:AddKey("global", "coreOptions", "protectAuctionHouse")
		:AddKey("global", "coreOptions", "chatFrame")
		:AddKey("factionrealm", "coreOptions", "ignoreGuilds")
	OC.MainUI.Settings.RegisterSettingPage(L["General Settings"], "top", private.GetGeneralSettingsFrame)
	Sync.RegisterConnectionChangedCallback(private.SyncConnectionChangedCallback)
end



-- ============================================================================
-- General Settings UI
-- ============================================================================

function private.GetGeneralSettingsFrame()
	UIUtils.AnalyticsRecordPathChange("main", "settings", "general")
	wipe(private.chatFrameList)
	local defaultChatFrame = nil
	for i = 1, NUM_CHAT_WINDOWS do
		local name = strlower(GetChatWindowInfo(i) or "")
		if DEFAULT_CHAT_FRAME == _G["ChatFrame"..i] then
			defaultChatFrame = name
		end
		if name ~= "" and _G["ChatFrame"..i.."Tab"]:IsVisible() then
			tinsert(private.chatFrameList, name)
		end
	end
	if not tContains(private.chatFrameList, private.settings.chatFrame) then
		if tContains(private.chatFrameList, defaultChatFrame) then
			private.settings.chatFrame = defaultChatFrame
			Log.SetChatFrame(defaultChatFrame)
		else
			-- all chat frames are hidden, so just disable the setting
			wipe(private.chatFrameList)
		end
	end

	wipe(private.characterList)
	wipe(private.characterKeys)
	for _, character, factionrealm in PlayerInfo.CharacterIterator(true) do
		if not Wow.IsPlayer(character, factionrealm) then
			tinsert(private.characterKeys, character..CHARACTER_SEP..factionrealm)
			tinsert(private.characterList, Wow.FormatCharacterName(character, factionrealm))
		end
	end

	wipe(private.guildList)
	for _, guild in PlayerInfo.GuildIterator(true) do
		tinsert(private.guildList, guild)
	end

	return UIElements.New("ScrollFrame", "generalSettings")
		:SetPadding(8, 8, 8, 0)
		:SetScript("OnUpdate", private.FrameOnUpdate)
		:SetScript("OnHide", private.FrameOnHide)
		:AddChild(OC.MainUI.Settings.CreateExpandableSection("General", "general", L["General Options"], L["Some general OC options are below."])
			:AddChildIf(Environment.HasFeature(Environment.FEATURES.REGION_WIDE_TRADING), UIElements.New("Frame", "check1")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Checkbox", "regionWide")
					:SetWidth("AUTO")
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Enable region-wide trading (requires reload)"])
					:SetSettingInfo(private.settings, "regionWide")
					:SetScript("OnValueChanged", private.RegionWideOnValueChanged)
					:SetTooltip(L["If enabled, OC will load data (i.e. inventory / Accounting / gold tracking) from every realm you have characters on, instead of just connected realms."])
				)
				:AddChild(UIElements.New("Spacer", "spacer"))
			)
			:AddChild(UIElements.New("Frame", "check2")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Checkbox", "globalOperations")
					:SetWidth("AUTO")
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Share operations between all profiles"])
					:SetChecked(OC.Operations.IsStoredGlobally())
					:SetScript("OnValueChanged", private.GlobalOperationsOnValueChanged)
				)
				:AddChild(UIElements.New("Spacer", "spacer"))
			)
			:AddChildIf(not Environment.IsRetail(), UIElements.New("Frame", "check3")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:SetMargin(0, 0, 0, 12)
				:AddChild(UIElements.New("Checkbox", "protectAuctionHouse")
					:SetWidth("AUTO")
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Prevent closing the Auction House with the esc key"])
					:SetSettingInfo(private.settings, "protectAuctionHouse")
				)
				:AddChild(UIElements.New("Spacer", "spacer"))
			)
			:AddChild(OC.MainUI.Settings.CreateInputWithReset("generalGroupPriceField", L["Filter group item lists based on the following price source"], "global.coreOptions.groupPriceSource"))
			:AddChild(UIElements.New("Frame", "dropdownLabelLine")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:SetMargin(0, 0, 12, 4)
				:AddChild(UIElements.New("Text", "chatTabLabel")
					:SetMargin(0, 12, 0, 0)
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Chat Tab"])
				)
				:AddChild(UIElements.New("Text", "forgetLabel")
					:SetMargin(0, 12, 0, 0)
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Forget Character"])
				)
				:AddChild(UIElements.New("Text", "ignoreLabel")
					:SetFont("BODY_BODY2_MEDIUM")
					:SetText(L["Ignore Guilds"])
				)
			)
			:AddChild(UIElements.New("Frame", "dropdownLabelLine")
				:SetLayout("HORIZONTAL")
				:SetHeight(24)
				:AddChild(UIElements.New("SelectionDropdown", "chatTabDropdown")
					:SetMargin(0, 16, 0, 0)
					:SetItems(private.chatFrameList, private.chatFrameList)
					:SetSettingInfo(next(private.chatFrameList) and private.settings or nil, "chatFrame")
					:SetScript("OnSelectionChanged", private.ChatTabOnSelectionChanged)
				)
				:AddChild(UIElements.New("SelectionDropdown", "forgetDropdown")
					:SetMargin(0, 16, 0, 0)
					:SetItems(private.characterList, private.characterKeys)
					:SetScript("OnSelectionChanged", private.ForgetCharacterOnSelectionChanged)
				)
				:AddChild(UIElements.New("MultiselectionDropdown", "ignoreDropdown")
					:SetItems(private.guildList, private.guildList)
					:SetSettingInfo(private.settings, "ignoreGuilds")
					:SetSelectionText(L["No Guilds"], L["%d Guilds"], L["All Guilds"])
				)
			)
		)
		:AddChild(OC.MainUI.Settings.CreateExpandableSection("General", "profiles", L["Profiles"], L["Set your active profile or create a new one."])
			:AddChildrenWithFunction(private.AddProfileRows)
			:AddChild(UIElements.New("Text", "profileLabel")
				:SetHeight(20)
				:SetMargin(0, 0, 4, 4)
				:SetFont("BODY_BODY2_MEDIUM")
				:SetText(L["Create new profile"])
			)
			:AddChild(UIElements.New("Input", "newProfileInput")
				:SetHeight(24)
				:SetBackgroundColor("ACTIVE_BG")
				:SetHintText(L["Enter profile name"])
				:SetMaxLetters(64)
				:SetScript("OnEnterPressed", private.NewProfileInputOnEnterPressed)
			)
		)
		:AddChild(OC.MainUI.Settings.CreateExpandableSection("General", "accountSync", L["Account Syncing"], L["OC can automatically sync data between multiple WoW accounts."])
			:AddChildrenWithFunction(private.AddAccountSyncRows)
			:AddChild(UIElements.New("Text", "profileLabel")
				:SetHeight(20)
				:SetMargin(0, 0, 4, 4)
				:SetFont("BODY_BODY2_MEDIUM")
				:SetText(L["Add account"])
			)
			:AddChild(UIElements.New("Input", "newProfileInput")
				:SetHeight(24)
				:SetBackgroundColor("ACTIVE_BG")
				:SetHintText(L["Enter name of logged-in character on other account"])
				:SetScript("OnEnterPressed", private.NewAccountSyncInputOnEnterPressed)
			)
		)
end

function private.AddProfileRows(frame)
	for index, profileName in OC.db:ScopeKeyIterator("profile") do
		local isCurrentProfile = profileName == OC.db:GetCurrentProfile()
		local row = UIElements.New("Frame", "profileRow_"..index)
			:SetLayout("HORIZONTAL")
			:SetHeight(28)
			:SetMargin(0, 0, 0, 8)
			:SetPadding(8, 8, 4, 4)
			:SetRoundedBackgroundColor(isCurrentProfile and "ACTIVE_BG" or "PRIMARY_BG_ALT")
			:SetContext(profileName)
			:SetScript("OnEnter", private.ProfileRowOnEnter)
			:SetScript("OnLeave", private.ProfileRowOnLeave)
			:AddChild(UIElements.New("Frame", "content")
				:SetLayout("HORIZONTAL")
				:SetHeight(20)
				:AddChild(UIElements.New("Checkbox", "checkbox")
					:SetText(profileName)
					:SetFont("BODY_BODY2")
					:SetChecked(isCurrentProfile)
					:SetScript("OnValueChanged", private.ProfileCheckboxOnValueChanged)
					:PropagateScript("OnEnter")
					:PropagateScript("OnLeave")
				)
				:PropagateScript("OnEnter")
				:PropagateScript("OnLeave")
			)
			:AddChild(UIElements.New("Button", "resetBtn")
				:SetBackgroundAndSize("iconPack.18x18/Reset")
				:SetMargin(4, 0, 0, 0)
				:SetScript("OnClick", private.ResetProfileOnClick)
				:SetScript("OnEnter", private.ResetProfileOnEnter)
				:SetScript("OnLeave", private.ResetProfileOnLeave)
			)
			:AddChild(UIElements.New("Button", "renameBtn")
				:SetBackgroundAndSize("iconPack.18x18/Edit")
				:SetMargin(4, 0, 0, 0)
				:SetScript("OnClick", private.RenameProfileOnClick)
				:SetScript("OnEnter", private.RenameProfileOnEnter)
				:SetScript("OnLeave", private.RenameProfileOnLeave)
			)
			:AddChild(UIElements.New("Button", "duplicateBtn")
				:SetBackgroundAndSize("iconPack.18x18/Duplicate")
				:SetMargin(4, 0, 0, 0)
				:SetScript("OnClick", private.DuplicateProfileOnClick)
				:SetScript("OnEnter", private.DuplicateProfileOnEnter)
				:SetScript("OnLeave", private.DuplicateProfileOnLeave)
			)
			:AddChild(UIElements.New("Button", "deleteBtn")
				:SetBackgroundAndSize("iconPack.18x18/Delete")
				:SetMargin(4, 0, 0, 0)
				:SetScript("OnClick", private.DeleteProfileOnClick)
				:SetScript("OnEnter", private.DeleteProfileOnEnter)
				:SetScript("OnLeave", private.DeleteProfileOnLeave)
			)
		row:GetElement("deleteBtn"):Hide()
		if not isCurrentProfile then
			row:GetElement("resetBtn"):Hide()
			row:GetElement("renameBtn"):Hide()
			row:GetElement("duplicateBtn"):Hide()
		end
		frame:AddChild(row)
	end
end

function private.AddAccountSyncRows(frame)
	local newAccountStatusText = Sync.GetNewAccountStatus()
	if newAccountStatusText then
		local row = private.CreateAccountSyncRow("new", newAccountStatusText)
		row:GetElement("sendProfileBtn"):Hide()
		row:GetElement("removeBtn"):Hide()
		frame:AddChild(row)
	end

	for _, account in OC.db:SyncAccountIterator() do
		local characters = TempTable.Acquire()
		for _, character in Settings.CharacterByAccountFactionrealmIterator(account) do
			tinsert(characters, character)
		end
		sort(characters)
		local isConnected, connectedCharacter = Sync.GetConnectionStatus(account)
		local statusText = nil
		if isConnected then
			statusText = Theme.GetColor("FEEDBACK_GREEN"):ColorText(format(L["Connected to %s"], connectedCharacter))
		else
			statusText = Theme.GetColor("FEEDBACK_RED"):ColorText(L["Offline"])
		end
		statusText = statusText.." | "..table.concat(characters, ", ")
		TempTable.Release(characters)

		local row = private.CreateAccountSyncRow("accountSyncRow_"..account, statusText)
		row:SetContext(account)
		row:GetElement("sendProfileBtn"):Hide()
		row:GetElement("removeBtn"):Hide()
		frame:AddChild(row)
	end
end

function private.CreateAccountSyncRow(id, statusText)
	local row = UIElements.New("Frame", id)
		:SetLayout("HORIZONTAL")
		:SetHeight(28)
		:SetMargin(0, 0, 0, 8)
		:SetPadding(8, 8, 4, 4)
		:SetRoundedBackgroundColor("PRIMARY_BG_ALT")
		:SetScript("OnEnter", private.AccountSyncRowOnEnter)
		:SetScript("OnLeave", private.AccountSyncRowOnLeave)
		:AddChild(UIElements.New("Text", "status")
			:SetFont("BODY_BODY2")
			:SetText(statusText)
			:SetScript("OnEnter", private.AccountSyncTextOnEnter)
			:SetScript("OnLeave", private.AccountSyncTextOnLeave)
		)
		:AddChild(UIElements.New("Button", "sendProfileBtn")
			:SetBackgroundAndSize("iconPack.18x18/Operation")
			:SetMargin(4, 0, 0, 0)
			:SetScript("OnClick", private.SendProfileOnClick)
			:SetScript("OnEnter", private.SendProfileOnEnter)
			:SetScript("OnLeave", private.SendProfileOnLeave)
		)
		:AddChild(UIElements.New("Button", "removeBtn")
			:SetBackgroundAndSize("iconPack.18x18/Delete")
			:SetMargin(4, 0, 0, 0)
			:SetScript("OnClick", private.RemoveAccountSyncOnClick)
			:SetScript("OnEnter", private.RemoveAccountOnEnter)
			:SetScript("OnLeave", private.RemoveAccountOnLeave)
		)
	return row
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.SyncConnectionChangedCallback()
	if private.frame then
		private.frame:GetParentElement():ReloadContent()
	end
end

function private.FrameOnUpdate(frame)
	frame:SetScript("OnUpdate", nil)
	private.frame = frame
end

function private.FrameOnHide(frame)
	private.frame = nil
end

function private.RegionWideOnValueChanged()
	ReloadUI()
end

function private.GlobalOperationsOnValueChanged(checkbox, value)
	-- restore the previous value until it's confirmed
	checkbox:SetChecked(not value, true)
	local desc = L["If you have multiple profiles set up with operations, enabling this will cause all but the current profile's operations to be irreversibly lost."]
	checkbox:GetBaseElement():ShowConfirmationDialog(L["Make Operations Global?"], desc, private.GlobalOperationsConfirmed, checkbox, value)
end

function private.GlobalOperationsConfirmed(checkbox, newValue)
	checkbox:SetChecked(newValue, true)
		:Draw()
	OC.Operations.SetStoredGlobally(newValue)
end

function private.ChatTabOnSelectionChanged(dropdown)
	Log.SetChatFrame(dropdown:GetSelectedItem())
end

function private.ForgetCharacterOnSelectionChanged(self)
	local key = self:GetSelectedItemKey()
	if not key then
		return
	end
	local character, factionrealm = strsplit(CHARACTER_SEP, key)
	OC.db:RemoveSyncCharacter(character, factionrealm)
	local pendingMail = OC.db:Get("factionrealm", factionrealm, "internalData", "pendingMail")
	if pendingMail then
		pendingMail[character] = nil
	end
	local characterGuilds = OC.db:Get("factionrealm", factionrealm, "internalData", "characterGuilds")
	if characterGuilds then
		characterGuilds[character] = nil
	end
	Log.PrintfUser(L["%s removed."], Wow.FormatCharacterName(character, factionrealm))
	local index = Table.KeyByValue(private.characterKeys, key)
	assert(index)
	tremove(private.characterList, index)
	tremove(private.characterKeys, index)
	self:SetSelectedItem(nil)
		:SetItems(private.characterList, private.characterKeys)
		:Draw()
end

function private.ProfileRowOnEnter(frame)
	local isCurrentProfile = frame:GetContext() == OC.db:GetCurrentProfile()
	frame:SetRoundedBackgroundColor("ACTIVE_BG")
	if not isCurrentProfile then
		frame:GetElement("resetBtn"):Show()
		frame:GetElement("renameBtn"):Show()
		frame:GetElement("duplicateBtn"):Show()
		frame:GetElement("deleteBtn"):Show()
	end
	frame:Draw()
end

function private.ProfileRowOnLeave(frame)
	local isCurrentProfile = frame:GetContext() == OC.db:GetCurrentProfile()
	frame:SetRoundedBackgroundColor(isCurrentProfile and "ACTIVE_BG" or "PRIMARY_BG_ALT")
	if not isCurrentProfile then
		frame:GetElement("resetBtn"):Hide()
		frame:GetElement("renameBtn"):Hide()
		frame:GetElement("duplicateBtn"):Hide()
		frame:GetElement("deleteBtn"):Hide()
	end
	frame:Draw()
end

function private.ProfileCheckboxOnValueChanged(checkbox, value)
	if not value then
		-- can't uncheck profile checkboxes
		checkbox:SetChecked(true, true)
		checkbox:Draw()
		return
	end
	-- uncheck the current profile row
	local currentProfileIndex = nil
	for index, profileName in OC.db:ScopeKeyIterator("profile") do
		if profileName == OC.db:GetCurrentProfile() then
			assert(not currentProfileIndex)
			currentProfileIndex = index
		end
	end
	local prevRow = checkbox:GetElement("__parent.__parent.__parent.profileRow_"..currentProfileIndex)
	prevRow:GetElement("content.checkbox")
		:SetChecked(false, true)
	prevRow:GetElement("resetBtn"):Hide()
	prevRow:GetElement("renameBtn"):Hide()
	prevRow:GetElement("duplicateBtn"):Hide()
	prevRow:GetElement("deleteBtn"):Hide()
	prevRow:SetRoundedBackgroundColor("PRIMARY_BG_ALT")
	prevRow:Draw()
	-- set the profile
	OC.db:SetProfile(checkbox:GetText())
	-- set this row as the current one
	local newRow = checkbox:GetElement("__parent.__parent")
	newRow:SetRoundedBackgroundColor("ACTIVE_BG")
	newRow:GetElement("resetBtn"):Show()
	newRow:GetElement("renameBtn"):Show()
	newRow:GetElement("duplicateBtn"):Show()
	newRow:GetElement("deleteBtn"):Hide()
	newRow:Draw()
end

function private.RenameProfileOnClick(button)
	local profileName = button:GetParentElement():GetContext()
	local dialogFrame = UIElements.New("Frame", "frame")
		:SetLayout("VERTICAL")
		:SetSize(600, 187)
		:AddAnchor("CENTER")
		:SetBackgroundColor("FRAME_BG")
		:SetBorderColor("ACTIVE_BG")
		:AddChild(UIElements.New("Text", "title")
			:SetHeight(44)
			:SetMargin(16, 16, 24, 16)
			:SetFont("BODY_BODY2_BOLD")
			:SetJustifyH("CENTER")
			:SetText(L["Rename Profile"])
		)
		:AddChild(UIElements.New("Input", "nameInput")
			:SetHeight(26)
			:SetMargin(16, 16, 0, 25)
			:SetBackgroundColor("PRIMARY_BG_ALT")
			:SetContext(profileName)
			:SetValue(profileName)
			:SetScript("OnEnterPressed", private.RenameProfileInputOnEnterPressed)
		)
		:AddChild(UIElements.New("Frame", "buttons")
			:SetLayout("HORIZONTAL")
			:SetMargin(16, 16, 0, 16)
			:AddChild(UIElements.New("Spacer", "spacer"))
			:AddChild(UIElements.New("ActionButton", "closeBtn")
				:SetSize(126, 26)
				:SetText(CLOSE)
				:SetScript("OnClick", private.DialogCloseBtnOnClick)
			)
		)
	button:GetBaseElement():ShowDialogFrame(dialogFrame)
	dialogFrame:GetElement("nameInput"):SetFocused(true)
end

function private.DialogCloseBtnOnClick(button)
	private.RenameProfileInputOnEnterPressed(button:GetElement("__parent.__parent.nameInput"))
end

function private.RenameProfileInputOnEnterPressed(input)
	local profileName = input:GetValue()
	local prevProfileName = input:GetContext()
	if profileName == prevProfileName then
		-- just hide the dialog
		local baseElement = input:GetBaseElement()
		baseElement:HideDialog()
		baseElement:GetElement("content.settings.contentFrame.content"):ReloadContent()
		return
	elseif not OC.db:IsValidProfileName(profileName) then
		Log.PrintUser(L["This is not a valid profile name. Profile names must be at least one character long and may not contain '@' characters."])
		return
	elseif OC.db:ProfileExists(profileName) then
		Log.PrintUser(L["A profile with this name already exists."])
		return
	end

	-- create a new profile, copy over the settings, then delete the old one
	local currentProfileName = OC.db:GetCurrentProfile()
	OC.db:SetProfile(profileName)
	OC.db:CopyProfile(prevProfileName)
	OC.db:DeleteProfile(prevProfileName, profileName)
	if currentProfileName ~= prevProfileName then
		OC.db:SetProfile(currentProfileName)
	end

	-- hide the dialog and refresh the settings content
	local baseElement = input:GetBaseElement()
	baseElement:HideDialog()
	baseElement:GetElement("content.settings.contentFrame.content"):ReloadContent()
end

function private.RenameProfileOnEnter(button)
	button:ShowTooltip(L["Rename the profile"])
	private.ProfileRowOnEnter(button:GetParentElement())
end

function private.RenameProfileOnLeave(button)
	Tooltip.Hide()
	private.ProfileRowOnLeave(button:GetParentElement())
end

function private.DuplicateProfileOnClick(button)
	local profileName = button:GetParentElement():GetContext()
	local newName = profileName
	while OC.db:ProfileExists(newName) do
		newName = newName.." Copy"
	end
	local activeProfile = OC.db:GetCurrentProfile()
	OC.db:SetProfile(newName)
	OC.db:CopyProfile(profileName)
	OC.db:SetProfile(activeProfile)
	button:GetBaseElement():GetElement("content.settings.contentFrame.content"):ReloadContent()
end

function private.DuplicateProfileOnEnter(button)
	button:ShowTooltip(L["Duplicate the profile"])
	private.ProfileRowOnEnter(button:GetParentElement())
end

function private.DuplicateProfileOnLeave(button)
	Tooltip.Hide()
	private.ProfileRowOnLeave(button:GetParentElement())
end

function private.ResetProfileOnClick(button)
	local profileName = button:GetParentElement():GetContext()
	local desc = format(L["This will reset all groups and operations (if not stored globally) to be wiped from '%s'."], profileName)
	button:GetBaseElement():ShowConfirmationDialog(L["Reset Profile?"], desc, private.ResetProfileConfirmed, profileName)
end

function private.ResetProfileConfirmed(profileName)
	local activeProfile = OC.db:GetCurrentProfile()
	OC.db:SetProfile(profileName)
	OC.db:ResetProfile()
	OC.db:SetProfile(activeProfile)
end

function private.ResetProfileOnEnter(button)
	button:ShowTooltip(L["Reset the current profile to default settings"])
	private.ProfileRowOnEnter(button:GetParentElement())
end

function private.ResetProfileOnLeave(button)
	Tooltip.Hide()
	private.ProfileRowOnLeave(button:GetParentElement())
end

function private.DeleteProfileOnClick(button)
	local profileName = button:GetParentElement():GetContext()
	local desc = format(L["This will permanently delete the '%s' profile."], profileName)
	button:GetBaseElement():ShowConfirmationDialog(L["Delete Profile?"], desc, private.DeleteProfileConfirmed, button, profileName)
end

function private.DeleteProfileConfirmed(button, profileName)
	OC.db:DeleteProfile(profileName)
	button:GetBaseElement():GetElement("content.settings.contentFrame.content"):ReloadContent()
end

function private.DeleteProfileOnEnter(button)
	button:ShowTooltip(L["Delete the profile"])
	private.ProfileRowOnEnter(button:GetParentElement())
end

function private.DeleteProfileOnLeave(button)
	Tooltip.Hide()
	private.ProfileRowOnLeave(button:GetParentElement())
end

function private.NewProfileInputOnEnterPressed(input)
	local profileName = input:GetValue()
	if not OC.db:IsValidProfileName(profileName) then
		Log.PrintUser(L["This is not a valid profile name. Profile names must be at least one character long and may not contain '@' characters."])
		return
	elseif OC.db:ProfileExists(profileName) then
		Log.PrintUser(L["A profile with this name already exists."])
		return
	end
	OC.db:SetProfile(profileName)
	input:GetBaseElement():GetElement("content.settings.contentFrame.content"):ReloadContent()
end

function private.AccountSyncRowOnEnter(frame)
	local account = frame:GetContext()
	if account then
		frame:GetElement("sendProfileBtn"):Show()
		frame:GetElement("removeBtn"):Show()
	end
	frame:SetRoundedBackgroundColor("ACTIVE_BG")
	frame:Draw()
end

function private.AccountSyncRowOnLeave(frame)
	frame:SetRoundedBackgroundColor("PRIMARY_BG_ALT")
	frame:GetElement("sendProfileBtn"):Hide()
	frame:GetElement("removeBtn"):Hide()
	frame:Draw()
end

function private.AccountSyncTextOnEnter(text)
	local account = text:GetParentElement():GetContext()
	local tooltipLines = TempTable.Acquire()
	if account then
		tinsert(tooltipLines, Theme.GetColor("INDICATOR"):ColorText(L["Sync Status"]))
		local mirrorConnected, mirrorSynced = Sync.GetMirrorStatus(account)
		local mirrorStatus = nil
		if not mirrorConnected then
			mirrorStatus = Theme.GetColor("FEEDBACK_RED"):ColorText(L["Not Connected"])
		elseif not mirrorSynced then
			mirrorStatus = Theme.GetColor("FEEDBACK_YELLOW"):ColorText(L["Updating"])
		else
			mirrorStatus = Theme.GetColor("FEEDBACK_GREEN"):ColorText(L["Up to date"])
		end
		tinsert(tooltipLines, L["Inventory / Gold Graph"]..Tooltip.GetSepChar()..mirrorStatus)
		tinsert(tooltipLines, L["Profession Info"]..Tooltip.GetSepChar()..OC.Crafting.Sync.GetStatus(account))
		tinsert(tooltipLines, L["Purchase / Sale Info"]..Tooltip.GetSepChar()..OC.Accounting.Sync.GetStatus(account))
	else
		tinsert(tooltipLines, L["Establishing connection..."])
	end
	text:ShowTooltip(table.concat(tooltipLines, "\n"), nil, 52)
	TempTable.Release(tooltipLines)
	private.AccountSyncRowOnEnter(text:GetParentElement())
end

function private.AccountSyncTextOnLeave(text)
	Tooltip.Hide()
	private.AccountSyncRowOnLeave(text:GetParentElement())
end

function private.SendProfileOnClick(button)
	local player = Sync.GetConnectedCharacterByAccount(button:GetParentElement():GetContext())
	if not player then
		return
	end
	OC.Groups.Sync.SendCurrentProfile(player)
end

function private.SendProfileOnEnter(button)
	button:ShowTooltip(L["Send your active profile to this synced account"])
	private.AccountSyncRowOnEnter(button:GetParentElement())
end

function private.SendProfileOnLeave(button)
	Tooltip.Hide()
	private.AccountSyncRowOnLeave(button:GetParentElement())
end

function private.RemoveAccountSyncOnClick(button)
	Sync.RemoveAccount(button:GetParentElement():GetContext())
	button:GetBaseElement():GetElement("content.settings.contentFrame.content"):ReloadContent()
	Tooltip.Hide()
	Log.PrintUser(L["Account sync removed. Please delete the account sync from the other account as well."])
end

function private.RemoveAccountOnEnter(button)
	button:ShowTooltip(L["Remove this account sync and all synced data from this account"])
	private.AccountSyncRowOnEnter(button:GetParentElement())
end

function private.RemoveAccountOnLeave(button)
	Tooltip.Hide()
	private.AccountSyncRowOnLeave(button:GetParentElement())
end

function private.NewAccountSyncInputOnEnterPressed(input)
	local character = Ambiguate(input:GetValue(), "none")
	if Sync.EstablishConnection(character) then
		Log.PrintfUser(L["Establishing connection to %s. Make sure that you've entered this character's name on the other account."], character)
		private.SyncConnectionChangedCallback()
	else
		input:SetValue("")
		input:Draw()
	end
end
