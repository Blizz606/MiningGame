local killZone = script.Parent

if not killZone:IsA("BasePart") then
	error("KillOnTouch must be parented to a BasePart.")
end

local debounceByHumanoid: { [Humanoid]: boolean } = {}

local function getHumanoidFromHit(hit: BasePart): Humanoid?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

killZone.Touched:Connect(function(hit)
	local humanoid = getHumanoidFromHit(hit)
	if not humanoid or humanoid.Health <= 0 or debounceByHumanoid[humanoid] then
		return
	end

	debounceByHumanoid[humanoid] = true
	humanoid.Health = 0

	task.delay(1, function()
		debounceByHumanoid[humanoid] = nil
	end)
end)
