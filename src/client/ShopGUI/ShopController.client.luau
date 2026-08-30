local TweenService = game:GetService("TweenService")

local shopHolder = script.Parent
local tabs = shopHolder:WaitForChild("Tabs")

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

	print("[SHOP] Selected tab:", tabName)
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


-- Startzustand OHNE Animation setzen
currentTab = "Passes"

passesButton.Image = selectedImages.Passes
cashButton.Image = normalImages.Cash
gemsButton.Image = normalImages.Gems
boostsButton.Image = normalImages.Boosts