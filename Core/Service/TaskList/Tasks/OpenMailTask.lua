-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local OpenMailTask = OC.Include("LibOCClass").DefineClass("OpenMailTask", OC.TaskList.ItemTask)
local L = OC.Include("Locale").GetTable()
local DefaultUI = OC.Include("Service.DefaultUI")
OC.TaskList.OpenMailTask = OpenMailTask
local private = {
	activeTasks = {},
	registeredCallbacks = false,
}



-- ============================================================================
-- Class Meta Methods
-- ============================================================================

function OpenMailTask.__init(self)
	self.__super:__init()
	if not private.registeredCallbacks then
		DefaultUI.RegisterMailVisibleCallback(private.FrameCallback)
		private.registeredCallbacks = true
	end
end

function OpenMailTask.Acquire(self, doneHandler, category)
	self.__super:Acquire(doneHandler, category, L["Open Mail"])
	private.activeTasks[self] = true
end

function OpenMailTask.Release(self)
	self.__super:Release()
	private.activeTasks[self] = nil
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

function OpenMailTask.OnButtonClick(self)
	-- TODO
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function OpenMailTask._UpdateState(self)
	if not DefaultUI.IsMailVisible() then
		return self:_SetButtonState(false, L["NOT OPEN"])
	else
		return self:_SetButtonState(false, L["OPEN"])
	end
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.FrameCallback()
	for task in pairs(private.activeTasks) do
		task:Update()
	end
end
