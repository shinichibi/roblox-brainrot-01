-- GameClient.client.luau (client)
-- The whole Brainrot Bay interface, built in code: the stat readouts (cash, income,
-- rebirths), the egg shop panel, the brainrot index, the rebirth panel, and the three
-- message channels the server speaks on (toasts, announcements, the carrying banner).
-- No image assets anywhere: every panel is frames, corners and text.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Money = require(Shared:WaitForChild("Money"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local leaderstats = player:WaitForChild("leaderstats")

local DARK = Color3.fromRGB(28, 30, 44)
local PANEL = Color3.fromRGB(38, 41, 60)
local ACCENT = Color3.fromRGB(255, 190, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = instance
	return corner
end

local function makeLabel(parent, name, size, position, text, textSize, color, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, color, anchor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.AnchorPoint = anchor or Vector2.new(0, 0)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextSize = 20
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.5
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 10)
	return button
end

-- Stats, top-right (clear of Roblox's own top-left menu buttons): cash, income, rebirths.
local statsFrame = Instance.new("Frame")
statsFrame.Name = "Stats"
statsFrame.Size = UDim2.fromOffset(252, 116)
statsFrame.Position = UDim2.new(1, -14, 0, 12)
statsFrame.AnchorPoint = Vector2.new(1, 0)
statsFrame.BackgroundColor3 = DARK
statsFrame.BackgroundTransparency = 0.15
statsFrame.Parent = gui
addCorner(statsFrame, 12)

local cashLabel = makeLabel(statsFrame, "Cash", UDim2.new(1, -16, 0, 34), UDim2.fromOffset(12, 6), "Cash: $0", 26, Color3.fromRGB(140, 255, 150))
local incomeLabel = makeLabel(statsFrame, "Income", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(12, 44), "Income: $0/s", 20, Color3.fromRGB(255, 255, 255))
local rebirthLabel = makeLabel(statsFrame, "Rebirths", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(12, 76), "Rebirths: 0 (x1 income)", 20, Color3.fromRGB(255, 190, 120))

local function refreshStats()
	local cash = leaderstats:FindFirstChild("Cash")
	local income = leaderstats:FindFirstChild("Income")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if cash then
		cashLabel.Text = "Cash: " .. Money.format(cash.Value)
	end
	if income then
		incomeLabel.Text = "Income: " .. Money.format(income.Value) .. "/s"
	end
	if rebirths then
		rebirthLabel.Text = "Rebirths: " .. rebirths.Value .. " (x" .. (2 ^ rebirths.Value) .. " income)"
	end
end
for _, statName in ipairs({ "Cash", "Income", "Rebirths" }) do
	local stat = leaderstats:WaitForChild(statName)
	stat:GetPropertyChangedSignal("Value"):Connect(refreshStats)
end
refreshStats()

-- The announcement banner: big, top-centre, impossible to miss (a tsunami is coming).
local announceLabel = makeLabel(gui, "Announce", UDim2.new(0.9, 0, 0, 60), UDim2.new(0.5, 0, 0, 66), "", 40, Color3.fromRGB(255, 120, 120), Vector2.new(0.5, 0))
announceLabel.TextXAlignment = Enum.TextXAlignment.Center
announceLabel.Visible = false
local announceToken = 0
local function showAnnouncement(text, color)
	announceToken += 1
	local token = announceToken
	announceLabel.Text = text
	announceLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	announceLabel.Visible = true
	task.delay(4.5, function()
		if announceToken == token then
			announceLabel.Visible = false
		end
	end)
end

-- Toasts: one line at the bottom centre for everything the server wants to tell you.
local toastLabel = makeLabel(gui, "Toast", UDim2.new(0.8, 0, 0, 36), UDim2.new(0.5, 0, 1, -118), "", 22, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false
local toastToken = 0
local function showToast(text)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(3.5, function()
		if toastToken == token then
			toastLabel.Visible = false
		end
	end)
end

-- The carrying banner: what is on your head, and where it wants to go.
local carryLabel = makeLabel(gui, "Carrying", UDim2.new(0.8, 0, 0, 38), UDim2.new(0.5, 0, 1, -76), "", 24, Color3.fromRGB(255, 224, 120), Vector2.new(0.5, 0))
carryLabel.TextXAlignment = Enum.TextXAlignment.Center
carryLabel.Visible = false

-- A one-line hint that never goes away, bottom-left.
local hintLabel = makeLabel(gui, "Hint", UDim2.new(0.6, 0, 0, 26), UDim2.new(0, 12, 1, -34), "Grab wild brainrots on the lane - buy eggs at the shop - run HOME when the siren sings!", 15, Color3.fromRGB(230, 235, 255))
hintLabel.TextTransparency = 0.25

-- Panels -----------------------------------------------------------------------------

local panels = {}

local function makePanel(name, size, titleText)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = PANEL
	panel.Visible = false
	panel.Parent = gui
	addCorner(panel, 14)
	local title = makeLabel(panel, "Title", UDim2.new(1, -70, 0, 44), UDim2.fromOffset(18, 8), titleText, 28, ACCENT)
	title.TextStrokeTransparency = 0.6
	local close = makeButton(panel, "Close", UDim2.fromOffset(40, 40), UDim2.new(1, -50, 0, 10), "X", Color3.fromRGB(200, 70, 80))
	close.TextSize = 20
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	panels[name] = panel
	return panel
end

local function togglePanel(name)
	for panelName, panel in pairs(panels) do
		panel.Visible = panelName == name and not panel.Visible
	end
end

-- The egg shop panel: one row per egg, its price, its odds, and a Buy button.
local shopPanel = makePanel("ShopPanel", UDim2.fromOffset(480, 356), "EGG SHOP")
makeLabel(shopPanel, "Blurb", UDim2.new(1, -36, 0, 26), UDim2.fromOffset(18, 52), "Eggs hatch straight onto a free pad in your base.", 16, Color3.fromRGB(210, 215, 235))
for i, egg in ipairs(BrainrotCatalog.Eggs) do
	local rowY = 88 + (i - 1) * 84
	local row = Instance.new("Frame")
	row.Name = "EggRow_" .. egg.id
	row.Size = UDim2.new(1, -36, 0, 76)
	row.Position = UDim2.fromOffset(18, rowY)
	row.BackgroundColor3 = DARK
	row.Parent = shopPanel
	addCorner(row, 10)
	makeLabel(row, "Name", UDim2.new(0.55, 0, 0, 30), UDim2.fromOffset(12, 6), egg.name, 22, Color3.fromRGB(egg.color[1], egg.color[2], egg.color[3]))
	local oddsParts = {}
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		if egg.odds[rarity] then
			table.insert(oddsParts, rarity .. " " .. egg.odds[rarity] .. "%")
		end
	end
	local oddsLabel = makeLabel(row, "Odds", UDim2.new(0.62, 0, 0, 24), UDim2.fromOffset(12, 40), table.concat(oddsParts, "  -  "), 14, Color3.fromRGB(190, 198, 220))
	oddsLabel.TextWrapped = true
	local buy = makeButton(row, "Buy", UDim2.fromOffset(118, 48), UDim2.new(1, -130, 0.5, -24), Money.format(egg.price), Color3.fromRGB(70, 170, 90))
	buy.Activated:Connect(function()
		remotes:WaitForChild("BuyEgg"):FireServer(egg.id)
	end)
end

-- The index panel: every brainrot in the catalogue, and which ones you have owned.
local indexPanel = makePanel("IndexPanel", UDim2.fromOffset(560, 430), "BRAINROT INDEX")
local indexScroll = Instance.new("ScrollingFrame")
indexScroll.Name = "List"
indexScroll.Size = UDim2.new(1, -24, 1, -70)
indexScroll.Position = UDim2.fromOffset(12, 58)
indexScroll.BackgroundTransparency = 1
indexScroll.BorderSizePixel = 0
indexScroll.ScrollBarThickness = 6
indexScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
indexScroll.Parent = indexPanel
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(168, 92)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.Parent = indexScroll

local indexStatusLabels = {}
for _, spec in ipairs(BrainrotCatalog.Characters) do
	local cell = Instance.new("Frame")
	cell.Name = "Cell_" .. spec.id
	cell.BackgroundColor3 = DARK
	cell.Parent = indexScroll
	addCorner(cell, 8)
	makeLabel(cell, "Name", UDim2.new(1, -12, 0, 24), UDim2.fromOffset(8, 4), spec.name, 15, Color3.fromRGB(255, 255, 255))
	makeLabel(cell, "Rarity", UDim2.new(1, -12, 0, 20), UDim2.fromOffset(8, 28), spec.rarity, 13, Money.RarityColors[spec.rarity])
	makeLabel(cell, "Income", UDim2.new(1, -12, 0, 20), UDim2.fromOffset(8, 46), Money.format(spec.income) .. "/s", 13, Color3.fromRGB(140, 255, 150))
	local status = makeLabel(cell, "Status", UDim2.new(1, -12, 0, 20), UDim2.fromOffset(8, 66), "Not caught yet", 13, Color3.fromRGB(150, 155, 175))
	indexStatusLabels[spec.id] = status
end

local function refreshIndex(collection)
	for specId, status in pairs(indexStatusLabels) do
		local count = collection and collection[specId] or 0
		if count > 0 then
			status.Text = "Owned x" .. count
			status.TextColor3 = Color3.fromRGB(140, 255, 150)
		else
			status.Text = "Not caught yet"
			status.TextColor3 = Color3.fromRGB(150, 155, 175)
		end
	end
end

-- The rebirth panel: what it costs, what it pays, and the big button.
local rebirthPanel = makePanel("RebirthPanel", UDim2.fromOffset(440, 300), "REBIRTH")
local rebirthInfo = makeLabel(rebirthPanel, "Info", UDim2.new(1, -36, 0, 110), UDim2.fromOffset(18, 58), "", 19, Color3.fromRGB(235, 238, 255))
rebirthInfo.TextWrapped = true
rebirthInfo.TextYAlignment = Enum.TextYAlignment.Top
local rebirthStatus = makeLabel(rebirthPanel, "Status", UDim2.new(1, -36, 0, 56), UDim2.fromOffset(18, 172), "", 16, Color3.fromRGB(255, 190, 120))
rebirthStatus.TextWrapped = true
rebirthStatus.TextYAlignment = Enum.TextYAlignment.Top
local rebirthButton = makeButton(rebirthPanel, "DoRebirth", UDim2.fromOffset(220, 52), UDim2.new(0.5, -110, 1, -66), "REBIRTH!", Color3.fromRGB(200, 90, 200))

local function refreshRebirthPanel()
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	local count = rebirths and rebirths.Value or 0
	local cost = 25000 * (5 ^ count)
	rebirthInfo.Text = "Rebirthing wipes your cash and your base's brainrots, but doubles ALL income forever.\n\nNow: x" .. (2 ^ count) .. " income   -   Cost: " .. Money.format(cost) .. "   -   After: x" .. (2 ^ (count + 1)) .. " income"
end

rebirthButton.Activated:Connect(function()
	local result = remotes:WaitForChild("RebirthRequest"):InvokeServer()
	if type(result) == "table" then
		rebirthStatus.Text = result.message or ""
		if result.ok then
			refreshRebirthPanel()
		end
	end
end)

-- The three menu buttons down the right edge.
local shopButton = makeButton(gui, "ShopButton", UDim2.fromOffset(178, 46), UDim2.new(1, -192, 0, 140), "EGG SHOP", Color3.fromRGB(70, 150, 200))
shopButton.Activated:Connect(function()
	togglePanel("ShopPanel")
end)
local indexButton = makeButton(gui, "IndexButton", UDim2.fromOffset(178, 46), UDim2.new(1, -192, 0, 194), "INDEX", Color3.fromRGB(120, 100, 200))
indexButton.Activated:Connect(function()
	togglePanel("IndexPanel")
end)
local rebirthMenuButton = makeButton(gui, "RebirthButton", UDim2.fromOffset(178, 46), UDim2.new(1, -192, 0, 248), "REBIRTH", Color3.fromRGB(200, 90, 200))
rebirthMenuButton.Activated:Connect(function()
	refreshRebirthPanel()
	rebirthStatus.Text = ""
	togglePanel("RebirthPanel")
end)

-- The server's voice: toasts, announcements, the carrying banner, the collection.
remotes:WaitForChild("Toast").OnClientEvent:Connect(showToast)
remotes:WaitForChild("Announce").OnClientEvent:Connect(function(text, color)
	showAnnouncement(text, color)
end)
remotes:WaitForChild("CarryUpdate").OnClientEvent:Connect(function(brainrotName)
	if brainrotName and brainrotName ~= "" then
		carryLabel.Text = "Carrying " .. brainrotName .. " - deliver it to YOUR base!"
		carryLabel.Visible = true
	else
		carryLabel.Visible = false
	end
end)
remotes:WaitForChild("CollectionUpdate").OnClientEvent:Connect(refreshIndex)

-- A gentle pulse on the announcement so warnings feel urgent (scale via text size is
-- enough; no tween targets needed on a label we rebuild anyway).
TweenService:Create(announceLabel, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.25 }):Play()
