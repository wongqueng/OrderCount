-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local FailedAuctions = OC.MainUI.Ledger:NewPackage("FailedAuctions")
local L = OC.Include("Locale").GetTable()



-- ============================================================================
-- Module Functions
-- ============================================================================

function FailedAuctions.OnInitialize()
	OC.MainUI.Ledger.RegisterPage(L["Failed Auctions"])
end

function FailedAuctions.RegisterPage(name, callback)
	OC.MainUI.Ledger.RegisterChildPage(L["Failed Auctions"], name, callback)
end
