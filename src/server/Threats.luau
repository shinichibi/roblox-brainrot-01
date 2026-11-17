-- Threats.luau (server)
-- The two dangers of Brainrot Bay. The tsunami: every couple of minutes a siren warns,
-- then a glass-blue wall of water sweeps the island from north to south; anyone caught
-- outside their own base loses the brainrot they are carrying and gets bowled over.
-- And each other: brush against a carrier and their brainrot slips out of their hands.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PlotManager = require(script.Parent.PlotManager)
local WildManager = require(script.Parent.WildManager)

local Threats = {}

local function characterRoot(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Flash the two siren lamps red until `stopAt`, then leave them dark again.
local function flashSirensUntil(sirens, stopAt)
	task.spawn(function()
		local on = false
		while os.clock() < stopAt do
			on = not on
			for _, lamp in ipairs(sirens) do
				lamp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				lamp.Color = on and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(120, 40, 40)
			end
			task.wait(0.35)
		end
		for _, lamp in ipairs(sirens) do
			lamp.Material = Enum.Material.SmoothPlastic
			lamp.Color = Color3.fromRGB(120, 40, 40)
		end
	end)
end

-- Sweep the wave across the island once, hitting everyone it passes who is not home.
local function sweepTsunamiWave(ctx)
	local water = Instance.new("Part")
	water.Name = "TsunamiWave"
	water.Size = Vector3.new(680, 62, 14)
	water.Color = Color3.fromRGB(60, 150, 255)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.35
	water.Anchored = true
	water.CanCollide = false
	water.CanQuery = false
	water.CanTouch = false
	water.Parent = Workspace

	local foam = Instance.new("Part")
	foam.Name = "TsunamiFoam"
	foam.Size = Vector3.new(680, 7, 15)
	foam.Color = Color3.fromRGB(240, 250, 255)
	foam.Material = Enum.Material.SmoothPlastic
	foam.Transparency = 0.15
	foam.Anchored = true
	foam.CanCollide = false
	foam.CanQuery = false
	foam.CanTouch = false
	foam.Parent = Workspace

	local alreadyHit = {}
	local z = -345
	while z < 345 do
		local dt = task.wait(0.05)
		z += 62 * dt
		water.CFrame = CFrame.new(0, 27, z)
		foam.CFrame = CFrame.new(0, 58, z)
		for _, state in pairs(ctx.states) do
			local player = state.player
			local root = characterRoot(player)
			if root and not alreadyHit[player] and z >= root.Position.Z - 4 then
				alreadyHit[player] = true
				if not PlotManager.isInPlot(state.plot, root.Position) then
					if state.carrying then
						local name = state.carrying.entry.data.spec.name
						WildManager.dropCarried(ctx, state, true)
						ctx.toast(player, "The tsunami ripped " .. name .. " out of your hands!")
					end
					root.AssemblyLinearVelocity = Vector3.new(0, 20, 48)
				end
			end
		end
	end
	water:Destroy()
	foam:Destroy()
end

-- The tsunami clock: a first wave soon after the server starts (so new players see the
-- show), then one every couple of minutes, always with ten seconds of sirens first.
local function startTsunamiClock(ctx, world)
	task.spawn(function()
		task.wait(45)
		while true do
			ctx.announce("TSUNAMI IN 10 SECONDS! Carry your brainrots HOME!", Color3.fromRGB(255, 90, 90))
			flashSirensUntil(world.sirens, os.clock() + 12)
			task.wait(10)
			ctx.announce("TSUNAMI!!!", Color3.fromRGB(120, 200, 255))
			sweepTsunamiWave(ctx)
			ctx.announce("The wave has passed... the bay is safe, for now.", Color3.fromRGB(140, 255, 170))
			task.wait(math.random(80, 110))
		end
	end)
end

-- Stealing: four times a second, check every carrier against every empty-handed
-- player; a brush within tagging range knocks the catch loose, slippery for its owner.
local function startStealWatcher(ctx)
	task.spawn(function()
		while true do
			task.wait(0.3)
			for _, carrierState in pairs(ctx.states) do
				if carrierState.carrying and os.clock() - carrierState.carrying.startedAt > 1.5 then
					if os.clock() - (carrierState.lastTaggedAt or 0) > 5 then
						local carrierRoot = characterRoot(carrierState.player)
						if carrierRoot then
							for _, other in ipairs(Players:GetPlayers()) do
								local otherState = ctx.states[other]
								if other ~= carrierState.player and otherState and not otherState.carrying then
									local otherRoot = characterRoot(other)
									if otherRoot and (carrierRoot.Position - otherRoot.Position).Magnitude < 4.2 then
										local name = carrierState.carrying.entry.data.spec.name
										carrierState.lastTaggedAt = os.clock()
										WildManager.dropCarried(ctx, carrierState, true)
										ctx.toast(carrierState.player, other.Name .. " tagged you! Your " .. name .. " slipped out!")
										ctx.toast(other, "You tagged " .. carrierState.player.Name .. "! Grab their " .. name .. "!")
										break
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end

function Threats.init(ctx, world)
	startTsunamiClock(ctx, world)
	startStealWatcher(ctx)
end

return Threats
