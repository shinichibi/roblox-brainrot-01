-- WildManager.luau (server)
-- The wild brainrots on the lane: spawning them, their idle wandering, being grabbed,
-- carried home on a player's head, delivered onto a base pad, and dropped (by tsunami,
-- by a rival's tag, or by their carrier leaving). Also runs the one animation loop that
-- bobs every brainrot in the world and cycles the Rainbow mutation's paint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local BrainrotBuilder = require(Shared:WaitForChild("BrainrotBuilder"))
local PlotManager = require(script.Parent.PlotManager)
local Economy = require(script.Parent.Economy)

local WildManager = {}

local MAX_WILD = 6
local CARRY_WALK_SPEED = 14
local NORMAL_WALK_SPEED = 16

local wildEntries = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- Raycast straight down for the ground under a point, ignoring every player's character
-- and any extra instances named (so a dropped brainrot lands on the floor, not a head).
local function groundPositionAt(x, z, fromY, extraExclusions)
	local exclusions = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(exclusions, player.Character)
		end
	end
	if extraExclusions then
		for _, instance in ipairs(extraExclusions) do
			table.insert(exclusions, instance)
		end
	end
	raycastParams.FilterDescendantsInstances = exclusions
	local result = Workspace:Raycast(Vector3.new(x, fromY or 60, z), Vector3.new(0, -80, 0), raycastParams)
	if result then
		return result.Position
	end
	return Vector3.new(x, 0.45, z)
end

