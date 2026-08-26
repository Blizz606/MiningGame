local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local killZone = script.Parent

if not killZone:IsA("BasePart") then
	error("KillOnTouch must be parented to a BasePart.")
end

local killedHumanoids: { [Humanoid]: boolean } = {}

local function isPointInsideZone(worldPoint: Vector3): boolean
	local localPoint = killZone.CFrame:PointToObjectSpace(worldPoint)
	local halfSize = killZone.Size * 0.5

	return math.abs(localPoint.X) <= halfSize.X
		and math.abs(localPoint.Y) <= halfSize.Y
		and math.abs(localPoint.Z) <= halfSize.Z
end

local function isBoxFullyInsideZone(boxCFrame: CFrame, boxSize: Vector3): boolean
	local halfSize = boxSize * 0.5

	for _, x in { -halfSize.X, halfSize.X } do
		for _, y in { -halfSize.Y, halfSize.Y } do
			for _, z in { -halfSize.Z, halfSize.Z } do
				local corner = boxCFrame:PointToWorldSpace(Vector3.new(x, y, z))

				if not isPointInsideZone(corner) then
					return false
				end
			end
		end
	end

	return true
end

local function shouldKillCharacter(character: Model): Humanoid?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or killedHumanoids[humanoid] then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil
	end

	local boxCFrame, boxSize = character:GetBoundingBox()
	if not isBoxFullyInsideZone(boxCFrame, boxSize) then
		return nil
	end

	return humanoid
end

RunService.Heartbeat:Connect(function()
	if not killZone:IsDescendantOf(workspace) then
		return
	end

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end

		local humanoid = shouldKillCharacter(character)
		if not humanoid then
			continue
		end

		killedHumanoids[humanoid] = true
		humanoid.Health = 0

		task.delay(1, function()
			killedHumanoids[humanoid] = nil
		end)
	end
end)
