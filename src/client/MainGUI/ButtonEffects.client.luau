local TweenService = game:GetService("TweenService")

local mainGUI = script.Parent

local leftHUD = mainGUI.HUD:WaitForChild("LeftHUD")
local buttonsFolder = leftHUD:WaitForChild("Buttons")
local currenciesFolder = leftHUD:WaitForChild("Currencies")


-- ========================================
-- EINSTELLUNGEN
-- ========================================

local HOVER_SCALE = 1.06
local HOVER_ROTATION = 4

local NORMAL_SCALE = 1
local NORMAL_ROTATION = 0

local PRESS_SCALE = 0.93

local HOVER_TIME = 0.15
local PRESS_TIME = 0.08


local hoverTweenInfo = TweenInfo.new(
	HOVER_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local pressTweenInfo = TweenInfo.new(
	PRESS_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)


-- ========================================
-- BUTTON ANIMATION
-- ========================================

local function setupButton(button)

	-- Nur echte Buttons
	if not button:IsA("GuiButton") then
		return
	end

	-- Nicht doppelt verbinden
	if button:GetAttribute("HoverAnimationSetup") then
		return
	end

	button:SetAttribute("HoverAnimationSetup", true)


	-- UIScale erstellen
	local hoverScale = button:FindFirstChild("HoverScale")

	if not hoverScale then
		hoverScale = Instance.new("UIScale")
		hoverScale.Name = "HoverScale"
		hoverScale.Scale = 1
		hoverScale.Parent = button
	end


	local scaleTween
	local rotationTween


	local function animate(scale, rotation, tweenInfo)

		if scaleTween then
			scaleTween:Cancel()
		end

		if rotationTween then
			rotationTween:Cancel()
		end


		scaleTween = TweenService:Create(
			hoverScale,
			tweenInfo,
			{
				Scale = scale
			}
		)


		rotationTween = TweenService:Create(
			button,
			tweenInfo,
			{
				Rotation = rotation
			}
		)


		scaleTween:Play()
		rotationTween:Play()

	end


	-- ====================================
	-- HOVER
	-- ====================================

	button.MouseEnter:Connect(function()

		animate(
			HOVER_SCALE,
			HOVER_ROTATION,
			hoverTweenInfo
		)

	end)


	button.MouseLeave:Connect(function()

		animate(
			NORMAL_SCALE,
			NORMAL_ROTATION,
			hoverTweenInfo
		)

	end)


	-- ====================================
	-- KLICK / TOUCH
	-- ====================================

	button.MouseButton1Down:Connect(function()

		animate(
			PRESS_SCALE,
			0,
			pressTweenInfo
		)

	end)


	button.MouseButton1Up:Connect(function()

		animate(
			HOVER_SCALE,
			HOVER_ROTATION,
			hoverTweenInfo
		)

	end)

end


-- ========================================
-- ALLE BUTTONS FINDEN
-- ========================================

local function setupContainer(container)

	for _, object in ipairs(container:GetDescendants()) do

		if object:IsA("GuiButton") then
			setupButton(object)
		end

	end


	-- Auch später neu hinzugefügte Buttons
	container.DescendantAdded:Connect(function(object)

		if object:IsA("GuiButton") then
			setupButton(object)
		end

	end)

end


-- ========================================
-- START
-- ========================================

setupContainer(buttonsFolder)
setupContainer(currenciesFolder)