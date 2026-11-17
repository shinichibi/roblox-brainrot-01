-- Economy.luau (server)
-- The money: the per-second income tick, the egg shop (hatching), selling placed
-- brainrots, and rebirths. Cash and rebirths live in the player's leaderstats; this
-- module is the only place that moves them (besides SaveManager reading them back).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Money = require(Shared:WaitForChild("Money"))
local PlotManager = require(script.Parent.PlotManager)

local Economy = {}

Economy.STARTING_CASH = 200

-- Rebirth pricing and power: each rebirth costs five times the last and doubles every
-- income the player will ever earn again.
function Economy.rebirthCost(rebirths)
	return 25000 * (5 ^ rebirths)
end

function Economy.rebirthMultiplier(rebirths)
	return 2 ^ rebirths
end

-- Build the instance record every system passes around for one owned brainrot.
function Economy.makeBrainrotData(spec, mutationName)
	local mutation = BrainrotCatalog.MutationByName[mutationName or "Normal"]
	return {
		spec = spec,
		mutation = mutationName or "Normal",
		mutationMult = mutation and mutation.mult or 1,
	}
end

local function leaderstats(player)
	return player:FindFirstChild("leaderstats")
end

local function cashValue(player)
	local stats = leaderstats(player)
	local cash = stats and stats:FindFirstChild("Cash")
	return cash and cash.Value or 0
end

local function addCash(player, amount)
	local stats = leaderstats(player)
	local cash = stats and stats:FindFirstChild("Cash")
	if cash then
		cash.Value += amount
	end
end

-- What a player's whole base earns each second, rebirth multiplier included.
function Economy.computeIncomeRate(state)
	local stats = leaderstats(state.player)
	local rebirths = 0
	if stats and stats:FindFirstChild("Rebirths") then
		rebirths = stats.Rebirths.Value
	end
	local base = 0
	for _, entry in ipairs(state.placed) do
		base += entry.data.spec.income * entry.data.mutationMult
	end
	return base * Economy.rebirthMultiplier(rebirths)
end

-- The heartbeat of the tycoon: every second, pay every base its rate and refresh the
-- Income leaderstat the HUD reads. Fractional income (a x2.5 mutation on $1/s) is
-- carried in state.incomeFraction so nothing is lost to rounding.
function Economy.startIncomeLoop(ctx)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, state in pairs(ctx.states) do
				if state.plot then
					local rate = Economy.computeIncomeRate(state)
					state.incomeFraction = (state.incomeFraction or 0) + rate
					local whole = math.floor(state.incomeFraction)
					if whole > 0 then
						state.incomeFraction -= whole
						addCash(state.player, whole)
					end
					local stats = leaderstats(state.player)
					local income = stats and stats:FindFirstChild("Income")
					if income then
						income.Value = math.floor(rate)
					end
				end
			end
		end
	end)
end

-- Buy and hatch an egg: validate cash and base space, roll the character and its
-- mutation, charge, and stand the newborn on a free pad.
function Economy.buyEgg(ctx, player, eggId)
	local state = ctx.states[player]
	local egg = BrainrotCatalog.EggById[eggId]
	if not state or not egg or not state.plot then
		return
	end
	if cashValue(player) < egg.price then
		ctx.toast(player, "You need " .. Money.format(egg.price) .. " for a " .. egg.name .. "!")
		return
	end
	if not PlotManager.hasFreePad(state.plot) then
		ctx.toast(player, "Your base is full! Sell a brainrot or rebirth to make room.")
		return
	end
	local spec = BrainrotCatalog.rollEgg(egg)
	if not spec then
		return
	end
	local mutation = BrainrotCatalog.rollMutation()
	addCash(player, -egg.price)
	local data = Economy.makeBrainrotData(spec, mutation.name)
	local entry = PlotManager.placeNewBrainrot(ctx, state, data)
	if not entry then
		addCash(player, egg.price)
		ctx.toast(player, "Your base is full! Sell a brainrot or rebirth to make room.")
		return
	end
	ctx.registerCollection(state, spec.id)
	local mutationText = mutation.name ~= "Normal" and (mutation.name .. " ") or ""
	ctx.toast(player, "Your " .. egg.name .. " hatched into a " .. mutationText .. spec.name .. " (" .. spec.rarity .. ")!")
end

-- Sell one placed brainrot back for half its (mutation-multiplied) catalogue value.
function Economy.sellBrainrot(ctx, player, entry)
	local state = ctx.states[player]
	if not state then
		return
	end
	local value = math.floor(entry.data.spec.value * entry.data.mutationMult * 0.5)
	PlotManager.removePlaced(state, entry)
	addCash(player, value)
	ctx.toast(player, "Sold " .. entry.data.spec.name .. " for " .. Money.format(value) .. ".")
end

-- Rebirth: wipe cash and brainrots, keep the collection, double all future income.
-- Returns (ok, message) for the client panel that asked.
function Economy.requestRebirth(ctx, player)
	local state = ctx.states[player]
	local stats = leaderstats(player)
	if not state or not stats then
		return false, "Rebirth is not available right now."
	end
	local rebirths = stats:FindFirstChild("Rebirths") and stats.Rebirths.Value or 0
	local cost = Economy.rebirthCost(rebirths)
	if cashValue(player) < cost then
		return false, "You need " .. Money.format(cost) .. " to rebirth. You have " .. Money.format(cashValue(player)) .. "."
	end
	PlotManager.clearPlaced(state)
	stats.Cash.Value = Economy.STARTING_CASH
	stats.Rebirths.Value = rebirths + 1
	return true, "Rebirth complete! All income is now x" .. Economy.rebirthMultiplier(rebirths + 1) .. ", forever."
end

return Economy
