local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MiningService = {}

local REMOTES_FOLDER_NAME = "Remotes"
local MINE_BLOCK_REQUEST_NAME = "MineBlockRequest"
local MAX_MINE_DISTANCE = 24
local MINE_COOLDOWN = 0.15

local started = false
local lastMineByPlayer: { [Player]: number } = {}

local function getMineRemote(): RemoteEvent
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	local mineRemote = remotesFolder:WaitForChild(MINE_BLOCK_REQUEST_NAME)

	if not mineRemote:IsA("RemoteEvent") then
		error(`ReplicatedStorage.{REMOTES_FOLDER_NAME}.{MINE_BLOCK_REQUEST_NAME} must be a RemoteEvent.`)
	end

	return mineRemote
end

local function getCharacterRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil
	end

	return rootPart
end

local function canMineNow(player: Player): boolean
	local now = os.clock()
	local lastMine = lastMineByPlayer[player]

	if lastMine and now - lastMine < MINE_COOLDOWN then
		return false
	end

	lastMineByPlayer[player] = now
	return true
end

local function isMineBlock(instance: Instance?): boolean
	return instance ~= nil
		and instance:IsA("BasePart")
		and instance:GetAttribute("MineBlock") == true
		and instance:IsDescendantOf(workspace)
end

local function isCloseEnough(player: Player, block: BasePart): boolean
	local rootPart = getCharacterRoot(player)
	if not rootPart then
		return false
	end

	return (rootPart.Position - block.Position).Magnitude <= MAX_MINE_DISTANCE
end

local function mineBlock(player: Player, target: Instance?)
	if not canMineNow(player) then
		return
	end

	if not isMineBlock(target) then
		return
	end

	local block = target :: BasePart
	if not isCloseEnough(player, block) then
		return
	end

	block:Destroy()
end

function MiningService.Start()
	if started then
		return
	end

	started = true
	getMineRemote().OnServerEvent:Connect(mineBlock)
end

return MiningService
