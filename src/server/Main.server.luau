-- Main.server.luau (server)
-- The bootstrap of Brainrot Bay. Builds the world, creates the remotes the client GUI
-- speaks through, keeps every player's state in one table (ctx.states) that all the
-- other server modules share, wires the modules together, and runs the player
-- lifecycle: leaderstats, a plot, a character that spawns at its base, a saved game
-- restored onto the pads, and a save written back when they leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent
local WorldBuilder = require(Server:WaitForChild("WorldBuilder"))
local PlotManager = require(Server:WaitForChild("PlotManager"))
local Economy = require(Server:WaitForChild("Economy"))
local WildManager = require(Server:WaitForChild("WildManager"))
local Threats = require(Server:WaitForChild("Threats"))
local SaveManager = require(Server:WaitForChild("SaveManager"))
local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

-- The world first: plots, shop, lane, sirens.
local world = WorldBuilder.build()
PlotManager.init(world)

-- The remotes, in one folder the client waits for.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BrainrotRemotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemote(className, name)
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local remotes = {
	buyEgg = makeRemote("RemoteEvent", "BuyEgg"),
	rebirthRequest = makeRemote("RemoteFunction", "RebirthRequest"),
	announce = makeRemote("RemoteEvent", "Announce"),
	toast = makeRemote("RemoteEvent", "Toast"),
	carryUpdate = makeRemote("RemoteEvent", "CarryUpdate"),
	collectionUpdate = makeRemote("RemoteEvent", "CollectionUpdate"),
}

-- The shared context every module works through: the state table, plus the few
-- cross-cutting helpers (toasts, announcements, the carry banner, the collection).
local ctx = {
	states = {},
	remotes = remotes,
	world = world,
}

function ctx.toast(player, text)
	remotes.toast:FireClient(player, text)
end

function ctx.announce(text, color)
	remotes.announce:FireAllClients(text, color)
end

function ctx.updateCarryUi(player, brainrotName)
	remotes.carryUpdate:FireClient(player, brainrotName or "")
end

function ctx.registerCollection(state, specId)
	state.collection[specId] = (state.collection[specId] or 0) + 1
	remotes.collectionUpdate:FireClient(state.player, state.collection)
end

ctx.onSellBrainrot = function(player, entry)
	Economy.sellBrainrot(ctx, player, entry)
end

-- Client requests.
remotes.buyEgg.OnServerEvent:Connect(function(player, eggId)
	if type(eggId) == "string" then
		Economy.buyEgg(ctx, player, eggId)
	end
end)

remotes.rebirthRequest.OnServerInvoke = function(player)
	local ok, message = Economy.requestRebirth(ctx, player)
	return { ok = ok, message = message }
end

-- The shop stand's egg prompts sell the same eggs as the shop panel.
for _, stand in ipairs(world.eggStands) do
	stand.prompt.Triggered:Connect(function(player)
		Economy.buyEgg(ctx, player, stand.eggId)
	end)
end

local function makeLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Economy.STARTING_CASH
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats
	leaderstats.Parent = player
	return leaderstats
end

-- Restore a saved game onto the player's pads (cash, rebirths, brainrots, collection).
local function restoreSavedGame(state, leaderstats)
	local data = SaveManager.loadData(state.player)
	if not data then
		return
	end
	if type(data.cash) == "number" then
		leaderstats.Cash.Value = math.floor(data.cash)
	end
	if type(data.rebirths) == "number" then
		leaderstats.Rebirths.Value = math.floor(data.rebirths)
	end
	if type(data.brainrots) == "table" and state.plot then
		for _, saved in ipairs(data.brainrots) do
			local spec = type(saved) == "table" and BrainrotCatalog.ById[saved.id]
			if spec then
				local entry = PlotManager.placeNewBrainrot(ctx, state, Economy.makeBrainrotData(spec, saved.mutation))
				if entry then
					state.collection[spec.id] = (state.collection[spec.id] or 0) + 1
				end
			end
		end
		remotes.collectionUpdate:FireClient(state.player, state.collection)
	end
end

local function onPlayerAdded(player)
	local state = {
		player = player,
		plot = nil,
		placed = {},
		carrying = nil,
		collection = {},
		saveLoaded = false,
		incomeFraction = 0,
		lastTaggedAt = 0,
		lastFullToast = 0,
	}
	ctx.states[player] = state

	local leaderstats = makeLeaderstats(player)
	state.plot = PlotManager.assignPlot(player)

	-- Every spawn (first, and after every tumble) starts at the player's own base,
	-- facing the lane.
	player.CharacterAdded:Connect(function(character)
		task.wait(0.25)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and state.plot then
			local spawnPosition = state.plot.spawnPosition
			root.CFrame = CFrame.lookAt(spawnPosition, Vector3.new(0, spawnPosition.Y, spawnPosition.Z))
		end
	end)

	task.spawn(function()
		restoreSavedGame(state, leaderstats)
		state.saveLoaded = true
		task.wait(2)
		if player.Parent then
			ctx.toast(player, "Welcome to Brainrot Bay! Grab a wild brainrot on the lane, or buy an egg at the shop.")
		end
	end)
end

local function onPlayerRemoving(player)
	local state = ctx.states[player]
	if not state then
		return
	end
	if state.saveLoaded then
		SaveManager.saveData(state)
	end
	if state.carrying then
		WildManager.removeWild(state.carrying.entry)
		state.carrying = nil
	end
	PlotManager.clearPlaced(state)
	PlotManager.releasePlot(state.plot)
	ctx.states[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, state in pairs(ctx.states) do
		if state.saveLoaded then
			SaveManager.saveData(state)
		end
	end
end)

-- Start the game's clocks.
Economy.startIncomeLoop(ctx)
WildManager.init(ctx)
Threats.init(ctx, world)
SaveManager.startAutosave(ctx)

print("Brainrot Bay is open: " .. #world.plots .. " bases, " .. #BrainrotCatalog.Characters .. " brainrots, one very rude tsunami.")
