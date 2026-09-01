local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local shopHolder = script.Parent
local tabs = shopHolder:WaitForChild("Tabs")
local player = Players.LocalPlayer

local cashProducts = {
	{
		ItemName = "Cash_5000",
		ProductId = 3710684905,
		Reward = 5_000,
	},
	{
		ItemName = "Cash_15000",
		ProductId = 3710684949,
		Reward = 15_000,
	},
	{
		ItemName = "Cash_40000",
		ProductId = 3710684981,
		Reward = 40_000,
	},
	{
		ItemName = "Cash_100000",
		ProductId = 3710685014,
		Reward = 100_000,
	},
	{
		ItemName = "Cash_275000",
		ProductId = 3710685083,
		Reward = 275_000,
	},
	{
		ItemName = "Cash_650000",
		ProductId = 3710685142,
		Reward = 650_000,
	},
}

local gemProducts = {
	{
		ItemName = "Gems_100",
		ProductId = 3710761179,
		Reward = 100,
	},
	{
		ItemName = "Gems_250",
		ProductId = 3710761239,
		Reward = 250,
	},
	{
		ItemName = "Gems_600",
		ProductId = 3710761278,
		Reward = 600,
	},
	{
		ItemName = "Gems_1500",
		ProductId = 3710761312,
		Reward = 1_500,
	},
	{
		ItemName = "Gems_3500",
		ProductId = 3710761340,
		Reward = 3_500,
	},
	{
		ItemName = "Gems_8000",
		ProductId = 3710761364,
		Reward = 8_000,
	},
}

local openPageRequest = shopHolder:FindFirstChild("OpenPageRequest")

if not openPageRequest then
	openPageRequest = Instance.new("BindableEvent")
	openPageRequest.Name = "OpenPageRequest"
	openPageRequest.Parent = shopHolder
end

-- Buttons
local passesButton = tabs:WaitForChild("PassesButton")
local cashButton = tabs:WaitForChild("CashButton")
local gemsButton = tabs:WaitForChild("GemsButton")
local boostsButton = tabs:WaitForChild("BoostsButton")


local buttons = {
	Passes = passesButton,
	Cash = cashButton,
	Gems = gemsButton,
	Boosts = boostsButton,
}


-- Normale Bilder werden automatisch aus Studio übernommen
local normalImages = {
	Passes = passesButton.Image,
	Cash = cashButton.Image,
	Gems = gemsButton.Image,
	Boosts = boostsButton.Image,
}


-- Selected-Bilder
local selectedImages = {
	Passes = "rbxassetid://91205228275908",
	Cash = "rbxassetid://116864106343017",
	Gems = "rbxassetid://137231576083914",
	Boosts = "rbxassetid://100139324895980",
}


-- Roblox Standard-Buttonanimation ausschalten
for _, button in pairs(buttons) do
	button.AutoButtonColor = false
end


-- UIScale automatisch für jeden Button erstellen
local scales = {}

for name, button in pairs(buttons) do
	local scale = button:FindFirstChild("ButtonScale")

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ButtonScale"
		scale.Scale = 1
		scale.Parent = button
	end

	scales[name] = scale
end


local currentTab = nil
local animating = false


local function tween(object, duration, properties, style, direction)
	local tweenInfo = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)

	local animation = TweenService:Create(
		object,
		tweenInfo,
		properties
	)

	animation:Play()

	return animation
end


local promptingProduct = false
local productBuyButtons = {}

local function setProductBuyButtonsActive(active)
	for _, buyButton in ipairs(productBuyButtons) do
		if buyButton:IsDescendantOf(game) then
			buyButton.Active = active
		end
	end
end

local function resetProductPromptState()
	promptingProduct = false
	setProductBuyButtonsActive(true)
end

local function findPage(...)
	local pages = shopHolder:FindFirstChild("Pages")

	if not pages then
		return nil
	end

	local pageNames = { ... }

	for _, pageName in ipairs(pageNames) do
		local page = pages:FindFirstChild(pageName)

		if page then
			return page
		end
	end

	return nil
end

