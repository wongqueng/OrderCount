-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local AltTask = OC.Include("LibOCClass").DefineClass("AltTask", OC.TaskList.Task)
local L = OC.Include("Locale").GetTable()
OC.TaskList.AltTask = AltTask



-- ============================================================================
-- Class Meta Methods
-- ============================================================================

function AltTask.Acquire(self, doneHandler, category, character)
	self.__super:Acquire(doneHandler, category, format(L["Switch to %s"], character))
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

function AltTask.IsSecureMacro(self)
	return true
end

function AltTask.GetSecureMacroText(self)
	return "/logout"
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function AltTask._UpdateState(self)
	return self:_SetButtonState(true, strupper(LOGOUT))
end
