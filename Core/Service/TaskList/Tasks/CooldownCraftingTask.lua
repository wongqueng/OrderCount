-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local CooldownCraftingTask = OC.Include("LibOCClass").DefineClass("CooldownCraftingTask", OC.TaskList.CraftingTask)
local Math = OC.Include("Util.Math")
local Profession = OC.Include("Service.Profession")
OC.TaskList.CooldownCraftingTask = CooldownCraftingTask
local private = {
	registeredCallbacks = false,
	activeTasks = {},
}



-- ============================================================================
-- Class Meta Methods
-- ============================================================================

function CooldownCraftingTask.__init(self)
	self.__super:__init()
	if not private.registeredCallbacks then
		OC.Crafting.CreateIgnoredCooldownQuery()
			:SetUpdateCallback(private.UpdateTasks)
		private.registeredCallbacks = true
	end
end

function CooldownCraftingTask.Acquire(self, ...)
	self.__super:Acquire(...)
	private.activeTasks[self] = true
end

function CooldownCraftingTask.Release(self)
	self.__super:Release()
	private.activeTasks[self] = nil
end

function CooldownCraftingTask.CanHideSubTasks(self)
	return true
end

function CooldownCraftingTask.HideSubTask(self, index)
	OC.Crafting.IgnoreCooldown(self._craftStrings[index])
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function CooldownCraftingTask._UpdateState(self)
	local result = self.__super:_UpdateState()
	if not self:HasCraftStrings() then
		return result
	end
	for i = #self._craftStrings, 1, -1 do
		if self:_IsOnCooldown(self._craftStrings[i]) or OC.Crafting.IsCooldownIgnored(self._craftStrings[i]) then
			self:_RemoveCraftString(self._craftStrings[i])
		end
	end
	if not self:HasCraftStrings() then
		self:_doneHandler()
		return true
	end
	return result
end

function CooldownCraftingTask._IsOnCooldown(self, craftString)
	assert(not OC.db.char.internalData.craftingCooldowns[craftString])
	local remainingCooldown = Profession.GetRemainingCooldown(craftString)
	if remainingCooldown then
		OC.db.char.internalData.craftingCooldowns[craftString] = time() + Math.Round(remainingCooldown)
		return true
	end
	return false
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.UpdateTasks()
	for task in pairs(private.activeTasks) do
		if task:HasCraftStrings() then
			task:Update()
		end
	end
end
