-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Environment = OC.Include("Environment")
-- only create the OCDEV table if we're in a dev or test environment
if not Environment.IsDev() and not Environment.IsTest() then
	return
end
OCDEV = {} ---@class OCDEV



-- ============================================================================
-- Global OCDEV Functions
-- ============================================================================

function OCDEV.Dump(value)
	-- TODO: Implement something for test environments
	assert(not Environment.IsTest())
	LoadAddOn("Blizzard_DebugTools")
	DevTools_Dump(value)
end
