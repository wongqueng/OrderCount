-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Revenue = OC.MainUI.Ledger:NewPackage("Revenue")
local L = OC.Include("Locale").GetTable()



-- ============================================================================
-- Module Functions
-- ============================================================================

function Revenue.OnInitialize()
	OC.MainUI.Ledger.RegisterPage(L["Revenue"])
end

function Revenue.RegisterPage(name, callback)
	OC.MainUI.Ledger.RegisterChildPage(L["Revenue"], name, callback)
end
