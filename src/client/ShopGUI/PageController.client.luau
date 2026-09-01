local TweenService = game:GetService("TweenService")

local shopHolder = script.Parent

local tabs = shopHolder:WaitForChild("Tabs")
local pages = shopHolder:WaitForChild("Pages")

local openPageRequest = shopHolder:FindFirstChild("OpenPageRequest")

if not openPageRequest then
	openPageRequest = Instance.new("BindableEvent")
	openPageRequest.Name = "OpenPageRequest"
	openPageRequest.Parent = shopHolder
end

--------------------------------------------------
-- BUTTONS
--------------------------------------------------

local passesButton = tabs:WaitForChild("PassesButton")
local cashButton = tabs:WaitForChild("CashButton")
local gemsButton = tabs:WaitForChild("GemsButton")
local boostsButton = tabs:WaitForChild("BoostsButton")

--------------------------------------------------
-- PAGES
--------------------------------------------------

local function findPage(...)
	local pageNames = { ... }

	for _, pageName in ipairs(pageNames) do
		local page = pages:FindFirstChild(pageName)

		if page then
			return page
		end
	end

	return nil
end

local passesPage = pages:WaitForChild("PassesPage")
local cashPage = pages:WaitForChild("CashPage")

local gemsPage = findPage("GemPage", "GemsPage")
local boostsPage = findPage("BoostsPage", "BoostPage")

local pageList = {
	Passes = passesPage,
	Cash = cashPage,
	Gems = gemsPage,
	Boosts = boostsPage,
}

--------------------------------------------------
-- ANIMATION
--------------------------------------------------

local START_SCALE = 0.88
local END_SCALE = 1

local ITEM_TIME = 0.20
local ITEM_DELAY = 0.045

--------------------------------------------------
-- AKTUELLE ANIMATION VERSION
--------------------------------------------------

local animationVersion = 0

--------------------------------------------------
-- ITEMS FINDEN
--------------------------------------------------

local function getItems(page)

	local items = {}

	for _, child in ipairs(page:GetChildren()) do

		-- Deine Angebotskarten sind Frames
		if child:IsA("Frame") then
			table.insert(items, child)
		end

	end

	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	return items
end

--------------------------------------------------
-- UISCALE ERSTELLEN / FINDEN
--------------------------------------------------

local function getScale(item)

	local scale = item:FindFirstChild("PageAnimScale")

	if not scale then

		scale = Instance.new("UIScale")

		scale.Name = "PageAnimScale"
		scale.Scale = 1
		scale.Parent = item

	end

	return scale
end

--------------------------------------------------
-- PAGE VORBEREITEN
--------------------------------------------------

local function preparePage(page)

	local items = getItems(page)

	for _, item in ipairs(items) do

		-- GANZ WICHTIG:
		-- Visible bleibt TRUE!
		item.Visible = true

		local scale = getScale(item)

		scale.Scale = START_SCALE

	end

	return items
end

--------------------------------------------------
-- PAGE ANIMIEREN
--------------------------------------------------

local function animatePage(page, version)

	local items = getItems(page)

	for index, item in ipairs(items) do

		local scale = getScale(item)

		task.delay((index - 1) * ITEM_DELAY, function()

			-- Wurde inzwischen eine andere Seite geöffnet?
			if version ~= animationVersion then
				return
			end

			-- Seite wurde inzwischen geschlossen?
			if not page.Visible then
				return
			end

			local tween = TweenService:Create(
				scale,

				TweenInfo.new(
					ITEM_TIME,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),

				{
					Scale = END_SCALE
				}
			)

			tween:Play()

		end)

	end
end

--------------------------------------------------
-- SEITE ÖFFNEN
--------------------------------------------------

local function openPage(pageName)

	animationVersion += 1

	local thisVersion = animationVersion

	local selectedPage = pageList[pageName]

	if not selectedPage then
		warn("[SHOP PAGE] Seite fehlt:", pageName)
		return
	end

	--------------------------------------------------
	-- ERST VORBEREITEN
	--------------------------------------------------

	-- Das passiert während die Page noch versteckt ist,
	-- damit man keinen Frame bei Scale 1 aufblitzen sieht.
	preparePage(selectedPage)

	--------------------------------------------------
	-- ANDERE PAGES AUS
	--------------------------------------------------

	for _, page in pairs(pageList) do

		if page then
			page.Visible = false
		end

	end

	--------------------------------------------------
	-- GEWÄHLTE PAGE AN
	--------------------------------------------------

	selectedPage.Visible = true

	--------------------------------------------------
	-- ANGEBOTE ANIMIEREN
	--------------------------------------------------

	animatePage(
		selectedPage,
		thisVersion
	)

end

--------------------------------------------------
-- BUTTONS
--------------------------------------------------

passesButton.Activated:Connect(function()
	openPage("Passes")
end)

cashButton.Activated:Connect(function()
	openPage("Cash")
end)

gemsButton.Activated:Connect(function()
	openPage("Gems")
end)

boostsButton.Activated:Connect(function()
	openPage("Boosts")
end)

if openPageRequest:IsA("BindableEvent") then
	openPageRequest.Event:Connect(function(pageName)
		if typeof(pageName) ~= "string" then
			return
		end

		openPage(pageName)
	end)
end

--------------------------------------------------
-- START
--------------------------------------------------

openPage("Passes")
