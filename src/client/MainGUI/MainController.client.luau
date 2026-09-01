local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Text = require(ReplicatedStorage.Text)

local GAIN_PULSE_SCALE = 1.08
local GAIN_PULSE_UP_TIME = 0.10
local GAIN_PULSE_DOWN_TIME = 0.18


-- ========================================
-- PLAYER DATA
-- ========================================

local leaderstats = player:WaitForChild("leaderstats")
local playerData = player:WaitForChild("PlayerData")

local moneyValue = leaderstats:WaitForChild("Money")
local diamondsValue = playerData:WaitForChild("Diamonds")


-- ========================================
-- GUI REFERENZEN
-- ========================================

local hud = script.Parent:WaitForChild("HUD")
local leftHUD = hud:WaitForChild("LeftHUD")

local uiScale = leftHUD:WaitForChild("UIScale")

local currencies = leftHUD:WaitForChild("Currencies")
local buttonsFrame = leftHUD:WaitForChild("Buttons")
local buttonsGrid = buttonsFrame:WaitForChild("UIGridLayout")


-- ========================================
-- CURRENCY SCALE
-- ========================================

local currencyScale = currencies:FindFirstChild("CurrencyScale")

if not currencyScale then
	currencyScale = Instance.new("UIScale")
	currencyScale.Name = "CurrencyScale"
	currencyScale.Scale = 1
	currencyScale.Parent = currencies
end


-- Verhindert Abschneiden
leftHUD.ClipsDescendants = false
buttonsFrame.ClipsDescendants = false


-- ========================================
-- MONEY
-- ========================================

local moneyFrame = currencies:WaitForChild("Money")
local moneyAmountFrame = moneyFrame:WaitForChild("Amount")
local moneyPlusButton = moneyFrame:WaitForChild("PlusButton")
local moneyGainScale = moneyFrame:FindFirstChild("GainPulseScale")

if not moneyGainScale then
	moneyGainScale = Instance.new("UIScale")
	moneyGainScale.Name = "GainPulseScale"
	moneyGainScale.Scale = 1
	moneyGainScale.Parent = moneyFrame
end


-- ========================================
-- DIAMONDS
-- ========================================

local diamondsFrame = currencies:WaitForChild("Diamonds")
local diamondsAmountFrame = diamondsFrame:WaitForChild("Amount")
local diamondsPlusButton = diamondsFrame:WaitForChild("PlusButton")
local diamondsGainScale = diamondsFrame:FindFirstChild("GainPulseScale")

if not diamondsGainScale then
	diamondsGainScale = Instance.new("UIScale")
	diamondsGainScale.Name = "GainPulseScale"
	diamondsGainScale.Scale = 1
	diamondsGainScale.Parent = diamondsFrame
end


-- ========================================
-- CFM GUI
-- ========================================

local TextGUI = Text.GetTextGUI(1)
TextGUI.Parent = player.PlayerGui


-- ========================================
-- MONEY TEXT
-- ========================================

local moneyText = Text.new("SuperBouncer", true)

moneyText.Parent = TextGUI.TextParent
moneyText.TextCentered = true


-- ========================================
-- DIAMONDS TEXT
-- ========================================

local diamondsText = Text.new("SuperBouncer", true)

diamondsText.Parent = TextGUI.TextParent
diamondsText.TextCentered = true


-- ========================================
-- ZAHLEN FORMATIEREN
-- ========================================

local function formatNumber(number)

	if number >= 1_000_000_000_000 then
		return string.format("%.1f T", number / 1_000_000_000_000)

	elseif number >= 1_000_000_000 then
		return string.format("%.1f B", number / 1_000_000_000)

	elseif number >= 1_000_000 then
		return string.format("%.1f M", number / 1_000_000)

	elseif number >= 1_000 then
		return string.format("%.1f K", number / 1_000)

	end

	return tostring(number)
end


-- ========================================
-- TEXTE AKTUALISIEREN
-- ========================================

local function updateMoneyText()
	moneyText.Text = formatNumber(moneyValue.Value)
end


local function updateDiamondsText()
	diamondsText.Text = formatNumber(diamondsValue.Value)
end


-- ========================================
-- CURRENCY GAIN ANIMATION
-- ========================================

local activePulseTweens = {}

