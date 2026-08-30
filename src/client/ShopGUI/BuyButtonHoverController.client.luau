local TweenService = game:GetService("TweenService")

local shopHolder = script.Parent

local NORMAL_SCALE = 1
local HOVER_SCALE = 1.05
local PRESSED_SCALE = 0.94

local HOVER_TIME = 0.10
local PRESS_TIME = 0.06
local RELEASE_TIME = 0.08

local function setupBuyButton(button)
	if not button:IsA("ImageButton") then
		return
	end

	if button.Name ~= "BuyButton" then
		return
	end

	print("[BUY EFFECT] Setup:", button:GetFullName())

	button.AutoButtonColor = false

	local uiScale = button:FindFirstChild("HoverScale")

	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "HoverScale"
		uiScale.Scale = NORMAL_SCALE
		uiScale.Parent = button
	end

	local currentTween = nil
	local isHovering = false
	local isPressed = false

	local function tweenTo(scaleValue, duration, easingStyle)
		if currentTween then
			currentTween:Cancel()
		end

		currentTween = TweenService:Create(
			uiScale,
			TweenInfo.new(
				duration,
				easingStyle or Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Scale = scaleValue
			}
		)

		currentTween:Play()
	end


	--------------------------------------------------
	-- HOVER
	--------------------------------------------------

	button.MouseEnter:Connect(function()
		isHovering = true

		if not isPressed then
			tweenTo(
				HOVER_SCALE,
				HOVER_TIME,
				Enum.EasingStyle.Quad
			)
		end
	end)


	button.MouseLeave:Connect(function()
		isHovering = false

		if not isPressed then
			tweenTo(
				NORMAL_SCALE,
				HOVER_TIME,
				Enum.EasingStyle.Quad
			)
		end
	end)


	--------------------------------------------------
	-- DRÜCKEN
	--------------------------------------------------

	button.MouseButton1Down:Connect(function()
		isPressed = true

		tweenTo(
			PRESSED_SCALE,
			PRESS_TIME,
			Enum.EasingStyle.Quad
		)
	end)


	--------------------------------------------------
	-- LOSLASSEN
	--------------------------------------------------

	button.MouseButton1Up:Connect(function()
		isPressed = false

		if isHovering then
			tweenTo(
				HOVER_SCALE,
				RELEASE_TIME,
				Enum.EasingStyle.Back
			)
		else
			tweenTo(
				NORMAL_SCALE,
				RELEASE_TIME,
				Enum.EasingStyle.Back
			)
		end
	end)
end


--------------------------------------------------
-- ALLE BUYBUTTONS FINDEN
--------------------------------------------------

for _, descendant in ipairs(shopHolder:GetDescendants()) do
	setupBuyButton(descendant)
end


--------------------------------------------------
-- NEUE BUTTONS AUTOMATISCH ERKENNEN
--------------------------------------------------

shopHolder.DescendantAdded:Connect(function(descendant)
	setupBuyButton(descendant)
end)