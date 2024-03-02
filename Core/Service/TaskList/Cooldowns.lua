-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Cooldowns = OC.TaskList:NewPackage("Cooldowns")
local L = OC.Include("Locale").GetTable()
local Delay = OC.Include("Util.Delay")
local ObjectPool = OC.Include("Util.ObjectPool")
local Table = OC.Include("Util.Table")
local private = {
	query = nil,
	taskPool = ObjectPool.New("COOLDOWN_TASK", OC.TaskList.CooldownCraftingTask, 0),
	activeTasks = {},
	activeTaskByProfession = {},
	ignoredQuery = nil, -- luacheck: ignore 1004 - just stored for GC reasons
	updateTimer = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Cooldowns.OnEnable()
	OC.TaskList.RegisterTaskPool(private.ActiveTaskIterator)
	private.updateTimer = Delay.CreateTimer("COOLDOWNS_UPDATE", private.PopulateTasks)
	private.query = OC.Crafting.CreateCooldownSpellsQuery()
		:Select("profession", "craftString")
		:ListContains("players", UnitName("player"))
		:SetUpdateCallback(private.PopulateTasks)
	private.ignoredQuery = OC.Crafting.CreateIgnoredCooldownQuery()
		:SetUpdateCallback(private.PopulateTasks)
	private.PopulateTasks()
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.ActiveTaskIterator()
	return ipairs(private.activeTasks)
end

function private.PopulateTasks()
	-- clean DB entries with expired times
	for craftString, expireTime in pairs(OC.db.char.internalData.craftingCooldowns) do
		if expireTime <= time() then
			OC.db.char.internalData.craftingCooldowns[craftString] = nil
		end
	end

	-- clear out the existing tasks
	for _, task in pairs(private.activeTaskByProfession) do
		task:WipeCraftStrings()
	end

	local minPendingCooldown = math.huge
	for _, profession, craftString in private.query:Iterator() do
		if OC.Crafting.IsCooldownIgnored(craftString) then
			-- this is ignored
		elseif OC.db.char.internalData.craftingCooldowns[craftString] then
			-- this is on CD
			minPendingCooldown = min(minPendingCooldown, OC.db.char.internalData.craftingCooldowns[craftString] - time())
		else
			-- this is a new CD task
			local task = private.activeTaskByProfession[profession]
			if not task then
				task = private.taskPool:Get()
				task:Acquire(private.RemoveTask, L["Cooldowns"], profession)
				private.activeTaskByProfession[profession] = task
			end
			if not task:HasCraftString(craftString) then
				task:AddCraftString(craftString, 1)
			end
		end
	end

	-- update our tasks
	wipe(private.activeTasks)
	for profession, task in pairs(private.activeTaskByProfession) do
		if task:HasCraftStrings() then
			tinsert(private.activeTasks, task)
			task:Update()
		else
			private.activeTaskByProfession[profession] = nil
			task:Release()
			private.taskPool:Recycle(task)
		end
	end
	OC.TaskList.OnTaskUpdated()

	if minPendingCooldown ~= math.huge then
		private.updateTimer:RunForTime(minPendingCooldown)
	else
		private.updateTimer:Cancel()
	end
end

function private.RemoveTask(task)
	local profession = task:GetProfession()
	assert(Table.RemoveByValue(private.activeTasks, task) == 1)
	assert(private.activeTaskByProfession[profession] == task)
	private.activeTaskByProfession[profession] = nil
	task:Release()
	private.taskPool:Recycle(task)
	OC.TaskList.OnTaskUpdated()
end
