-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Expenses = OC.MainUI.Ledger:NewPackage("Expenses")
local L = OC.Include("Locale").GetTable()



-- ============================================================================
-- Module Functions
-- ============================================================================

function Expenses.OnInitialize()
	OC.MainUI.Ledger.RegisterPage(L["Expenses"])
end

function Expenses.RegisterPage(name, callback)
	OC.MainUI.Ledger.RegisterChildPage(L["Expenses"], name, callback)
end
