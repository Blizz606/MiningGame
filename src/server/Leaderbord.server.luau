local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PLAYER_DATA_STORE = "PlayerData_v1"
local DATA_SAVE_ENABLED_ATTRIBUTE = "DataSaveEnabled"
local RECEIPT_WAIT_TIMEOUT = 10
local SAVE_RETRIES = 3
local RETRY_DELAY = 2
local CHANGE_SAVE_DEBOUNCE = 5
local AUTO_SAVE_INTERVAL = 60
local MAX_INT_VALUE = 2_147_483_647

local playerDataStore = DataStoreService:GetDataStore(PLAYER_DATA_STORE)

local defaultData = {
	Money = 0,
	Blocks = 0,
	Rebirths = 0,
	Diamonds = 0,
	ProcessedReceipts = {},
}

local productRewardsByProductId = {
	[3710684905] = {
		Currency = "Money",
		Amount = 5_000,
	},
	[3710684949] = {
		Currency = "Money",
		Amount = 15_000,
	},
	[3710684981] = {
		Currency = "Money",
		Amount = 40_000,
	},
	[3710685014] = {
		Currency = "Money",
		Amount = 100_000,
	},
	[3710685083] = {
		Currency = "Money",
		Amount = 275_000,
	},
	[3710685142] = {
		Currency = "Money",
		Amount = 650_000,
	},
	[3710761179] = {
		Currency = "Diamonds",
		Amount = 100,
	},
	[3710761239] = {
		Currency = "Diamonds",
		Amount = 250,
	},
	[3710761278] = {
		Currency = "Diamonds",
		Amount = 600,
	},
	[3710761312] = {
		Currency = "Diamonds",
		Amount = 1_500,
	},
	[3710761340] = {
		Currency = "Diamonds",
		Amount = 3_500,
	},
	[3710761364] = {
		Currency = "Diamonds",
		Amount = 8_000,
	},
}

local queuedSaves: { [Player]: boolean } = {}
local dataLocks: { [number]: boolean } = {}

local function getDataKey(userId: number): string
	return `Player_{userId}`
end

local function runWithDataLock(userId: number, callback): (boolean, any)
	while dataLocks[userId] do
		task.wait()
	end

	dataLocks[userId] = true

	local success, result = pcall(callback)
	dataLocks[userId] = nil

	if not success then
		warn("[LEADERBORD] Data lock callback failed:", userId, result)
	end

	return success, result
end

local function copyDefaultData()
	return {
		Money = defaultData.Money,
		Blocks = defaultData.Blocks,
		Rebirths = defaultData.Rebirths,
		Diamonds = defaultData.Diamonds,
		ProcessedReceipts = {},
	}
end

local function readNumber(data, name: string): number
	local value = data[name]

	if typeof(value) ~= "number" then
		return defaultData[name]
	end

	return math.clamp(math.floor(value), 0, MAX_INT_VALUE)
end

local function sanitizeData(data): { [string]: any }
	if typeof(data) ~= "table" then
		return copyDefaultData()
	end

	local processedReceipts = data.ProcessedReceipts

	if typeof(processedReceipts) ~= "table" then
		processedReceipts = {}
	end

	return {
		Money = readNumber(data, "Money"),
		Blocks = readNumber(data, "Blocks"),
		Rebirths = readNumber(data, "Rebirths"),
		Diamonds = readNumber(data, "Diamonds"),
		ProcessedReceipts = processedReceipts,
	}
end

local function createIntValue(name: string, value: number, parent: Instance): IntValue
	local intValue = Instance.new("IntValue")
	intValue.Name = name
	intValue.Value = value
	intValue.Parent = parent

	return intValue
end

local function getReceiptKey(receiptInfo): string
	return tostring(receiptInfo.PurchaseId)
end

local function waitForPlayerValues(player: Player): (IntValue?, IntValue?, IntValue?, IntValue?)
	local leaderstats = player:WaitForChild("leaderstats", RECEIPT_WAIT_TIMEOUT)
	local playerData = player:WaitForChild("PlayerData", RECEIPT_WAIT_TIMEOUT)

	if not leaderstats or not playerData then
		return nil, nil, nil, nil
	end

	local money = leaderstats:WaitForChild("Money", RECEIPT_WAIT_TIMEOUT)
	local blocks = leaderstats:WaitForChild("Blocks", RECEIPT_WAIT_TIMEOUT)
	local rebirths = leaderstats:WaitForChild("Rebirths", RECEIPT_WAIT_TIMEOUT)
	local diamonds = playerData:WaitForChild("Diamonds", RECEIPT_WAIT_TIMEOUT)

	if not money or not money:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	if not blocks or not blocks:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	if not rebirths or not rebirths:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	if not diamonds or not diamonds:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	return money, blocks, rebirths, diamonds
end

local function getPlayerValues(player: Player): (IntValue?, IntValue?, IntValue?, IntValue?)
	local leaderstats = player:FindFirstChild("leaderstats")
	local playerData = player:FindFirstChild("PlayerData")

	if not leaderstats or not playerData then
		return nil, nil, nil, nil
	end

	local money = leaderstats:FindFirstChild("Money")
	local blocks = leaderstats:FindFirstChild("Blocks")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	local diamonds = playerData:FindFirstChild("Diamonds")

	if not money or not money:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	if not blocks or not blocks:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	if not rebirths or not rebirths:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	if not diamonds or not diamonds:IsA("IntValue") then
		return nil, nil, nil, nil
	end

	return money, blocks, rebirths, diamonds
end

