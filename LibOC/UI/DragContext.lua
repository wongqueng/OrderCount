-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local DragContext = OC.Init("UI.DragContext") ---@class UI.DragContext
local private = {
	context = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function DragContext.Get()
	return private.context
end

function DragContext.Set(items)
	private.context = items
end

function DragContext.Clear()
	private.context = nil
end
