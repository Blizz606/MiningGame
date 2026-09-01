local Systems = script.Parent:WaitForChild("Systems")

local MineGenerator = require(Systems:WaitForChild("MineGenerator"))
local MiningService = require(Systems:WaitForChild("MiningService"))

MineGenerator.Start()
MiningService.Start()