local function characterRoot(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function setWalkSpeed(player, speed)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

-- Spawn one wild brainrot somewhere along the lane, with its Grab prompt.
local function spawnWildBrainrot(ctx)
	local spec = BrainrotCatalog.rollWildCharacter()
	if not spec then
		return
	end
	local mutation = BrainrotCatalog.rollMutation()
	local data = Economy.makeBrainrotData(spec, mutation.name)
	local x = math.random(-110, 110) / 10
	local z = math.random(-190, 215)
	local position = groundPositionAt(x, z)
	local model = BrainrotBuilder.build(spec, mutation.name)
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = Workspace

	local entry = {
		model = model,
		data = data,
		home = position,
		target = position,
		position = position,
		phase = math.random() * 10,
		carriedBy = nil,
		lockouts = {},
	}
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "Grab"
	prompt.ObjectText = spec.name
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	entry.prompt = prompt
	prompt.Triggered:Connect(function(player)
		WildManager.tryGrab(ctx, player, entry)
	end)

	table.insert(wildEntries, entry)
end

-- Pick up a wild brainrot: it rides on the carrier's head until it is delivered home,
-- dropped, or torn away. One at a time, and never twice in a row after a drop.
function WildManager.tryGrab(ctx, player, entry)
	local state = ctx.states[player]
	if not state or entry.carriedBy then
		return
	end
	if state.carrying then
		ctx.toast(player, "You are already carrying a brainrot! Take it home first.")
		return
	end
	local lockoutUntil = entry.lockouts[player]
	if lockoutUntil and os.clock() < lockoutUntil then
		ctx.toast(player, "It keeps slipping out of your hands! Try again in a second.")
		return
	end
	entry.carriedBy = player
	entry.prompt.Enabled = false
	state.carrying = { entry = entry, startedAt = os.clock() }
	setWalkSpeed(player, CARRY_WALK_SPEED)
	ctx.updateCarryUi(player, entry.data.spec.name)
	ctx.toast(player, "You grabbed " .. entry.data.spec.name .. "! Run it home to YOUR base!")
end

-- Put down whatever a player is carrying, where they stand. With `slippery`, the
-- dropper cannot grab the same brainrot again for a few seconds (a steal, a wave).
function WildManager.dropCarried(ctx, state, slippery)
	local carrying = state.carrying
	if not carrying then
		return
	end
	local entry = carrying.entry
	state.carrying = nil
	entry.carriedBy = nil
	local root = characterRoot(state.player)
	local position
	if root then
		position = groundPositionAt(root.Position.X, root.Position.Z, root.Position.Y + 6, { entry.model })
	else
		position = entry.home
	end
	entry.home = position
	entry.target = position
	entry.position = position
	entry.model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	entry.prompt.Enabled = true
	if slippery then
		entry.lockouts[state.player] = os.clock() + 3
	end
	setWalkSpeed(state.player, NORMAL_WALK_SPEED)
	ctx.updateCarryUi(state.player, nil)
end

-- Destroy a wild brainrot outright (its carrier left the game while holding it).
function WildManager.removeWild(entry)
	for i, wild in ipairs(wildEntries) do
		if wild == entry then
			table.remove(wildEntries, i)
			break
		end
	end
	if entry.model then
		entry.model:Destroy()
	end
end

-- Deliver a carried brainrot: when its carrier stands on their own plot, the model is
-- adopted onto a free pad by PlotManager and starts earning.
local function tryDeliverCarried(ctx, state)
	local root = characterRoot(state.player)
	if not root or not state.plot then
		return
	end
	if not PlotManager.isInPlot(state.plot, root.Position) then
		return
	end
	local entry = state.carrying.entry
	local placed = PlotManager.adoptModel(ctx, state, entry.data, entry.model)
	if placed then
		for i, wild in ipairs(wildEntries) do
			if wild == entry then
				table.remove(wildEntries, i)
				break
			end
		end
		state.carrying = nil
		setWalkSpeed(state.player, NORMAL_WALK_SPEED)
		ctx.updateCarryUi(state.player, nil)
		ctx.registerCollection(state, entry.data.spec.id)
		ctx.toast(state.player, entry.data.spec.name .. " is home and earning " .. entry.data.spec.income * entry.data.mutationMult .. " dollars a second!")
	else
		local now = os.clock()
		if now - (state.lastFullToast or 0) > 3 then
			state.lastFullToast = now
			ctx.toast(state.player, "Your base is full! Sell a brainrot or rebirth to make room.")
		end
	end
end

local function cycleRainbowPaint(model, t)
	if model:GetAttribute("Rainbow") and model.PrimaryPart then
		model.PrimaryPart.Color = Color3.fromHSV((t * 0.12 + (model.PrimaryPart.Position.X % 10) / 14) % 1, 0.6, 1)
	end
end

-- One loop drives every brainrot's motion: wild ones wander around their home spot,
-- carried ones ride heads, placed ones bob on their pads; Rainbow paint cycles.
local function startAnimationLoop(ctx)
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for _, entry in ipairs(wildEntries) do
			local model = entry.model
			if entry.carriedBy then
				local root = characterRoot(entry.carriedBy)
				if root then
					local head = root.Parent:FindFirstChild("Head") or root
					local bob = math.sin(t * 3 + entry.phase) * 0.15
					local pos = head.Position + Vector3.new(0, 2.3 + bob, 0)
					model:PivotTo(CFrame.new(pos, pos + root.CFrame.LookVector))
				end
			else
				local toTarget = entry.target - entry.position
				toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
				if toTarget.Magnitude < 0.7 then
					local angle = math.random() * math.pi * 2
					local radius = math.random(2, 9)
					entry.target = entry.home + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				else
					local step = toTarget.Unit * math.min(2.2 * dt, toTarget.Magnitude)
					entry.position += step
					local bob = math.abs(math.sin(t * 4 + entry.phase)) * 0.22
					local facing = entry.position + toTarget
					model:PivotTo(CFrame.lookAt(Vector3.new(entry.position.X, entry.position.Y + bob, entry.position.Z), Vector3.new(facing.X, entry.position.Y + bob, facing.Z)))
				end
			end
			cycleRainbowPaint(model, t)
		end
		for _, state in pairs(ctx.states) do
			if state.plot then
				for _, placed in ipairs(state.placed) do
					local padPosition = state.plot.pads[placed.padIndex]
					local bob = math.sin(t * 2 + placed.padIndex * 1.3) * 0.1
					placed.model:PivotTo(CFrame.new(padPosition + Vector3.new(0, bob, 0)) * CFrame.Angles(0, math.rad(-state.plot.side * 90), 0))
					cycleRainbowPaint(placed.model, t)
				end
			end
		end
	end)
end

-- Start the spawner (a fresh wild brainrot every few seconds up to the cap) and the
-- delivery watcher (four times a second, is any carrier home yet?).
function WildManager.init(ctx)
	task.spawn(function()
		while true do
			task.wait(5)
			if #wildEntries < MAX_WILD then
				spawnWildBrainrot(ctx)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, state in pairs(ctx.states) do
				if state.carrying and os.clock() - state.carrying.startedAt > 0.8 then
					tryDeliverCarried(ctx, state)
				end
			end
		end
	end)
	startAnimationLoop(ctx)
end

return WildManager
