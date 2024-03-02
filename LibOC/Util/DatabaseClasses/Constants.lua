-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Constants = OC.Init("Util.DatabaseClasses.Constants") ---@class Util.DatabaseClasses.Constants
Constants.DB_INDEX_VALUE_SEP = "\001"
Constants.OTHER_FIELD_QUERY_PARAM = newproxy()
Constants.BOUND_QUERY_PARAM = newproxy()
