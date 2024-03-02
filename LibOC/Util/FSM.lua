-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local FSM = OC.Init("Util.FSM") ---@class Util.FSM
local Machine = OC.Include("Util.FSMClasses.Machine")
local State = OC.Include("Util.FSMClasses.State")



-- ============================================================================
-- Module Functions
-- ============================================================================

---Create a new FSM.
---@param name string The name of the FSM (for debugging purposes)
---@return FSMObject @The FSM object
function FSM.New(name)
	return Machine.Create(name)
end

---Create a new FSM state.
---@param state string The name of the state
---@return FSMState @The State object
function FSM.NewState(state)
	return State.Create(state)
end