local function playGainPulse(scaleObject)
	local currentTween = activePulseTweens[scaleObject]

	if currentTween then
		currentTween:Cancel()
	end

	scaleObject.Scale = 1

	local growTween = TweenService:Create(
		scaleObject,
		TweenInfo.new(
			GAIN_PULSE_UP_TIME,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Scale = GAIN_PULSE_SCALE
		}
	)

	activePulseTweens[scaleObject] = growTween
	growTween:Play()

	growTween.Completed:Once(function(playbackState)
		if activePulseTweens[scaleObject] ~= growTween then
			return
		end

		if playbackState == Enum.PlaybackState.Cancelled then
			return
		end

		local shrinkTween = TweenService:Create(
			scaleObject,
			TweenInfo.new(
				GAIN_PULSE_DOWN_TIME,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Scale = 1
			}
		)

		activePulseTweens[scaleObject] = shrinkTween
		shrinkTween:Play()

		shrinkTween.Completed:Once(function()
			if activePulseTweens[scaleObject] == shrinkTween then
				activePulseTweens[scaleObject] = nil
			end
		end)
	end)
end


-- ========================================
-- SHOP PAGE OEFFNEN
-- ========================================

local function getOpenPageRequest(shopHolder)
	local openPageRequest = shopHolder:FindFirstChild("OpenPageRequest")

	if openPageRequest then
		if openPageRequest:IsA("BindableEvent") then
			return openPageRequest
		end

		warn("ShopHolder.OpenPageRequest muss ein BindableEvent sein.")
		return nil
	end

	openPageRequest = Instance.new("BindableEvent")
	openPageRequest.Name = "OpenPageRequest"
	openPageRequest.Parent = shopHolder

	return openPageRequest
end

local function openShopPage(pageName)
	local playerGui = player:WaitForChild("PlayerGui")
	local shopGui = playerGui:WaitForChild("ShopGUI", 5)

	if not shopGui then
		warn("ShopGUI wurde im PlayerGui nicht gefunden.")
		return
	end

	local shopLayer = shopGui:WaitForChild("ShopLayer", 5)

	if not shopLayer then
		warn("ShopGUI.ShopLayer wurde nicht gefunden.")
		return
	end

	local shopHolder = shopLayer:WaitForChild("ShopHolder", 5)

	if not shopHolder then
		warn("ShopGUI.ShopLayer.ShopHolder wurde nicht gefunden.")
		return
	end

	local shopScale = shopHolder:FindFirstChild("UIScale")

	if not shopScale then
		shopScale = Instance.new("UIScale")
		shopScale.Name = "UIScale"
		shopScale.Scale = 1
		shopScale.Parent = shopHolder
	end

	local dimButton = shopLayer:FindFirstChild("DimButton")
	local openPageRequest = getOpenPageRequest(shopHolder)

	playerGui:SetAttribute("ShopOpenedByUser", true)
	shopGui.Enabled = true
	shopLayer.Visible = true

	if shopScale then
		shopScale.Scale = 1
	end

	if dimButton and dimButton:IsA("GuiObject") then
		dimButton.BackgroundTransparency = 0.55
	end

	if openPageRequest then
		openPageRequest:Fire(pageName)
	end
end


-- ========================================
-- RESPONSIVE HUD
-- ========================================

local function updateHUD()

	local viewport = camera.ViewportSize

	local shortestSide = math.min(
		viewport.X,
		viewport.Y
	)


	-- Immer maximal 3 Buttons nebeneinander
	buttonsGrid.FillDirection = Enum.FillDirection.Horizontal
	buttonsGrid.FillDirectionMaxCells = 3


	-- ====================================
	-- MOBILE
	-- ====================================

	if UserInputService.TouchEnabled then

		-- ====================================
		-- HANDY
		-- ====================================

		if shortestSide <= 600 then

			uiScale.Scale = 0.72

			-- Currency Counter kleiner
			currencyScale.Scale = 0.80


			leftHUD.Position = UDim2.new(
				0.02,
				0,
				0.16,
				0
			)


			-- Buttons weiter unten
			buttonsFrame.Position = UDim2.fromOffset(
				0,
				175
			)


			-- Platz für 3x2 Grid
			buttonsFrame.Size = UDim2.fromOffset(
				240,
				160
			)


			-- Mobile Buttons
			buttonsGrid.CellSize = UDim2.fromOffset(
				68,
				68
			)


			buttonsGrid.CellPadding = UDim2.fromOffset(
				8,
				8
			)


			-- Schrift
			moneyText.TextSize = 0.74
			diamondsText.TextSize = 0.80


			-- ====================================
			-- TABLET
			-- ====================================

		else

			uiScale.Scale = 0.85

			currencyScale.Scale = 0.90


			leftHUD.Position = UDim2.new(
				0.02,
				0,
				0.24,
				0
			)


			buttonsFrame.Position = UDim2.fromOffset(
				0,
				190
			)


			buttonsFrame.Size = UDim2.fromOffset(
				270,
				180
			)


			buttonsGrid.CellSize = UDim2.fromOffset(
				72,
				72
			)


			buttonsGrid.CellPadding = UDim2.fromOffset(
				10,
				10
			)


			moneyText.TextSize = 0.76
			diamondsText.TextSize = 0.82

		end


		-- ====================================
		-- DESKTOP
		-- ====================================

	else

		uiScale.Scale = 1
		currencyScale.Scale = 1


		leftHUD.Position = UDim2.new(
			0.015,
			0,
			0.34,
			0
		)


		buttonsFrame.Position = UDim2.fromOffset(
			0,
			210
		)


		-- Genug Platz für 3 große Buttons
		buttonsFrame.Size = UDim2.fromOffset(
			410,
			250
		)


		-- ====================================
		-- DESKTOP BUTTON GRÖSSE
		-- ====================================

		buttonsGrid.CellSize = UDim2.fromOffset(
			110,
			110
		)


		buttonsGrid.CellPadding = UDim2.fromOffset(
			12,
			12
		)


		-- Desktop Schrift
		moneyText.TextSize = 0.64
		diamondsText.TextSize = 0.68

	end

