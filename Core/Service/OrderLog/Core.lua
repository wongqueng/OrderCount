-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local OrderLog = OC:NewPackage("OrderLog")
local Database = OC.Include("Util.Database")
local CSV = OC.Include("Util.CSV")
local String = OC.Include("Util.String")
local Log = OC.Include("Util.Log")
local Wow = OC.Include("Util.Wow")
local Settings = OC.Include("Service.Settings")
local private = {
	settings = nil,
	db = nil,
	numQuery=nil,
	moneyQuery=nil,
	dataChanged = false,
	statsQuery = nil,
	statsTemp = {},
}
local COMBINE_TIME_THRESHOLD = 300 -- group expenses within 5 minutes together
local REMOVE_OLD_THRESHOLD = 180 * 24 * 60 * 60 -- remove records over 6 months old
local SECONDS_PER_DAY = 24 * 60 * 60
local CSV_KEYS = { "item", "orderType", "client", "player","commission","quantity", "time" }



-- ============================================================================
-- Module Functions
-- ============================================================================
function OrderLog.OnInitialize()
	private.settings = Settings.NewView()
		:AddKey("realm", "internalData", "csvOrderLog")
		:AddKey("realm", "internalData", "saveTimeOrderLog")
		:AddKey("global", "coreOptions", "regionWide")
	private.db = Database.NewSchema("ORDER_RECORD")
		:AddStringField("orderType")
		:AddStringField("item")
		:AddStringField("client")
		:AddNumberField("commission")
		:AddNumberField("quantity")
		:AddStringField("player")
		:AddNumberField("time")
		:AddNumberField("saveTime")
		:AddBooleanField("isCurrentRealm")
		:AddIndex("item")
		:AddIndex("time")
		:Commit()
	private.numQuery = private.db:NewQuery()
									 :Select("item")
									 --:GreaterThanOrEqual("time", Database.BoundQueryParam())
	private.moneyQuery = private.db:NewQuery()
								:Select("commission")
								--:GreaterThanOrEqual("time", Database.BoundQueryParam())
	private.db:BulkInsertStart()
	for _, csvOrderLog, realm, isConnected in private.settings:AccessibleValueIterator("csvOrderLog") do
		if isConnected or private.settings.regionWide then
			local saveTimeOrderLog = private.settings:GetForScopeKey("saveTimeOrderLog", realm)
			private.LoadData( csvOrderLog, saveTimeOrderLog, realm == Wow.GetRealmName())
		end
	end
	private.db:BulkInsertEnd()
end

function OrderLog.OnDisable()
	if not private.dataChanged then
		-- nothing changed, so no need to save
		return
	end
	local orderRecordSaveTimes= {}
	local orderRecordEncodeContext = CSV.EncodeStart(CSV_KEYS)
	-- order by time to speed up loading
	local query = private.db:NewQuery()
						 :Select("item", "orderType", "client", "player", "commission", "quantity", "time","saveTime")
						 :OrderBy("time", true)
						 :Equal("isCurrentRealm", true)
	for _, item, orderType, client, player, commission, quantity, time ,saveTime in query:Iterator() do
		-- add the save time
		tinsert(orderRecordSaveTimes, saveTime ~= 0 and saveTime or time())
		-- add to our list of CSV lines
		CSV.EncodeAddRowDataRaw(orderRecordEncodeContext, item, orderType, client, player, commission, quantity, time)
	end
	query:Release()
	private.settings.csvOrderLog = CSV.EncodeEnd(orderRecordEncodeContext)
	private.settings.saveTimeOrderLog = table.concat(orderRecordSaveTimes, ",")
end


function OrderLog.GetMoenySum()
	--private.moneyQuery:BindParams(ItemString.GetBase(itemString), minTime or 0)
	local sum = 0
	for _, commission in private.moneyQuery:Iterator() do
		sum = sum + commission
	end
	return sum
end

function OrderLog.GetNum()
	--private.numQuery:BindParams(ItemString.GetBase(itemString), minTime or 0)
	local num = 0
	for _, item in private.numQuery:Iterator() do
		num = num + 1
	end
	return num
end


function OrderLog.CreateQuery()
	return private.db:NewQuery()
end

function OrderLog.RemoveOldData(days)
	private.dataChanged = true
	private.db:SetQueryUpdatesPaused(true)
	local numRecords = private.db:NewQuery()
		:LessThan("time", time() - days * SECONDS_PER_DAY)
		:Equal("isCurrentRealm", true)
		:DeleteAndRelease()
	private.db:SetQueryUpdatesPaused(false)
	return numRecords
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.LoadData( csvRecords, csvSaveTimes, isCurrentRealm)
	local saveTimes = String.SafeSplit(csvSaveTimes, ",")
	if not saveTimes then
		return
	end

	local decodeContext = CSV.DecodeStart(csvRecords, CSV_KEYS)
	if not decodeContext then
		private.dataChanged = true
		return
	end

	local removeTime = time() - REMOVE_OLD_THRESHOLD
	local index = 1
	local prevTimestamp = 0
	for item, orderType, client, player, commission,quantity,time in CSV.DecodeIterator(decodeContext) do
		local saveTime = tonumber(saveTimes[index])
		commission = tonumber(commission)
		quantity = tonumber(quantity)
		time = tonumber(time)
		if item and orderType and client and player and commission and quantity and time and saveTime and time > removeTime then
			local newTimestamp = floor(time)
			if newTimestamp ~= time then
				-- make sure all timestamps are stored as integers
				private.dataChanged = true
				time = newTimestamp
			end
			if time < prevTimestamp then
				-- not ordered by timestamp
				private.dataChanged = true
			end
			prevTimestamp = time
			private.db:BulkInsertNewRowFast9(item, orderType, client, player, commission, quantity, time,saveTime , isCurrentRealm)
		else
			private.dataChanged = true
		end
		index = index + 1
	end

	if not CSV.DecodeEnd(decodeContext) then
		Log.Err("Failed to decode %s records", recordType)
		private.dataChanged = true
	end
end

function OrderLog.InsertRecord(item, orderType, client, commission, quantity, time)
	private.dataChanged = true
	assert(item and orderType and  client  and commission and quantity > 0 and time)
	time = floor(time)
	local matchingRow = private.db:NewQuery()
		:Equal("item", item)
		:Equal("orderType", orderType)
		:Equal("client", client)
		:Equal("commission", commission)
		:Equal("quantity", quantity)
		:Equal("time", time)
		:Equal("player", UnitName("player"))
		:Equal("saveTime", 0)
		:Equal("isCurrentRealm", true)
		:GetFirstResultAndRelease()
	if matchingRow then

	else
		private.db:NewRow()
			:SetField("item", item)
			:SetField("orderType", orderType)
			:SetField("client", client)
			:SetField("commission", commission)
			:SetField("quantity", quantity)
			:SetField("player", UnitName("player"))
			:SetField("time", time)
			:SetField("saveTime", 0)
			:SetField("isCurrentRealm", true)
			:Create()
		print(OrderLog.GetNum())
	end
end
