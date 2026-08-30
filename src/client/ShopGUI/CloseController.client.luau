local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local shopLayer = script.Parent
local shopHolder = shopLayer:WaitForChild("ShopHolder")
local dimButton = shopLayer:WaitForChild("DimButton")
local uiScale = shopHolder:WaitForChild("UIScale")

local PREFIX = "[SHOP CLOSE DEBUG]"

local NORMAL_SCALE = 1
local CLOSED_SCALE = 0.88

local NORMAL_DIM_TRANSPARENCY = 0.55

local isClosing = false


--------------------------------------------------
-- LOG FUNCTION
--------------------------------------------------

local function log(...)
	print(PREFIX, ...)
end


local function logWarn(...)
	warn(PREFIX, ...)
end


--------------------------------------------------
-- START DEBUG
--------------------------------------------------

log("========================================")
log("CloseController gestartet")
log("Script:", script:GetFullName())

log("ShopLayer:", shopLayer:GetFullName())
log("ShopHolder:", shopHolder:GetFullName())
log("DimButton:", dimButton:GetFullName())
log("DimButton Typ:", dimButton.ClassName)
log("UIScale:", uiScale:GetFullName())

log("========================================")


--------------------------------------------------
-- SHOP HITBOX
--------------------------------------------------

local function isInsideShop(x, y)

	local position = shopHolder.AbsolutePosition
	local size = shopHolder.AbsoluteSize

	local left = position.X
	local right = position.X + size.X

	local top = position.Y
	local bottom = position.Y + size.Y


	log("----------------------------------------")
	log("HITBOX TEST")

	log("Klick:")
	log(" X =", x)
	log(" Y =", y)

	log("Shop Grenzen:")
	log(" LEFT   =", left)
	log(" RIGHT  =", right)
	log(" TOP    =", top)
	log(" BOTTOM =", bottom)


	local insideX =
		x >= left and x <= right

	local insideY =
		y >= top and y <= bottom

	local inside =
		insideX and insideY


	log("Inside X:", insideX)
	log("Inside Y:", insideY)
	log("INSIDE SHOP:", inside)

	log("----------------------------------------")


	return inside
end


--------------------------------------------------
-- GUI OBJECT DEBUG
--------------------------------------------------

local function debugGuiObjects(x, y)

	log("GUI Elemente unter Klick:")

	local success, objects = pcall(function()
		return playerGui:GetGuiObjectsAtPosition(x, y)
	end)


	if not success then

		logWarn(
			"Konnte GUI-Objekte nicht auslesen:",
			objects
		)

		return

	end


	log("Anzahl:", #objects)


	for index, object in ipairs(objects) do

		if index > 10 then
			log("Weitere Objekte ausgelassen...")
			break
		end

		log(
			"#" .. index,
			object:GetFullName(),
			"| Typ:",
			object.ClassName,
			"| ZIndex:",
			object.ZIndex
		)

	end
end


--------------------------------------------------
-- CLOSE
--------------------------------------------------

local function closeShop()

	log("========================================")
	log("closeShop() AUFGERUFEN")


	if isClosing then
		logWarn("Abbruch: schließt bereits")
		return
	end


	if not shopLayer.Visible then
		logWarn("Abbruch: Shop bereits unsichtbar")
		return
	end


	isClosing = true

	log("isClosing = true")

	log("ShopLayer.Visible vorher:", shopLayer.Visible)
	log("UIScale vorher:", uiScale.Scale)
	log(
		"Dim Transparency vorher:",
		dimButton.BackgroundTransparency
	)


	--------------------------------------------------
	-- TWEENS
	--------------------------------------------------

	local scaleTween = TweenService:Create(
		uiScale,

		TweenInfo.new(
			0.16,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),

		{
			Scale = CLOSED_SCALE
		}
	)


	local dimTween = TweenService:Create(
		dimButton,

		TweenInfo.new(
			0.16,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			BackgroundTransparency = 1
		}
	)


	log("Starte Tweens...")


	scaleTween:Play()
	dimTween:Play()


	scaleTween.Completed:Wait()


	log("Scale Tween fertig")
	log("UIScale jetzt:", uiScale.Scale)


	--------------------------------------------------
	-- VERSTECKEN
	--------------------------------------------------

	log("Setze ShopLayer.Visible = false")

	shopLayer.Visible = false


	log(
		"ShopLayer.Visible danach:",
		shopLayer.Visible
	)


	--------------------------------------------------
	-- RESET
	--------------------------------------------------

	uiScale.Scale = NORMAL_SCALE

	dimButton.BackgroundTransparency =
		NORMAL_DIM_TRANSPARENCY

	isClosing = false


	log("UIScale zurückgesetzt:", uiScale.Scale)

	log(
		"Dim Transparency zurückgesetzt:",
		dimButton.BackgroundTransparency
	)

	log("isClosing = false")

	log("✅ SHOP GESCHLOSSEN")
	log("========================================")
end


--------------------------------------------------
-- INPUT
--------------------------------------------------

UserInputService.InputBegan:Connect(
	function(input, gameProcessed)

		log("")
		log("########################################")
		log("INPUT")

		log(
			"Input Type:",
			input.UserInputType
		)

		log(
			"gameProcessed:",
			gameProcessed
		)

		log(
			"Position:",
			input.Position
		)

		log(
			"Shop sichtbar:",
			shopLayer.Visible
		)


		if not shopLayer.Visible then
			log("Shop nicht sichtbar -> ignoriert")
			return
		end


		--------------------------------------------------
		-- NUR KLICK / TOUCH
		--------------------------------------------------

		local validInput =
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch


		if not validInput then

			log(
				"Kein MouseButton1/Touch -> ignoriert"
			)

			return
		end


		--------------------------------------------------
		-- POSITION
		--------------------------------------------------

		local x = input.Position.X
		local y = input.Position.Y


		log("Klick erkannt!")
		log("X:", x)
		log("Y:", y)


		--------------------------------------------------
		-- EXTRA DEBUG
		--------------------------------------------------

		debugGuiObjects(x, y)


		--------------------------------------------------
		-- HITBOX
		--------------------------------------------------

		local inside =
			isInsideShop(x, y)


		if inside then

			log("✅ Klick INNERHALB")
			log("Shop bleibt offen")

		else

			log("🚨 Klick AUSSERHALB")
			log("Shop wird geschlossen!")

			closeShop()

		end


		log("########################################")

	end
)