local function setupProductBuyButton(page, product, currencyName)
	local item = page:FindFirstChild(product.ItemName)

	if not item then
		warn("[SHOP] Angebot fehlt:", page.Name, product.ItemName)
		return
	end

	local buyButton = item:FindFirstChild("BuyButton")

	if not buyButton then
		warn("[SHOP] BuyButton fehlt:", item:GetFullName())
		return
	end

	if not buyButton:IsA("GuiButton") then
		warn("[SHOP] BuyButton ist kein GuiButton:", buyButton:GetFullName())
		return
	end

	buyButton:SetAttribute("ProductId", product.ProductId)
	buyButton:SetAttribute("RewardCurrency", currencyName)
	buyButton:SetAttribute("RewardAmount", product.Reward)
	table.insert(productBuyButtons, buyButton)

	buyButton.Activated:Connect(function()
		if promptingProduct then
			return
		end

		promptingProduct = true
		setProductBuyButtonsActive(false)
		MarketplaceService:PromptProductPurchase(player, product.ProductId)

		task.delay(15, function()
			if promptingProduct then
				resetProductPromptState()
			end
		end)
	end)
end


local function setupProducts()
	local cashPage = findPage("CashPage")

	if not cashPage then
		warn("[SHOP] CashPage fehlt, Cash-Angebote werden nicht verbunden.")
	else
		for _, product in ipairs(cashProducts) do
			setupProductBuyButton(cashPage, product, "Money")
		end
	end

	local gemPage = findPage("GemPage", "GemsPage")

	if not gemPage then
		warn("[SHOP] GemPage fehlt, Gems-Angebote werden nicht verbunden.")
		return
	end

	for _, product in ipairs(gemProducts) do
		setupProductBuyButton(gemPage, product, "Diamonds")
	end
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId)
	if userId ~= player.UserId then
		return
	end

	resetProductPromptState()
end)


local function changeImageSmooth(button, scaleObject, newImage, selected)

	-- leicht kleiner + leicht ausblenden
	local shrinkTween = tween(
		scaleObject,
		0.07,
		{Scale = 0.94},
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	tween(
		button,
		0.07,
		{ImageTransparency = 0.22}
	)

	shrinkTween.Completed:Wait()


	-- Bild wechseln
	button.Image = newImage


	-- wieder einblenden
	tween(
		button,
		0.09,
		{ImageTransparency = 0}
	)


	if selected then

		-- kleiner Pop
		local popTween = tween(
			scaleObject,
			0.09,
			{Scale = 1.05},
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)

		popTween.Completed:Wait()


		tween(
			scaleObject,
			0.08,
			{Scale = 1},
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

	else

		-- normal zurück
		tween(
			scaleObject,
			0.09,
			{Scale = 1},
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

	end
end


local function selectTab(tabName)

	if not buttons[tabName] then
		warn("[SHOP] Tab fehlt:", tabName)
		return
	end

	if tabName == currentTab then
		return
	end

	if animating then
		return
	end

	animating = true


	local previousTab = currentTab
	currentTab = tabName


	-- Alten Tab zurücksetzen
	if previousTab then

		task.spawn(function()

			changeImageSmooth(
				buttons[previousTab],
				scales[previousTab],
				normalImages[previousTab],
				false
			)

		end)

	end


	-- Neuen Tab auswählen
	changeImageSmooth(
		buttons[tabName],
		scales[tabName],
		selectedImages[tabName],
		true
	)


	task.wait(0.04)

	animating = false

end


passesButton.Activated:Connect(function()
	selectTab("Passes")
end)

cashButton.Activated:Connect(function()
	selectTab("Cash")
end)

gemsButton.Activated:Connect(function()
	selectTab("Gems")
end)

boostsButton.Activated:Connect(function()
	selectTab("Boosts")
end)

if openPageRequest:IsA("BindableEvent") then
	openPageRequest.Event:Connect(function(pageName)
		if typeof(pageName) ~= "string" then
			return
		end

		selectTab(pageName)
	end)
end


currentTab = "Passes"

passesButton.Image = selectedImages.Passes
cashButton.Image = normalImages.Cash
gemsButton.Image = normalImages.Gems
boostsButton.Image = normalImages.Boosts

task.defer(setupProducts)