end


-- ========================================
-- CFM TEXT POSITIONIERUNG
-- ========================================

local function positionText(textObject, amountFrame)

	local virtualResolution =
		Text.GetVirtualResolution()

	local textParent =
		TextGUI.TextParent


	if textParent.AbsoluteSize.X <= 0
		or textParent.AbsoluteSize.Y <= 0 then

		return
	end


	-- Mitte des Amount Frames
	local amountCenter =
		amountFrame.AbsolutePosition
		+ amountFrame.AbsoluteSize / 2


	-- Optische Korrektur
	amountCenter += Vector2.new(
		amountFrame.AbsoluteSize.X * 0.07,
		-amountFrame.AbsoluteSize.Y * 0.12
	)


	local relativePosition =
		amountCenter
	- textParent.AbsolutePosition


	-- Roblox Pixel -> CFM Position
	textObject.Position = Vector2.new(

		relativePosition.X
			/ textParent.AbsoluteSize.X
			* virtualResolution.X,

		relativePosition.Y
			/ textParent.AbsoluteSize.Y
			* virtualResolution.Y

	)

end


-- ========================================
-- BEIDE TEXTE POSITIONIEREN
-- ========================================

local function updateTextPositions()

	positionText(
		moneyText,
		moneyAmountFrame
	)


	positionText(
		diamondsText,
		diamondsAmountFrame
	)

end


-- ========================================
-- ALLES AKTUALISIEREN
-- ========================================

local function updateEverything()

	updateHUD()

	updateMoneyText()
	updateDiamondsText()


	task.defer(function()

		updateTextPositions()

	end)

end


-- ========================================
-- MONEY ÄNDERT SICH
-- ========================================

local lastMoneyValue = moneyValue.Value

moneyValue
	:GetPropertyChangedSignal("Value")
	:Connect(function()

		local newValue = moneyValue.Value

		updateMoneyText()

		if newValue > lastMoneyValue then
			playGainPulse(moneyGainScale)
		end

		lastMoneyValue = newValue

	end)


-- ========================================
-- DIAMONDS ÄNDERN SICH
-- ========================================

local lastDiamondsValue = diamondsValue.Value

diamondsValue
	:GetPropertyChangedSignal("Value")
	:Connect(function()

		local newValue = diamondsValue.Value

		updateDiamondsText()

		if newValue > lastDiamondsValue then
			playGainPulse(diamondsGainScale)
		end

		lastDiamondsValue = newValue

	end)


-- ========================================
-- CURRENCY PLUS BUTTONS
-- ========================================

if moneyPlusButton:IsA("GuiButton") then
	moneyPlusButton.Activated:Connect(function()
		openShopPage("Cash")
	end)
else
	warn("Money.PlusButton muss ein GuiButton sein.")
end

if diamondsPlusButton:IsA("GuiButton") then
	diamondsPlusButton.Activated:Connect(function()
		openShopPage("Gems")
	end)
else
	warn("Diamonds.PlusButton muss ein GuiButton sein.")
end

-- ========================================
-- AUFLÖSUNG ÄNDERT SICH
-- ========================================

camera
	:GetPropertyChangedSignal("ViewportSize")
	:Connect(function()

		updateEverything()

	end)


-- ========================================
-- START
-- ========================================

updateEverything()


-- ========================================
-- CFM POSITION SYNCHRON HALTEN
-- ========================================

RunService.RenderStepped:Connect(function()

	updateTextPositions()

end)
