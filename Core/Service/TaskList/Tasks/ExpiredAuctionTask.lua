-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local ExpiredAuctionTask = OC.Include("LibOCClass").DefineClass("ExpiredAuctionTask", OC.TaskList.Task)
local L = OC.Include("Locale").GetTable()
OC.TaskList.ExpiredAuctionTask = ExpiredAuctionTask
local private = {}



-- ============================================================================
-- Class Meta Methods
-- ============================================================================

function ExpiredAuctionTask.__init(self)
	self.__super:__init()
	self._characters = {}
	self._daysLeft = {}
end

function ExpiredAuctionTask.Acquire(self, doneHandler, category)
	self.__super:Acquire(doneHandler, category, L["Expired Auctions"])
end

function ExpiredAuctionTask.Release(self)
	self.__super:Release()
	wipe(self._characters)
	wipe(self._daysLeft)
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

function ExpiredAuctionTask.IsSecureMacro(self)
	return true
end

function ExpiredAuctionTask.GetSecureMacroText(self)
	return "/logout"
end

function ExpiredAuctionTask.GetDaysLeft(self, character)
	return self._daysLeft[character] or false
end

function ExpiredAuctionTask.WipeCharacters(self)
	wipe(self._characters)
	wipe(self._daysLeft)
end

function ExpiredAuctionTask.HasCharacters(self)
	return #self._characters > 0
end

function ExpiredAuctionTask.HasCharacter(self, character)
	return self._daysLeft[character] and true or false
end

function ExpiredAuctionTask.AddCharacter(self, character, days)
	tinsert(self._characters, character)
	self._daysLeft[character] = days
end

function ExpiredAuctionTask.CanHideSubTasks(self)
	return true
end

function ExpiredAuctionTask.HideSubTask(self, index)
	local character = self._characters[index]
	if not character then
		return
	end
	OC.db.factionrealm.internalData.expiringAuction[character] = nil

	OC.TaskList.Expirations.Update()
end

function ExpiredAuctionTask.HasSubTasks(self)
	assert(self:HasCharacters())
	return true
end

function ExpiredAuctionTask.SubTaskIterator(self)
	assert(self:HasCharacters())
	sort(self._characters)
	return private.SubTaskIterator, self, 0
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function ExpiredAuctionTask._UpdateState(self)
	return self:_SetButtonState(true, strupper(LOGOUT))
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.SubTaskIterator(self, index)
	index = index + 1
	local character = self._characters[index]
	if not character then
		return
	end
	local charColored = character
	local classColor = RAID_CLASS_COLORS[OC.db:Get("sync", OC.db:GetSyncScopeKeyByCharacter(character), "internalData", "classKey")]
	if classColor then
		charColored = "|c"..classColor.colorStr..charColored.."|r"
	end
	return index, charColored
end
