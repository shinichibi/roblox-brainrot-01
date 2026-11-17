-- PlotManager.luau (server)
-- Owns the eight base plots: who holds which, which pads are taken, and the placing and
-- removing of the brainrot models that stand on the pads. A placed brainrot is a built
-- model plus a sell prompt; selling itself lives in Economy, reached through ctx.onSell.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotBuilder = require(Shared:WaitForChild("BrainrotBuilder"))
local Money = require(Shared:WaitForChild("Money"))

local PlotManager = {}

local plots = {}

function PlotManager.init(world)
	plots = world.plots
end

-- Hand the first free plot to a joining player and put their name on its sign.
function PlotManager.assignPlot(player)
	for _, plot in ipairs(plots) do
		if plot.owner == nil then
			plot.owner = player
			plot.signLabel.Text = string.upper(player.Name) .. "'S BASE"
			plot.signLabel.TextColor3 = plot.trimColor
			return plot
		end
	end
	return nil
end

-- Free a plot when its owner leaves: sign back to EMPTY BASE, pads back to untaken.
-- (Placed models are destroyed by clearPlaced before this runs.)
function PlotManager.releasePlot(plot)
	if not plot then
		return
	end
	plot.owner = nil
	plot.takenPads = {}
	plot.signLabel.Text = "EMPTY BASE"
	plot.signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- Is this world position inside the plot's platform rectangle (and low enough to be
-- standing on it)? Used for delivering catches and for tsunami safety.
function PlotManager.isInPlot(plot, position)
	if not plot then
		return false
	end
	return math.abs(position.X - plot.center.X) <= plot.halfSize.X
		and math.abs(position.Z - plot.center.Z) <= plot.halfSize.Y
		and position.Y < plot.center.Y + 9
end

local function findFreePad(plot)
	for padIndex = 1, #plot.pads do
		if not plot.takenPads[padIndex] then
			return padIndex
		end
	end
	return nil
end

function PlotManager.hasFreePad(plot)
	return plot ~= nil and findFreePad(plot) ~= nil
end

-- Stand an already-built model on a free pad of the owner's plot, register it as placed
-- and give it a sell prompt. The model is adopted, not rebuilt: a caught wild brainrot
-- keeps its look as it moves from the lane to the base. Returns the placed entry or nil.
function PlotManager.adoptModel(ctx, state, data, model)
	local plot = state.plot
	if not plot then
		return nil
	end
	local padIndex = findFreePad(plot)
	if not padIndex then
		return nil
	end
	local spec = data.spec
	model:PivotTo(CFrame.new(plot.pads[padIndex]) * CFrame.Angles(0, math.rad(-plot.side * 90), 0))
	model.Parent = game:GetService("Workspace")

	local grabPrompt = model.PrimaryPart:FindFirstChild("GrabPrompt")
	if grabPrompt then
		grabPrompt:Destroy()
	end

	local entry = { padIndex = padIndex, data = data, model = model }
	local sellValue = math.floor(spec.value * data.mutationMult * 0.5)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Sell " .. Money.format(sellValue)
	prompt.ObjectText = spec.name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if player == state.player and ctx.onSellBrainrot then
			ctx.onSellBrainrot(player, entry)
		end
	end)
	entry.prompt = prompt

	plot.takenPads[padIndex] = entry
	table.insert(state.placed, entry)
	return entry
end

-- Build a fresh brainrot (an egg hatch, a restored save) straight onto a free pad.
function PlotManager.placeNewBrainrot(ctx, state, data)
	local model = BrainrotBuilder.build(data.spec, data.mutation)
	return PlotManager.adoptModel(ctx, state, data, model)
end

-- Take one placed brainrot off its pad and destroy its model.
function PlotManager.removePlaced(state, entry)
	local plot = state.plot
	if plot and plot.takenPads[entry.padIndex] == entry then
		plot.takenPads[entry.padIndex] = nil
	end
	for i, placed in ipairs(state.placed) do
		if placed == entry then
			table.remove(state.placed, i)
			break
		end
	end
	if entry.model then
		entry.model:Destroy()
	end
end

-- Remove every placed brainrot (rebirth, or the owner leaving).
function PlotManager.clearPlaced(state)
	while #state.placed > 0 do
		PlotManager.removePlaced(state, state.placed[1])
	end
end

return PlotManager
