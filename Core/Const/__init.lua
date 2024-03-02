-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Environment = OC.Include("Environment")
OC.CONST = {}

-- Miscellaneous constants which should never change
OC.CONST.OPERATION_SEP = "\001"
OC.CONST.GROUP_SEP = "`"
OC.CONST.ROOT_GROUP_PATH = ""
OC.CONST.MIN_BONUS_ID_ITEM_LEVEL = 200
OC.CONST.AUCTION_DURATIONS = {
	not Environment.IsVanillaClassic() and AUCTION_DURATION_ONE or gsub(AUCTION_DURATION_ONE, "12", "2"),
	not Environment.IsVanillaClassic() and AUCTION_DURATION_TWO or gsub(AUCTION_DURATION_TWO, "24", "8"),
	not Environment.IsVanillaClassic() and AUCTION_DURATION_THREE or gsub(AUCTION_DURATION_THREE, "48", "24"),
}
