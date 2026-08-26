local Workspace = game:GetService("Workspace")

local MineGenerator = {}

local BLOCK_SIZE = 4
local ACTIVE_DEPTH_PER_COLUMN = 2

local MINE_FOLDER_NAME = "Mine"
local LAYERS_FOLDER_NAME = "Layers"
local BOUNDS_FOLDER_NAME = "MineBounds"
local TOP_CORNER_NAME = "TopCorner"
local BOTTOM_CORNER_NAME = "BottomCorner"

local started = false
local blocksByKey: { [string]: Part } = {}

type MineBounds = {
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number,
	topY: number,
	bottomY: number,
	gridSizeX: number,
	gridSizeZ: number,
	maxDepth: number,
}

local function getBlockKey(gridX: number, gridZ: number, depth: number): string
	return `{gridX}:{gridZ}:{depth}`
end

local function getLayerName(depth: number): string
	return `Depth_{depth}`
end

local function readCornerPart(boundsFolder: Instance, name: string): BasePart
	local corner = boundsFolder:FindFirstChild(name)
	if not corner or not corner:IsA("BasePart") then
		error(`Workspace.{BOUNDS_FOLDER_NAME}.{name} must be a BasePart.`)
	end

	return corner
end

local function readMineBounds(): MineBounds
	local boundsFolder = Workspace:FindFirstChild(BOUNDS_FOLDER_NAME)
	if not boundsFolder then
		error(`Workspace.{BOUNDS_FOLDER_NAME} is missing.`)
	end

	local topCorner = readCornerPart(boundsFolder, TOP_CORNER_NAME)
	local bottomCorner = readCornerPart(boundsFolder, BOTTOM_CORNER_NAME)

	local topPosition = topCorner.Position
	local bottomPosition = bottomCorner.Position
	local minX = math.min(topPosition.X, bottomPosition.X)
	local maxX = math.max(topPosition.X, bottomPosition.X)
	local minZ = math.min(topPosition.Z, bottomPosition.Z)
	local maxZ = math.max(topPosition.Z, bottomPosition.Z)
	local topY = math.max(topPosition.Y, bottomPosition.Y)
	local bottomY = math.min(topPosition.Y, bottomPosition.Y)
	local gridSizeX = math.max(1, math.floor((maxX - minX) / BLOCK_SIZE) + 1)
	local gridSizeZ = math.max(1, math.floor((maxZ - minZ) / BLOCK_SIZE) + 1)
	local maxDepth = math.max(1, math.floor((topY - bottomY) / BLOCK_SIZE) + 1)

	return {
		minX = minX,
		maxX = maxX,
		minZ = minZ,
		maxZ = maxZ,
		topY = topY,
		bottomY = bottomY,
		gridSizeX = gridSizeX,
		gridSizeZ = gridSizeZ,
		maxDepth = maxDepth,
	}
end

local function hideBoundsMarkers()
	local boundsFolder = Workspace:FindFirstChild(BOUNDS_FOLDER_NAME)
	if not boundsFolder then
		return
	end

	for _, descendant in boundsFolder:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		descendant.Transparency = 1
		descendant.CanCollide = false
		descendant.CanTouch = false
		descendant.CanQuery = false
	end
end

local function getBlockPosition(bounds: MineBounds, gridX: number, gridZ: number, depth: number): Vector3
	local x = bounds.minX + (gridX - 1) * BLOCK_SIZE
	local y = bounds.topY - (depth - 1) * BLOCK_SIZE
	local z = bounds.minZ + (gridZ - 1) * BLOCK_SIZE

	return Vector3.new(x, y, z)
end

local function getBlockColor(bounds: MineBounds, depth: number): Color3
	local depthAlpha = math.clamp(depth / bounds.maxDepth, 0, 1)

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

local function createBlock(bounds: MineBounds, layersFolder: Folder, gridX: number, gridZ: number, depth: number)
	if depth > bounds.maxDepth then
		return
	end

	local key = getBlockKey(gridX, gridZ, depth)
	if blocksByKey[key] then
		return
	end

	local block = Instance.new("Part")
	block.Name = `Block_{gridX}_{gridZ}_{depth}`
	block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	block.Position = getBlockPosition(bounds, gridX, gridZ, depth)
	block.Anchored = true
	block.Material = Enum.Material.Slate
	block.Color = getBlockColor(bounds, depth)
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
		createBlock(bounds, layersFolder, gridX, gridZ, depth + ACTIVE_DEPTH_PER_COLUMN)
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
	blocksByKey = {}

	local bounds = readMineBounds()
	hideBoundsMarkers()

	local mineFolder = Instance.new("Folder")
	mineFolder.Name = MINE_FOLDER_NAME
	mineFolder.Parent = Workspace

	local layersFolder = Instance.new("Folder")
	layersFolder.Name = LAYERS_FOLDER_NAME
	layersFolder.Parent = mineFolder

	for gridX = 1, bounds.gridSizeX do
		for gridZ = 1, bounds.gridSizeZ do
			for depth = 1, ACTIVE_DEPTH_PER_COLUMN do
				createBlock(bounds, layersFolder, gridX, gridZ, depth)
			end
		end
	end

	print(
		`Generated mine: {bounds.gridSizeX}x{bounds.gridSizeZ} columns, {bounds.maxDepth} blocks deep, `
			.. `{bounds.gridSizeX * bounds.gridSizeZ * math.min(ACTIVE_DEPTH_PER_COLUMN, bounds.maxDepth)} active blocks.`
	)
end

return MineGenerator
