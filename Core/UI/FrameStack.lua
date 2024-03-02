-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

--- FrameStack Functions
-- @module FrameStack

local OC = select(2, ...) ---@type OC
local FrameStack = OC.UI:NewPackage("FrameStack")
local Math = OC.Include("Util.Math")
local Theme = OC.Include("Util.Theme")
local Table = OC.Include("Util.Table")
local Vararg = OC.Include("Util.Vararg")
local ScriptWrapper = OC.Include("Util.ScriptWrapper")
local UIElements = OC.Include("UI.UIElements")
local private = {}
local STRATA_ORDER = {"TOOLTIP", "FULLSCREEN_DIALOG", "FULLSCREEN", "DIALOG", "HIGH", "MEDIUM", "LOW", "BACKGROUND", "WORLD"}
local framesByStrata = {
	WORLD = {},
	BACKGROUND = {},
	LOW = {},
	MEDIUM = {},
	HIGH = {},
	DIALOG = {},
	FULLSCREEN = {},
	FULLSCREEN_DIALOG = {},
	TOOLTIP = {},
}
local ELEMENT_ATTR_KEYS = {
	"_hScrollbar",
	"_vScrollbar",
	"_hScrollFrame",
	"_hContent",
	"_vScrollFrame",
	"_content",
	"_header",
	"_frame",
	"_rows",
}
local COLOR_KEYS = {
	FRAME_BG = true,
	PRIMARY_BG = true,
	PRIMARY_BG_ALT = true,
	ACTIVE_BG = true,
	ACTIVE_BG_ALT = true,
	INDICATOR = true,
	INDICATOR_ALT = true,
	INDICATOR_DISABLED = true,
	TEXT = true,
	TEXT_ALT = true,
	TEXT_DISABLED = true,
	FEEDBACK_RED = true,
	FEEDBACK_YELLOW = true,
	FEEDBACK_GREEN = true,
	FEEDBACK_BLUE = true,
	FEEDBACK_ORANGE = true,
	GROUP_ONE = true,
	GROUP_TWO = true,
	GROUP_THREE = true,
	GROUP_FOUR = true,
	GROUP_FIVE = true,
	FULL_BLACK = true,
	FULL_WHITE = true,
	BLIZZARD_YELLOW = true,
	BLIZZARD_GM = true,
}
local FONT_KEYS = {
	HEADING_H5 = true,
	BODY_BODY1 = true,
	BODY_BODY1_BOLD = true,
	BODY_BODY2 = true,
	BODY_BODY2_MEDIUM = true,
	BODY_BODY2_BOLD = true,
	BODY_BODY3 = true,
	BODY_BODY3_MEDIUM = true,
	ITEM_BODY1 = true,
	ITEM_BODY2 = true,
	ITEM_BODY3 = true,
	TABLE_TABLE1 = true,
}
local ELEMENT_STYLE_KEYS = {
	"_texture",
	"_backgroundColor",
	"_borderColor",
	"_font",
	"_roundedCorners",
	"_borderSize",
}
local IGNORED_FRAMES = {
	GlobalFXDialogModelScene = true
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function FrameStack.Toggle()
	if not OCFrameStackTooltip then
		CreateFrame("GameTooltip", "OCFrameStackTooltip", UIParent, "GameTooltipTemplate")
		OCFrameStackTooltip.highlightFrame = CreateFrame("Frame", nil, nil, BackdropTemplateMixin and "BackdropTemplate" or nil)
		OCFrameStackTooltip.highlightFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
		OCFrameStackTooltip.highlightFrame:SetBackdropColor(1, 0, 0, 0.3)
		OCFrameStackTooltip:Hide()
		ScriptWrapper.Set(OCFrameStackTooltip, "OnUpdate", private.OnUpdate)
	end
	if OCFrameStackTooltip:IsVisible() then
		OCFrameStackTooltip:Hide()
		OCFrameStackTooltip.highlightFrame:Hide()
	else
		OCFrameStackTooltip.lastUpdate = 0
		OCFrameStackTooltip.altDown = nil
		OCFrameStackTooltip.index = 1
		OCFrameStackTooltip.numFrames = 0
		OCFrameStackTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		OCFrameStackTooltip:SetPoint("TOPLEFT", 0, 0)
		OCFrameStackTooltip:AddLine("Loading...")
		OCFrameStackTooltip:Show()
		OCFrameStackTooltip.highlightFrame:Show()
	end
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.OnUpdate(self)
	if self.lastUpdate + 0.05 >= GetTime() then
		return
	end
	self.lastUpdate = GetTime()

	local numFrames = 0
	for _, strata in ipairs(STRATA_ORDER) do
		for _, strataFrame in ipairs(framesByStrata[strata]) do
			local name = private.GetFrameName(strataFrame)
			if not strmatch(name, "innerBorderFrame") then
				numFrames = numFrames + 1
			end
		end
	end
	if numFrames ~= OCFrameStackTooltip.numFrames then
		OCFrameStackTooltip.index = 1
		OCFrameStackTooltip.numFrames = numFrames
	end

	local leftAltDown = IsKeyDown("LALT")
	local rightAltDown = IsKeyDown("RALT")
	if not self.altDown and leftAltDown and not rightAltDown then
		self.altDown = "LEFT"
		if OCFrameStackTooltip.index == OCFrameStackTooltip.numFrames then
			OCFrameStackTooltip.index = 1
		else
			OCFrameStackTooltip.index = OCFrameStackTooltip.index + 1
		end
	elseif not self.altDown and not leftAltDown and rightAltDown then
		self.altDown = "RIGHT"
		if OCFrameStackTooltip.index == 1 then
			OCFrameStackTooltip.index = OCFrameStackTooltip.numFrames
		else
			OCFrameStackTooltip.index = OCFrameStackTooltip.index - 1
		end
	elseif self.altDown == "LEFT" and not leftAltDown then
		self.altDown = nil
	elseif self.altDown == "RIGHT" and not rightAltDown then
		self.altDown = nil
	end

	for _, strata in ipairs(STRATA_ORDER) do
		wipe(framesByStrata[strata])
	end

	local frame = EnumerateFrames()
	while frame do
		if frame ~= self.highlightFrame and not frame:IsForbidden() and frame:IsVisible() and MouseIsOver(frame) and not IGNORED_FRAMES[frame:GetName() or ""] then
			tinsert(framesByStrata[frame:GetFrameStrata()], frame)
			for _, region in Vararg.Iterator(frame:GetRegions()) do
				if region:IsObjectType("Texture") and not region:IsForbidden() and region:IsVisible() and MouseIsOver(region) and UIElements.GetByFrame(region) then
					tinsert(framesByStrata[frame:GetFrameStrata()], region)
				end
			end
		end
		frame = EnumerateFrames(frame)
	end

	self:ClearLines()
	self:AddDoubleLine("OC Frame Stack", format("%0.2f, %0.2f", GetCursorPosition()))
	local currentIndex = 1
	local topFrame = nil
	for _, strata in ipairs(STRATA_ORDER) do
		if #framesByStrata[strata] > 0 then
			sort(framesByStrata[strata], private.FrameLevelSortFunction)
			self:AddLine(strata, 0.6, 0.6, 1)
			for _, strataFrame in ipairs(framesByStrata[strata]) do
				local isTexture = strataFrame:IsObjectType("Texture")
				local level = (isTexture and strataFrame:GetParent() or strataFrame):GetFrameLevel()
				local width = strataFrame:GetWidth()
				local height = strataFrame:GetHeight()
				local mouseEnabled = not isTexture and strataFrame:IsMouseEnabled()
				local name = private.GetFrameName(strataFrame)
				local isIndexedFrame = false
				if not strmatch(name, "innerBorderFrame") then
					if not topFrame and currentIndex == self.index then
						topFrame = strataFrame
						isIndexedFrame = true
					end
					currentIndex = currentIndex + 1
				end
				local text = format("  <%d%s> %s (%d, %d)", level, isTexture and "+" or "", name, Math.Round(width), Math.Round(height))
				if isIndexedFrame then
					self:AddLine(text, 0.9, 0.9, 0.5)
					local element = UIElements.GetByFrame(strataFrame)
					if element then
						for _, k in ipairs(ELEMENT_STYLE_KEYS) do
							local v = element[k]
							if v ~= nil then
								local vStr = private.GetStyleValueStr(v)
								if vStr then
									self:AddLine(format("    %s = %s", tostring(k), vStr), 0.7, 0.7, 0.7)
								end
							end
						end
						local state = element._state:_GetData()
						if next(state) then
							self:AddLine("    _state = {", 0.7, 0.7, 0.7)
							for k, v in pairs(state) do
								local vStr = private.GetStyleValueStr(v)
								if vStr then
									self:AddLine(format("        %s = %s", tostring(k), vStr), 0.7, 0.7, 0.7)
								end
							end
							self:AddLine("    }", 0.7, 0.7, 0.7)
						end
					end
				elseif mouseEnabled then
					self:AddLine(text, 0.6, 1, 1)
				else
					self:AddLine(text, 0.9, 0.9, 0.9)
				end
			end
		end
	end
	self.highlightFrame:ClearAllPoints()
	self.highlightFrame:SetAllPoints(topFrame)
	self.highlightFrame:SetFrameStrata("TOOLTIP")
	self:Show()
end

function private.FrameLevelSortFunction(a, b)
	local aLevel = a:IsObjectType("Texture") and (a:GetParent():GetFrameLevel() + 0.1) or a:GetFrameLevel()
	local bLevel = b:IsObjectType("Texture") and (b:GetParent():GetFrameLevel() + 0.1) or b:GetFrameLevel()
	return aLevel > bLevel
end

function private.TableValueSearch(tbl, searchValue, currentKey, visited)
	visited = visited or {}
	for key, value in pairs(tbl) do
		if value == searchValue then
			return (currentKey and (currentKey..".") or "")..key
		elseif type(value) == "table" and (not value.__isa or value:__isa(OC.UI.Element)) and not visited[value] then
			visited[value] = true
			local result = private.TableValueSearch(value, searchValue, (currentKey and (currentKey..".") or "")..key, visited)
			if result then
				return result
			end
		end
	end
	for _, key in ipairs(ELEMENT_ATTR_KEYS) do
		local value = tbl[key]
		if value == searchValue then
			return (currentKey and (currentKey..".") or "")..key
		elseif type(value) == "table" and (not value.__isa or value:__isa(OC.UI.Element)) and not visited[value] then
			visited[value] = true
			local result = private.TableValueSearch(value, searchValue, (currentKey and (currentKey..".") or "")..key, visited)
			if result then
				return result
			end
		end
	end
end

function private.GetFrameNodeInfo(frame)
	local globalName = not frame:IsObjectType("Texture") and frame:GetName()
	if globalName and not strmatch(globalName, "^OC_UI_ELEMENT:") and not strmatch(globalName, "^OC_FONT_STRING:") then
		return globalName, frame:GetParent()
	end

	local parent = frame:GetParent()
	local element = UIElements.GetByFrame(frame)
	if element then
		return element._id, parent
	end

	if parent then
		-- check if this exists as an attribute of the parent table
		local parentKey = Table.KeyByValue(parent, frame)
		if parentKey then
			return tostring(parentKey), parent
		end

		-- find the nearest element to which this frame belongs
		local parentElement = nil
		local testFrame = parent
		while testFrame and not parentElement do
			parentElement = UIElements.GetByFrame(testFrame)
			testFrame = testFrame:GetParent()
		end
		if parentElement then
			-- check if this exists as an attribute of this element
			local tableKey = private.TableValueSearch(parentElement, frame)
			if tableKey then
				return tableKey, parentElement._frame
			end
		end
	end

	return nil, parent
end

function private.GetFrameName(frame)
	local name, parent = private.GetFrameNodeInfo(frame)
	local parentName = parent and (private.GetFrameName(parent)..".") or ""
	name = name or gsub(tostring(frame), ": ?0*", ":")
	return parentName..name
end

function private.GetStyleValueStr(value)
	for key in pairs(COLOR_KEYS) do
		if value == Theme.GetColor(key) then
			return "ThemeColor<"..key..">"
		end
	end
	for key in pairs(FONT_KEYS) do
		if value == Theme.GetFont(key) then
			return "ThemeFont<"..key..">"
		end
	end
	if type(value) == "string" then
		return "\""..value.."\""
	elseif value ~= false then
		return tostring(value)
	end
	return nil
end
