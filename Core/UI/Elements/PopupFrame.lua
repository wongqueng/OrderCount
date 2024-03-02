	-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

--- PopupFrame UI Element Class.
-- A popup frame which shows when clicking on a "more" button.
-- @classmod PopupFrame

local OC = select(2, ...) ---@type OC
local NineSlice = OC.Include("Util.NineSlice")
local Theme = OC.Include("Util.Theme")
local PopupFrame = OC.Include("LibOCClass").DefineClass("PopupFrame", OC.UI.Frame)
local UIElements = OC.Include("UI.UIElements")
UIElements.Register(PopupFrame)
OC.UI.PopupFrame = PopupFrame



-- ============================================================================
-- Public Class Methods
-- ============================================================================

function PopupFrame.__init(self)
	self.__super:__init()
	self._nineSlice = NineSlice.New(self:_GetBaseFrame())
end

function PopupFrame.Draw(self)
	self.__super:Draw()
	self._nineSlice:SetStyle("popup")
	-- TOOD: fix the texture color properly
	self._nineSlice:SetPartVertexColor("center", Theme.GetColor("PRIMARY_BG_ALT:duskwood"):GetFractionalRGBA())
end
