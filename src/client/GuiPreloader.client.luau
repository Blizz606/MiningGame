local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PREFIX = "[GUI PRELOAD]"
local GUI_WAIT_TIMEOUT = 10
local BATCH_SIZE = 25
local DYNAMIC_PRELOAD_DELAY = 0.2
local WARM_RENDER_FRAMES = 2

local explicitAssetIds = {
	"rbxassetid://91205228275908",
	"rbxassetid://116864106343017",
	"rbxassetid://137231576083914",
	"rbxassetid://100139324895980",
}

local assetClasses = {
	Animation = true,
	Beam = true,
	Decal = true,
	ImageButton = true,
	ImageLabel = true,
	MeshPart = true,
	Pants = true,
	ParticleEmitter = true,
	Shirt = true,
	ShirtGraphic = true,
	Sound = true,
	SpecialMesh = true,
	SurfaceAppearance = true,
	TextBox = true,
	TextButton = true,
	TextLabel = true,
	Texture = true,
	Trail = true,
	VideoFrame = true,
}

local contentProperties = {
	Animation = { "AnimationId" },
	Beam = { "Texture" },
	Decal = { "Texture" },
	ImageButton = { "Image", "HoverImage", "PressedImage" },
	ImageLabel = { "Image" },
	MeshPart = { "MeshId", "TextureID" },
	Pants = { "PantsTemplate" },
	ParticleEmitter = { "Texture" },
	Shirt = { "ShirtTemplate" },
	ShirtGraphic = { "Graphic" },
	Sound = { "SoundId" },
	SpecialMesh = { "MeshId", "TextureId" },
	SurfaceAppearance = { "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap" },
	Texture = { "Texture" },
	Trail = { "Texture" },
	VideoFrame = { "Video" },
}

local preloadedItems = setmetatable({}, { __mode = "k" })
local preloadedAssetIds = {}
local queuedDynamicRoots = setmetatable({}, { __mode = "k" })
local dynamicPreloadQueued = false

local function addUnique(items, seen, item)
	if item == nil or seen[item] then
		return
	end

	if typeof(item) == "Instance" then
		if preloadedItems[item] then
			return
		end
	elseif typeof(item) == "string" then
		if item == "" or preloadedAssetIds[item] then
			return
		end
	else
		return
	end

	seen[item] = true
	table.insert(items, item)
end

local function normalizeContentId(value)
	if typeof(value) ~= "string" then
		return nil
	end

	if value == "" then
		return nil
	end

	if string.match(value, "^%d+$") then
		return "rbxassetid://" .. value
	end

	return value
end

local function collectAssets(root, includeExplicitIds)
	local items = {}
	local seen = {}

	if includeExplicitIds then
		for _, assetId in ipairs(explicitAssetIds) do
			addUnique(items, seen, assetId)
		end
	end

	local function collect(instance)
		if assetClasses[instance.ClassName] then
			addUnique(items, seen, instance)
		end

		local properties = contentProperties[instance.ClassName]

		if not properties then
			return
		end

		for _, propertyName in ipairs(properties) do
			local success, propertyValue = pcall(function()
				return instance[propertyName]
			end)

			if success then
				addUnique(items, seen, normalizeContentId(propertyValue))
			end
		end
	end

	collect(root)

	for _, descendant in ipairs(root:GetDescendants()) do
		collect(descendant)
	end

	return items
end

local function markBatchPreloaded(batch)
	for _, item in ipairs(batch) do
		if typeof(item) == "Instance" then
			preloadedItems[item] = true
		else
			preloadedAssetIds[item] = true
		end
	end
end

