-- SaveManager.luau (server)
-- Persists each player's cash, rebirths and placed brainrots in a DataStore. Every call is
-- wrapped in pcall: in Studio (or with API access off) the store simply fails and the game
-- runs on session-only progress instead of erroring.

local DataStoreService = game:GetService("DataStoreService")

local SaveManager = {}

local STORE_NAME = "BrainrotBayData_v1"
local store = nil

local function getStore()
	if store == nil then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME)
		end)
		if ok then
			store = result
		end
	end
	return store
end

-- Load a player's saved table, or nil when there is nothing (or nowhere) to load from.
-- Shape: { cash = number, rebirths = number, brainrots = { { id = ..., mutation = ... } } }
function SaveManager.loadData(player)
	local dataStore = getStore()
	if not dataStore then
		return nil
	end
	local ok, data = pcall(function()
		return dataStore:GetAsync("player_" .. player.UserId)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

-- Snapshot a player's live state into the saved shape and write it.
function SaveManager.saveData(state)
	local dataStore = getStore()
	if not dataStore then
		return
	end
	local player = state.player
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local brainrots = {}
	for _, entry in ipairs(state.placed) do
		table.insert(brainrots, { id = entry.data.spec.id, mutation = entry.data.mutation })
	end
	local snapshot = {
		cash = leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0,
		rebirths = leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0,
		brainrots = brainrots,
	}
	pcall(function()
		dataStore:SetAsync("player_" .. player.UserId, snapshot)
	end)
end

-- Save everyone every 90 seconds, so a crash loses little.
function SaveManager.startAutosave(ctx)
	task.spawn(function()
		while true do
			task.wait(90)
			for _, state in pairs(ctx.states) do
				if state.saveLoaded then
					SaveManager.saveData(state)
				end
			end
		end
	end)
end

return SaveManager
