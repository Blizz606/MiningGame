local Workspace = game:GetService("Workspace")

local MineGenerator = {}

local GRID_SIZE = 20
local MAX_DEPTH = 100
local BLOCK_SIZE = 4
local ACTIVE_DEPTH_PER_COLUMN = 2

local MINE_FOLDER_NAME = "Mine"
local LAYERS_FOLDER_NAME = "Layers"
local SURFACE_Y = 8
local MINE_CENTER = Vector3.new(80, 0, 0)

local started = false
local blocksByKey: { [string]: Part } = {}

local function getBlockKey(gridX: number, gridZ: number, depth: number): string
	return `{gridX}:{gridZ}:{depth}`
end

local function getLayerName(depth: number): string
	return `Depth_{depth}`
end

local function getBlockPosition(gridX: number, gridZ: number, depth: number): Vector3
	local gridOffset = (GRID_SIZE + 1) * 0.5
	local x = MINE_CENTER.X + (gridX - gridOffset) * BLOCK_SIZE
	local y = SURFACE_Y - (depth - 0.5) * BLOCK_SIZE
	local z = MINE_CENTER.Z + (gridZ - gridOffset) * BLOCK_SIZE

	return Vector3.new(x, y, z)
end

local function getBlockColor(depth: number): Color3
	local depthAlpha = math.clamp(depth / MAX_DEPTH, 0, 1)

	return Color3.fromRGB(
		math.floor(104 - depthAlpha * 44),
		math.floor(94 - depthAlpha * 38),
		math.floor(82 - depthAlpha * 30)
	)
end

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	return folder
end

local function getOrCreateLayerFolder(layersFolder: Folder, depth: number): Folder
	return getOrCreateFolder(layersFolder, getLayerName(depth))
end

local function createBlock(layersFolder: Folder, gridX: number, gridZ: number, depth: number)
	if depth > MAX_DEPTH then
		return
	end

	local key = getBlockKey(gridX, gridZ, depth)
	if blocksByKey[key] then
		return
	end

	local block = Instance.new("Part")
	block.Name = `Block_{gridX}_{gridZ}_{depth}`
	block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	block.Position = getBlockPosition(gridX, gridZ, depth)
	block.Anchored = true
	block.Material = Enum.Material.Slate
	block.Color = getBlockColor(depth)
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth

	block:SetAttribute("MineBlock", true)
	block:SetAttribute("GridX", gridX)
	block:SetAttribute("GridZ", gridZ)
	block:SetAttribute("Depth", depth)

	blocksByKey[key] = block
	block.Destroying:Connect(function()
		if blocksByKey[key] ~= block then
			return
		end

		blocksByKey[key] = nil
		createBlock(layersFolder, gridX, gridZ, depth + ACTIVE_DEPTH_PER_COLUMN)
	end)

	block.Parent = getOrCreateLayerFolder(layersFolder, depth)
end

local function clearExistingMine()
	local existingMine = Workspace:FindFirstChild(MINE_FOLDER_NAME)
	if existingMine then
		existingMine:Destroy()
	end
end

function MineGenerator.Start()
	if started then
		return
	end

	started = true
	clearExistingMine()

	local mineFolder = Instance.new("Folder")
	mineFolder.Name = MINE_FOLDER_NAME
	mineFolder.Parent = Workspace

	local layersFolder = Instance.new("Folder")
	layersFolder.Name = LAYERS_FOLDER_NAME
	layersFolder.Parent = mineFolder

	for gridX = 1, GRID_SIZE do
		for gridZ = 1, GRID_SIZE do
			for depth = 1, ACTIVE_DEPTH_PER_COLUMN do
				createBlock(layersFolder, gridX, gridZ, depth)
			end
		end
	end
end

return MineGenerator