local function preloadItems(items, reason)
	if #items == 0 then
		print(PREFIX, reason .. ": keine neuen Assets")
		return
	end

	print(PREFIX, string.format("%s: 0/%d (0%%)", reason, #items))
	local failedAssetIds = {}

	for firstIndex = 1, #items, BATCH_SIZE do
		local lastIndex = math.min(firstIndex + BATCH_SIZE - 1, #items)
		local batch = table.create(lastIndex - firstIndex + 1)

		for index = firstIndex, lastIndex do
			table.insert(batch, items[index])
		end

		local success, preloadError = pcall(function()
			ContentProvider:PreloadAsync(batch, function(assetId, fetchStatus)
				if fetchStatus == Enum.AssetFetchStatus.Failure then
					failedAssetIds[assetId] = true
				end
			end)
		end)

		if success then
			markBatchPreloaded(batch)
		else
			warn(PREFIX, "Asset-Batch fehlgeschlagen:", preloadError)
		end

		print(
			PREFIX,
			string.format("%s: %d/%d (%.0f%%)", reason, lastIndex, #items, lastIndex / #items * 100)
		)
		task.wait()
	end

	local failedCount = 0

	for assetId in pairs(failedAssetIds) do
		failedCount += 1
		warn(PREFIX, "Roblox konnte Asset nicht laden:", assetId)
	end

	if failedCount > 0 then
		warn(PREFIX, string.format("%s mit %d fehlgeschlagenen Assets beendet.", reason, failedCount))
	end
end

local function waitRenderFrames(frameCount)
	for _ = 1, frameCount do
		RunService.RenderStepped:Wait()
	end
end

local function warmShopPage(page)
	if not page or not page:IsA("GuiObject") then
		return
	end

	local originalVisible = page.Visible
	page.Visible = true

	for _, descendant in ipairs(page:GetDescendants()) do
		if descendant:IsA("ScrollingFrame") then
			descendant.CanvasPosition = Vector2.zero
		elseif descendant:IsA("GuiObject") then
			descendant.Visible = descendant.Visible
		end
	end

	waitRenderFrames(WARM_RENDER_FRAMES)
	page.Visible = originalVisible
end

local function warmShopRender(shopGui)
	local warmupGui = shopGui:Clone()
	warmupGui.Name = "_ShopWarmupGUI"

	for _, descendant in ipairs(warmupGui:GetDescendants()) do
		if descendant:IsA("LocalScript") or descendant:IsA("Script") then
			descendant:Destroy()
		end
	end

	warmupGui.ResetOnSpawn = false
	warmupGui.Enabled = true
	warmupGui.DisplayOrder = -1000
	warmupGui.Parent = playerGui

	local shopLayer = warmupGui:FindFirstChild("ShopLayer")

	if not shopLayer or not shopLayer:IsA("GuiObject") then
		warn(PREFIX, "ShopLayer fehlt; Warm-Render wird uebersprungen.")
		warmupGui:Destroy()
		return
	end

	local shopHolder = shopLayer:FindFirstChild("ShopHolder")

	if not shopHolder or not shopHolder:IsA("GuiObject") then
		warn(PREFIX, "ShopHolder fehlt; Warm-Render wird uebersprungen.")
		warmupGui:Destroy()
		return
	end

	local pages = shopHolder:FindFirstChild("Pages")
	local dimButton = shopLayer:FindFirstChild("DimButton")

	playerGui:SetAttribute("ShopWarmupActive", true)
	shopLayer.Visible = true
	shopLayer.Active = false
	shopHolder.Visible = true
	shopHolder.Position = UDim2.fromScale(-10, -10)

	if dimButton and dimButton:IsA("GuiObject") then
		dimButton.BackgroundTransparency = 1
		dimButton.Active = false
	end

	waitRenderFrames(WARM_RENDER_FRAMES)

	if pages then
		for _, page in ipairs(pages:GetChildren()) do
			warmShopPage(page)
		end
	end

	waitRenderFrames(WARM_RENDER_FRAMES)
	warmupGui:Destroy()
	playerGui:SetAttribute("ShopWarmupActive", false)
	print(PREFIX, "Shop-Rendercache vorbereitet.")
end

local function getOrderedPages(shopGui)
	local shopLayer = shopGui:FindFirstChild("ShopLayer")

	if not shopLayer then
		return {}
	end

	local shopHolder = shopLayer:FindFirstChild("ShopHolder")

	if not shopHolder then
		return {}
	end

	local pages = shopHolder:FindFirstChild("Pages")

	if not pages then
		return {}
	end

	local pageList = {}

	for _, page in ipairs(pages:GetChildren()) do
		if page:IsA("GuiObject") then
			table.insert(pageList, page)
		end
	end

	table.sort(pageList, function(left, right)
		if left.LayoutOrder == right.LayoutOrder then
			return left.Name < right.Name
		end

		return left.LayoutOrder < right.LayoutOrder
	end)

	return pageList
end

local function setPagePreloadedAttribute(pageName)
	local safeName = string.gsub(pageName, "[^%w_]", "_")
	playerGui:SetAttribute("ShopPagePreloaded_" .. safeName, true)
end

local function preloadShop()
	local shopGui = playerGui:FindFirstChild("ShopGUI") or playerGui:WaitForChild("ShopGUI", GUI_WAIT_TIMEOUT)

	if not shopGui then
		warn(PREFIX, "ShopGUI wurde nicht gefunden; der Shop darf trotzdem sofort oeffnen.")
		return
	end

	warmShopRender(shopGui)

	for _, page in ipairs(getOrderedPages(shopGui)) do
		preloadItems(collectAssets(page, false), "ShopPage " .. page.Name)
		setPagePreloadedAttribute(page.Name)
	end

	preloadItems(collectAssets(shopGui, true), "ShopGUI")
	playerGui:SetAttribute("ShopGuiAssetsPreloaded", true)
end

local function preloadRemainingGui()
	local items = {}
	local seen = {}

	for _, gui in ipairs(playerGui:GetChildren()) do
		for _, item in ipairs(collectAssets(gui, false)) do
			addUnique(items, seen, item)
		end
	end

	preloadItems(items, "Restliche GUI")
	playerGui:SetAttribute("GuiAssetsPreloaded", true)
end

local function preloadDynamicRoots()
	dynamicPreloadQueued = false

	local items = {}
	local seen = {}

	for root in pairs(queuedDynamicRoots) do
		queuedDynamicRoots[root] = nil

		if root:IsDescendantOf(playerGui) then
			for _, item in ipairs(collectAssets(root, false)) do
				addUnique(items, seen, item)
			end
		end
	end

	if #items > 0 then
		preloadItems(items, "Dynamische GUI")
	end
end

local function queueDynamicRoot(root)
	queuedDynamicRoots[root] = true

	if dynamicPreloadQueued then
		return
	end

	dynamicPreloadQueued = true
	task.delay(DYNAMIC_PRELOAD_DELAY, preloadDynamicRoots)
end

playerGui:SetAttribute("GuiAssetsPreloaded", false)
playerGui:SetAttribute("ShopGuiAssetsPreloaded", false)
playerGui:SetAttribute("ShopOpenedByUser", false)
playerGui:SetAttribute("ShopWarmupActive", false)
playerGui.DescendantAdded:Connect(queueDynamicRoot)

task.spawn(function()
	print(PREFIX, "Shop-Preload startet sofort; Shop-Oeffnen wird nicht blockiert.")
	preloadShop()
	preloadRemainingGui()
	print(PREFIX, "Initialer GUI-Preload abgeschlossen.")
end)
