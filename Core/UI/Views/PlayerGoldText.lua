-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local PlayerGoldText = OC.UI.Views:NewPackage("PlayerGoldText") ---@class OC.UI.Views.PlayerGoldText
local L = OC.Include("Locale").GetTable()
local Event = OC.Include("Util.Event")
local TempTable = OC.Include("Util.TempTable")
local Money = OC.Include("Util.Money")
local Wow = OC.Include("Util.Wow")
local Settings = OC.Include("Service.Settings")
local UIElements = OC.Include("UI.UIElements")
local Tooltip = OC.Include("UI.Tooltip")
local private = {
	settings = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function PlayerGoldText.OnInitialize()
	private.settings = Settings.NewView()
		:AddKey("global", "coreOptions", "regionWide")
		:AddKey("global", "appearanceOptions", "showTotalMoney")
		:AddKey("sync", "internalData", "money")
end

---Creates a new player gold text element.
---@param id string The id to assign to the element
---@return Button @The element
function PlayerGoldText.New(id)
	local text = UIElements.New("Button", id)
		:SetJustifyH("RIGHT")
		:SetFont("TABLE_TABLE1")
		:SetText(private.GetText())
		:SetTooltip(private.TooltipFunc)
	text:AddCancellable(Event.GetPublisher("PLAYER_MONEY")
		:MapWithFunction(private.GetText)
		:CallMethod(text, "SetText")
	)
	return text
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.GetText()
	local amount = private.settings.money
	if private.settings.showTotalMoney then
		for _, money, character, factionrealm, _, isConnected in private.settings:AccessibleValueIterator("money") do
			if (isConnected or private.settings.regionWide) and money > 0 and not Wow.IsPlayer(character, factionrealm) then
				amount = amount + money
			end
		end
	end
	return Money.ToString(amount, nil, "OPT_RETAIL_ROUND")
end

function private.TooltipFunc()
	local tooltipLines = TempTable.Acquire()
	local playerMoney = private.settings.money
	local total = playerMoney
	tinsert(tooltipLines, private.GetTooltipLine(Wow.GetCharacterName(), playerMoney))
	local numPosted, numSold, postedGold, soldGold = OC.MyAuctions.GetAuctionInfo()
	if numPosted then
		tinsert(tooltipLines, private.GetTooltipLine(format("  "..L["%s Sold Auctions"], numSold), soldGold))
		tinsert(tooltipLines, private.GetTooltipLine(format("  "..L["%s Posted Auctions"], numPosted), postedGold))
	end
	for _, money, character, factionrealm, _, isConnected in private.settings:AccessibleValueIterator("money") do
		if (isConnected or private.settings.regionWide) and money > 0 and not Wow.IsPlayer(character, factionrealm) then
			character = Wow.FormatCharacterName(character, factionrealm)
			tinsert(tooltipLines, private.GetTooltipLine(character, money))
			total = total + money
		end
	end
	tinsert(tooltipLines, 1, private.GetTooltipLine(L["Total Gold"], total))
	return strjoin("\n", TempTable.UnpackAndRelease(tooltipLines))
end

function private.GetTooltipLine(label, value)
	return strjoin(Tooltip.GetSepChar(), label..":", Money.ToString(value, nil, "OPT_RETAIL_ROUND"))
end
