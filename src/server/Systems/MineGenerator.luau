local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MineGenerator = {}

local BLOCK_SIZE = 4
local INITIAL_VISIBLE_LAYERS = 2
local BLOCKS_PER_BATCH = 250
local MAX_BLOCKS_PER_LAYER = 25_000

local MINE_FOLDER_NAME = "Mine"
local LAYERS_FOLDER_NAME = "Layers"
local BOUNDS_FOLDER_NAME = "MineBounds"
local BOUNDS_SNAPSHOT_NAME = "MineBoundsSnapshot"
local TOP_CORNER_NAME = "TopCorner"
local BOTTOM_CORNER_NAME = "BottomCorner"

local ORE_VARIANTS = {
	{
		name = "Stone",
		weight = 640,
		color = Color3.fromRGB(92, 84, 76),
		material = Enum.Material.Slate,
	},
	{
		name = "Coal",
		weight = 180,
		color = Color3.fromRGB(38, 35, 34),
		material = Enum.Material.Basalt,
	},
	{
		name = "Copper",
		weight = 95,
		color = Color3.fromRGB(184, 102, 54),
		material = Enum.Material.Slate,
	},
	{
		name = "Iron",
		weight = 55,
		color = Color3.fromRGB(170, 166, 156),
		material = Enum.Material.Metal,
	},
	{
		name = "Gold",
		weight = 24,
		color = Color3.fromRGB(255, 202, 58),
		material = Enum.Material.Metal,
	},
	{
		name = "Diamond",
		weight = 6,
		color = Color3.fromRGB(78, 224, 255),
		material = Enum.Material.Glass,
	},
}

local started = false
local blocksByKey: { [string]: Part } = {}
local deepestGeneratedDepth = 0
local generationId = 0
local generatingDepths: { [number]: boolean } = {}

type OreVariant = {
	name: string,
	weight: number,
	color: Color3,
	material: Enum.Material,
	cumulativeWeight: number?,
}

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

local oreTotalWeight = 0

for _, variant in ipairs(ORE_VARIANTS) do
	oreTotalWeight += variant.weight
	variant.cumulativeWeight = oreTotalWeight
end

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
	local blocksPerLayer = gridSizeX * gridSizeZ

	if blocksPerLayer > MAX_BLOCKS_PER_LAYER then
		error(
			`Mine bounds are too large: {blocksPerLayer} blocks per layer. `
				.. `Maximum is {MAX_BLOCKS_PER_LAYER}.`
		)
	end

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

local function stashBoundsMarkers()
	local boundsFolder = Workspace:FindFirstChild(BOUNDS_FOLDER_NAME)
	if not boundsFolder then
		return
	end

	local existingSnapshot = ServerStorage:FindFirstChild(BOUNDS_SNAPSHOT_NAME)
	if existingSnapshot then
		existingSnapshot:Destroy()
	end

	for _, descendant in boundsFolder:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		descendant.Anchored = true
		descendant.Locked = true
		descendant.Transparency = 1
		descendant.CanCollide = false
		descendant.CanTouch = false
		descendant.CanQuery = false
	end

	local snapshot = boundsFolder:Clone()
	snapshot.Name = BOUNDS_SNAPSHOT_NAME
	snapshot.Parent = ServerStorage

	boundsFolder:Destroy()
end

local function getBlockPosition(bounds: MineBounds, gridX: number, gridZ: number, depth: number): Vector3
	local x = bounds.minX + (gridX - 1) * BLOCK_SIZE
	local y = bounds.topY - (depth - 1) * BLOCK_SIZE
	local z = bounds.minZ + (gridZ - 1) * BLOCK_SIZE

	return Vector3.new(x, y, z)
end

local function getOreVariant(): OreVariant
	local roll = math.random() * oreTotalWeight

	for _, variant in ORE_VARIANTS do
		if roll <= (variant.cumulativeWeight or 0) then
			return variant
		end
	end

	return ORE_VARIANTS[1]
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

local function generateLayer(bounds: MineBounds, layersFolder: Folder, depth: number)
	if depth > bounds.maxDepth or depth <= deepestGeneratedDepth or generatingDepths[depth] then
		return
	end

	generatingDepths[depth] = true

	local success, result = pcall(function()
		local layerFolder = getOrCreateLayerFolder(layersFolder, depth)
		local blocksInBatch = 0

		for gridX = 1, bounds.gridSizeX do
			for gridZ = 1, bounds.gridSizeZ do
				MineGenerator.CreateBlock(bounds, layersFolder, layerFolder, gridX, gridZ, depth)

				blocksInBatch += 1

				if blocksInBatch >= BLOCKS_PER_BATCH then
					blocksInBatch = 0
					task.wait()
				end
			end
		end

		deepestGeneratedDepth = depth
	end)

	generatingDepths[depth] = nil

	if not success then
		warn("[MINE GENERATOR] Layer generation failed:", depth, result)
	end
end

function MineGenerator.CreateBlock(
	bounds: MineBounds,
	layersFolder: Folder,
	layerFolder: Folder,
	gridX: number,
	gridZ: number,
	depth: number
)
	if depth > bounds.maxDepth then
		return
	end

	local key = getBlockKey(gridX, gridZ, depth)
	if blocksByKey[key] then
		return
	end

	local blockGenerationId = generationId
	local block = Instance.new("Part")
	block.Name = `Block_{gridX}_{gridZ}_{depth}`
	block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	block.Position = getBlockPosition(bounds, gridX, gridZ, depth)
	block.Anchored = true
	block.CanTouch = false
	block.CastShadow = false

	local oreVariant = getOreVariant()
	block.Material = oreVariant.material
	block.Color = oreVariant.color
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth

	block:SetAttribute("MineBlock", true)
	block:SetAttribute("OreType", oreVariant.name)
	block:SetAttribute("OreWeight", oreVariant.weight)
	block:SetAttribute("GridX", gridX)
	block:SetAttribute("GridZ", gridZ)
	block:SetAttribute("Depth", depth)

	blocksByKey[key] = block
	block.Destroying:Connect(function()
		if blockGenerationId ~= generationId then
			return
		end

		if blocksByKey[key] ~= block then
			return
		end

		blocksByKey[key] = nil

		if depth >= deepestGeneratedDepth - 1 then
			task.spawn(generateLayer, bounds, layersFolder, deepestGeneratedDepth + 1)
		end
	end)

	if blockGenerationId ~= generationId or not layerFolder:IsDescendantOf(Workspace) then
		block:Destroy()
		return
	end

	block.Parent = layerFolder
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
	generationId += 1
	blocksByKey = {}
	deepestGeneratedDepth = 0
	generatingDepths = {}

	local success, result = pcall(function()
		clearExistingMine()

		local bounds = readMineBounds()
		stashBoundsMarkers()

		local mineFolder = Instance.new("Folder")
		mineFolder.Name = MINE_FOLDER_NAME
		mineFolder.Parent = Workspace

		local layersFolder = Instance.new("Folder")
		layersFolder.Name = LAYERS_FOLDER_NAME
		layersFolder.Parent = mineFolder

		for depth = 1, math.min(INITIAL_VISIBLE_LAYERS, bounds.maxDepth) do
			generateLayer(bounds, layersFolder, depth)
		end
	end)

	if not success then
		started = false
		generationId += 1
		blocksByKey = {}
		deepestGeneratedDepth = 0
		generatingDepths = {}

		warn("[MINE GENERATOR] Start failed:", result)
	end

end

return MineGenerator
