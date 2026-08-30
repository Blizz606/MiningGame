local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Text = require(ReplicatedStorage.Text)


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


-- ========================================
-- DIAMONDS
-- ========================================

local diamondsFrame = currencies:WaitForChild("Diamonds")
local diamondsAmountFrame = diamondsFrame:WaitForChild("Amount")


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
		return string.format("%.1fT", number / 1_000_000_000_000)

	elseif number >= 1_000_000_000 then
		return string.format("%.1fB", number / 1_000_000_000)

	elseif number >= 1_000_000 then
		return string.format("%.1fM", number / 1_000_000)

	elseif number >= 1_000 then
		return string.format("%.1fK", number / 1_000)

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
			moneyText.TextSize = 0.80
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


			moneyText.TextSize = 0.82
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
		moneyText.TextSize = 0.74
		diamondsText.TextSize = 0.74

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

moneyValue
	:GetPropertyChangedSignal("Value")
	:Connect(function()

		updateMoneyText()

	end)


-- ========================================
-- DIAMONDS ÄNDERN SICH
-- ========================================

diamondsValue
	:GetPropertyChangedSignal("Value")
	:Connect(function()

		updateDiamondsText()

	end)


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