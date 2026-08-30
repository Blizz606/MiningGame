local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local OPEN_TIME = 0.22

local START_SCALE = 0.85
local OPEN_SCALE = 1

local OPEN_DIM_TRANSPARENCY = 0.55
local START_DIM_TRANSPARENCY = 1

--------------------------------------------------
-- LOG
--------------------------------------------------

local function log(...)
	print("[SHOP OPEN]", ...)
end

local function logWarn(...)
	warn("[SHOP OPEN]", ...)
end

--------------------------------------------------
-- START
--------------------------------------------------

log("======================================")
log("Open-Script gestartet")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local button = script.Parent

log("Spieler:", player.Name)
log("Button:", button:GetFullName())
log("Button Typ:", button.ClassName)

--------------------------------------------------
-- SHOP GUI FINDEN
--------------------------------------------------

log("Suche ShopGUI...")

local shopGui = playerGui:WaitForChild("ShopGUI", 10)

if not shopGui then
	logWarn("❌ ShopGUI wurde nicht gefunden!")
	return
end

log("✅ ShopGUI gefunden:", shopGui:GetFullName())

--------------------------------------------------
-- SHOP LAYER FINDEN
--------------------------------------------------

log("Suche ShopLayer...")

local shopLayer = shopGui:WaitForChild("ShopLayer", 10)

if not shopLayer then
	logWarn("❌ ShopLayer wurde nicht gefunden!")
	return
end

log("✅ ShopLayer gefunden:", shopLayer:GetFullName())

--------------------------------------------------
-- SHOP HOLDER FINDEN
--------------------------------------------------

log("Suche ShopHolder...")

local shopHolder = shopLayer:WaitForChild("ShopHolder", 10)

if not shopHolder then
	logWarn("❌ ShopHolder wurde nicht gefunden!")
	return
end

log("✅ ShopHolder gefunden:", shopHolder:GetFullName())

--------------------------------------------------
-- DIM BUTTON FINDEN
--------------------------------------------------

log("Suche DimButton...")

local dimButton = shopLayer:WaitForChild("DimButton", 10)

if not dimButton then
	logWarn("❌ DimButton wurde nicht gefunden!")
	return
end

log("✅ DimButton gefunden:", dimButton:GetFullName())
log("DimButton Typ:", dimButton.ClassName)

--------------------------------------------------
-- UISCALE FINDEN
--------------------------------------------------

log("Suche UIScale...")

local uiScale = shopHolder:FindFirstChild("UIScale")

if not uiScale then
	logWarn("⚠️ UIScale fehlt - wird automatisch erstellt")

	uiScale = Instance.new("UIScale")
	uiScale.Name = "UIScale"
	uiScale.Scale = 1
	uiScale.Parent = shopHolder
end

log("✅ UIScale bereit:", uiScale:GetFullName())

--------------------------------------------------
-- STATE
--------------------------------------------------

local isOpening = false
local scaleTween = nil
local dimTween = nil

--------------------------------------------------
-- SHOP ÖFFNEN
--------------------------------------------------

local function openShop()

	log("")
	log("======================================")
	log("openShop() aufgerufen")

	log("ShopLayer.Visible vorher:", shopLayer.Visible)
	log("ShopGUI.Enabled vorher:", shopGui.Enabled)
	log("isOpening:", isOpening)

	--------------------------------------------------
	-- SCHON OFFEN?
	--------------------------------------------------

	if shopLayer.Visible then
		log("⚠️ Shop ist bereits geöffnet")
		log("→ kein weiterer Open-Tween")
		return
	end

	if isOpening then
		log("⚠️ Öffnungsanimation läuft bereits")
		return
	end

	isOpening = true

	--------------------------------------------------
	-- ALTE TWEENS STOPPEN
	--------------------------------------------------

	if scaleTween then
		log("Stoppe alten ScaleTween")
		scaleTween:Cancel()
	end

	if dimTween then
		log("Stoppe alten DimTween")
		dimTween:Cancel()
	end

	--------------------------------------------------
	-- SCREEN GUI AKTIVIEREN
	--------------------------------------------------

	shopGui.Enabled = true

	log("ShopGUI.Enabled =", shopGui.Enabled)

	--------------------------------------------------
	-- STARTZUSTAND
	--------------------------------------------------

	uiScale.Scale = START_SCALE

	dimButton.BackgroundTransparency =
		START_DIM_TRANSPARENCY

	shopLayer.Visible = true

	log("Startwerte gesetzt")
	log("ShopLayer.Visible =", shopLayer.Visible)
	log("UIScale =", uiScale.Scale)

	log(
		"DimTransparency =",
		dimButton.BackgroundTransparency
	)

	--------------------------------------------------
	-- SCALE TWEEN
	--------------------------------------------------

	scaleTween = TweenService:Create(
		uiScale,

		TweenInfo.new(
			OPEN_TIME,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),

		{
			Scale = OPEN_SCALE
		}
	)

	--------------------------------------------------
	-- DIM TWEEN
	--------------------------------------------------

	dimTween = TweenService:Create(
		dimButton,

		TweenInfo.new(
			0.18,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		{
			BackgroundTransparency =
				OPEN_DIM_TRANSPARENCY
		}
	)

	--------------------------------------------------
	-- START
	--------------------------------------------------

	log("▶️ Starte Öffnungsanimation")

	scaleTween:Play()
	dimTween:Play()

	--------------------------------------------------
	-- FERTIG
	--------------------------------------------------

	scaleTween.Completed:Once(function(state)

		log("ScaleTween beendet:", state)

		-- Nur bei erfolgreichem Tween
		if state == Enum.PlaybackState.Completed then

			uiScale.Scale = OPEN_SCALE

			dimButton.BackgroundTransparency =
				OPEN_DIM_TRANSPARENCY

			log("✅ Shop vollständig geöffnet")

		end

		isOpening = false

		log("isOpening = false")
		log("UIScale:", uiScale.Scale)

		log(
			"DimTransparency:",
			dimButton.BackgroundTransparency
		)

		log("======================================")

	end)
end

--------------------------------------------------
-- BUTTON
--------------------------------------------------

button.Activated:Connect(function()

	log("")
	log("🛒 ShopButton.Activated")

	openShop()

end)

--------------------------------------------------
-- SETUP FERTIG
--------------------------------------------------

log("✅ Setup abgeschlossen")
log("Warte auf ShopButton...")
log("======================================")