local function getCurrentPlayerData(player: Player): { [string]: any }?
	local money, blocks, rebirths, diamonds = getPlayerValues(player)

	if not money or not blocks or not rebirths or not diamonds then
		return nil
	end

	return {
		Money = math.clamp(money.Value, 0, MAX_INT_VALUE),
		Blocks = math.clamp(blocks.Value, 0, MAX_INT_VALUE),
		Rebirths = math.clamp(rebirths.Value, 0, MAX_INT_VALUE),
		Diamonds = math.clamp(diamonds.Value, 0, MAX_INT_VALUE),
	}
end

local function applyPlayerDataToValues(player: Player, data: { [string]: any }): boolean
	local money, blocks, rebirths, diamonds = getPlayerValues(player)

	if not money or not blocks or not rebirths or not diamonds then
		return false
	end

	money.Value = data.Money
	blocks.Value = data.Blocks
	rebirths.Value = data.Rebirths
	diamonds.Value = data.Diamonds

	return true
end

local function loadPlayerData(player: Player): ({ [string]: any }, boolean)
	local success, result = pcall(function()
		return playerDataStore:GetAsync(getDataKey(player.UserId))
	end)

	if not success then
		warn("[LEADERBORD] Could not load player data:", player.UserId, result)
		return copyDefaultData(), false
	end

	return sanitizeData(result), true
end

local function savePlayerData(player: Player): boolean
	if player:GetAttribute(DATA_SAVE_ENABLED_ATTRIBUTE) ~= true then
		warn("[LEADERBORD] Save skipped because data was not loaded safely:", player.UserId)
		return false
	end

	local dataKey = getDataKey(player.UserId)

	for attempt = 1, SAVE_RETRIES do
		local success, result = runWithDataLock(player.UserId, function()
			local currentData = getCurrentPlayerData(player)

			if not currentData then
				error("Could not read current player values for save.")
			end

			playerDataStore:UpdateAsync(dataKey, function(oldData)
				local storedData = sanitizeData(oldData)

				storedData.Money = currentData.Money
				storedData.Blocks = currentData.Blocks
				storedData.Rebirths = currentData.Rebirths
				storedData.Diamonds = currentData.Diamonds

				return storedData
			end)
		end)

		if success then
			return true
		end

		warn("[LEADERBORD] Save failed:", player.UserId, "attempt", attempt, result)
		task.wait(RETRY_DELAY)
	end

	return false
end

local function queueSavePlayerData(player: Player)
	if player:GetAttribute(DATA_SAVE_ENABLED_ATTRIBUTE) ~= true then
		return
	end

	if queuedSaves[player] then
		return
	end

	queuedSaves[player] = true

	task.delay(CHANGE_SAVE_DEBOUNCE, function()
		queuedSaves[player] = nil

		if not player:IsDescendantOf(Players) then
			return
		end

		savePlayerData(player)
	end)
end

local function connectAutosave(player: Player, valueObject: IntValue)
	valueObject:GetPropertyChangedSignal("Value"):Connect(function()
		queueSavePlayerData(player)
	end)
end

local function createPlayerValues(player: Player, data: { [string]: any })
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = createIntValue("Money", data.Money, leaderstats)
	local blocks = createIntValue("Blocks", data.Blocks, leaderstats)
	local rebirths = createIntValue("Rebirths", data.Rebirths, leaderstats)

	local playerData = Instance.new("Folder")
	playerData.Name = "PlayerData"
	playerData.Parent = player

	local diamonds = createIntValue("Diamonds", data.Diamonds, playerData)

	connectAutosave(player, money)
	connectAutosave(player, blocks)
	connectAutosave(player, rebirths)
	connectAutosave(player, diamonds)
end

Players.PlayerAdded:Connect(function(player)
	local data, canSave = loadPlayerData(player)
	player:SetAttribute(DATA_SAVE_ENABLED_ATTRIBUTE, canSave)
	createPlayerValues(player, data)
end)

Players.PlayerRemoving:Connect(function(player)
	queuedSaves[player] = nil
	savePlayerData(player)
	dataLocks[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayerData(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)

		for _, player in Players:GetPlayers() do
			savePlayerData(player)
		end
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local productReward = productRewardsByProductId[receiptInfo.ProductId]

	if not productReward then
		warn("[LEADERBORD] Unknown developer product:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local currencyName = productReward.Currency
	local rewardAmount = productReward.Amount

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local money, blocks, rebirths, diamonds = waitForPlayerValues(player)

	if not money or not blocks or not rebirths or not diamonds then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = getReceiptKey(receiptInfo)
	local dataKey = getDataKey(receiptInfo.PlayerId)
	local updatedData = nil
	local granted = false

	local success = false
	local result = nil

	for attempt = 1, SAVE_RETRIES do
		success, result = runWithDataLock(receiptInfo.PlayerId, function()
			updatedData = playerDataStore:UpdateAsync(dataKey, function(oldData)
				local data = sanitizeData(oldData)

				if data.ProcessedReceipts[receiptKey] == true then
					granted = false
					return data
				end

				data[currencyName] = math.clamp(data[currencyName] + rewardAmount, 0, MAX_INT_VALUE)
				data.ProcessedReceipts[receiptKey] = true
				granted = true

				return data
			end)
		end)

		if success then
			break
		end

		warn("[LEADERBORD] Receipt processing failed:", receiptKey, "attempt", attempt, result)
		task.wait(RETRY_DELAY)
	end

	if not success then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	updatedData = sanitizeData(updatedData)

	if not applyPlayerDataToValues(player, updatedData) then
		if currencyName == "Money" then
			money.Value = updatedData.Money
		elseif currencyName == "Diamonds" then
			diamonds.Value = updatedData.Diamonds
		end
	end

	player:SetAttribute(DATA_SAVE_ENABLED_ATTRIBUTE, true)

	if granted then
		print(
			"[LEADERBORD] Granted",
			rewardAmount,
			currencyName,
			"to",
			player.Name,
			"for product",
			receiptInfo.ProductId
		)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
