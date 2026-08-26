local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local tool = script.Parent
local mouse: Mouse? = nil

local mineRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MineBlockRequest")

if not tool:IsA("Tool") then
	error("MineClient must be parented to a Tool.")
end

tool.Equipped:Connect(function(equippedMouse)
	mouse = equippedMouse
end)

tool.Unequipped:Connect(function()
	mouse = nil
end)

tool.Activated:Connect(function()
	if not mouse then
		return
	end

	local target = mouse.Target
	if not target or target:GetAttribute("MineBlock") ~= true then
		return
	end

	mineRemote:FireServer(target)
end)
