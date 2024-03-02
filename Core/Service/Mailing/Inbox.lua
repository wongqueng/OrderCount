-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local Inbox = OC.Mailing:NewPackage("Inbox")
local Database = OC.Include("Util.Database")
local TempTable = OC.Include("Util.TempTable")
local MailTracking = OC.Include("Service.MailTracking")
local UIUtils = OC.Include("UI.UIUtils")
local private = {
	itemsQuery = nil,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Inbox.OnInitialize()
	private.itemsQuery = MailTracking.CreateMailItemQuery()
		:Equal("index", Database.BoundQueryParam())
end

function Inbox.CreateQuery()
	return MailTracking.CreateMailInboxQuery()
		:VirtualField("itemList", "string", private.GetItemLinkVirtualField)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.GetItemLinkVirtualField(row)
	private.itemsQuery:BindParams(row:GetField("index"))

	local items = TempTable.Acquire()
	for _, itemsRow in private.itemsQuery:Iterator() do
		local itemLink = itemsRow:GetField("itemLink")
		local itemName = nil
		if tonumber(itemLink) then
			itemName = ""
		else
			itemName = UIUtils.GetDisplayItemName(itemLink) or ""
		end
		local qty = itemsRow:GetField("quantity")

		tinsert(items, qty > 1 and (itemName.." (x"..qty..")") or itemName)
	end

	local result = table.concat(items, ", ")
	TempTable.Release(items)

	return result
end
