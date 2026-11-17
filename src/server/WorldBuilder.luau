-- WorldBuilder.luau (server)
-- Builds the whole of Brainrot Bay out of parts when the server starts: the island, the
-- central lane wild brainrots stroll on, eight player base plots with six pads each, the
-- egg shop, and the dressing (palms, lamps, the welcome arch, the tsunami sirens). Nothing
-- is placed in Studio: this module is the map, so Rojo and src/ hold the entire game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Money = require(Shared:WaitForChild("Money"))

local WorldBuilder = {}

-- One trim colour per plot slot, in assignment order.
WorldBuilder.PlotColors = {
	Color3.fromRGB(255, 99, 99),
	Color3.fromRGB(255, 164, 60),
	Color3.fromRGB(255, 224, 84),
	Color3.fromRGB(110, 220, 110),
	Color3.fromRGB(84, 190, 255),
	Color3.fromRGB(150, 120, 255),
	Color3.fromRGB(255, 110, 200),
	Color3.fromRGB(110, 235, 215),
}

local PLOT_Z_CENTERS = { -168, -56, 56, 168 }
local PLOT_X = 72
local PAD_OFFSETS_X = { -13, 0, 13 }
local PAD_OFFSETS_Z = { -8.5, 8.5 }

local function makePart(parent, name, size, cframe, color, material, collide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = collide == true
	part.CanQuery = false
	part.Parent = parent
	return part
end

local function makeBillboard(parent, adornee, size, offset, text, textColor, textSize)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Billboard"
	gui.Size = UDim2.fromOffset(size[1], size[2])
	gui.StudsOffset = offset
	gui.AlwaysOnTop = true
	gui.MaxDistance = 220
	gui.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize or 28
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parent
	return label
end

-- The island slab, the sea around it, the asphalt lane with its sidewalks and dashes,
-- and the sandy paths from the lane out to each plot.
local function buildGroundAndLane(workspace)
	local water = makePart(workspace, "BayWater", Vector3.new(1100, 4, 1100), CFrame.new(0, -4.5, 0), Color3.fromRGB(52, 130, 200), Enum.Material.SmoothPlastic, false)
	water.Transparency = 0.25
	makePart(workspace, "Island", Vector3.new(620, 2, 620), CFrame.new(0, -1, 0), Color3.fromRGB(104, 188, 96), Enum.Material.SmoothPlastic, true)
	makePart(workspace, "LaneRoad", Vector3.new(34, 0.4, 580), CFrame.new(0, 0.2, 0), Color3.fromRGB(56, 56, 64), Enum.Material.Asphalt, true)
	for _, side in ipairs({ -1, 1 }) do
		makePart(workspace, "Sidewalk", Vector3.new(8, 0.5, 580), CFrame.new(side * 21, 0.25, 0), Color3.fromRGB(172, 172, 178), Enum.Material.Concrete, true)
		for _, zc in ipairs(PLOT_Z_CENTERS) do
			makePart(workspace, "PlotPath", Vector3.new(26, 0.3, 9), CFrame.new(side * 37, 0.15, zc), Color3.fromRGB(226, 204, 158), Enum.Material.Sand, true)
		end
	end
	for z = -270, 270, 18 do
		makePart(workspace, "LaneDash", Vector3.new(0.9, 0.44, 6), CFrame.new(0, 0.22, z), Color3.fromRGB(245, 230, 150), Enum.Material.SmoothPlastic, false)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BaySpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 0.5, 238)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(226, 204, 158)
	spawn.Material = Enum.Material.Sand
	spawn.Parent = workspace
end

-- One base plot: a raised platform, a coloured trim, six brainrot pads, a path-side sign
-- and the spot its owner spawns on. Returns the plot table PlotManager works with.
local function buildPlot(workspace, index, side, zCenter, trimColor)
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder.Parent = workspace

	local centerX = side * PLOT_X
	local platform = makePart(folder, "Platform", Vector3.new(46, 2, 36), CFrame.new(centerX, 1, zCenter), Color3.fromRGB(203, 200, 192), Enum.Material.Concrete, true)

	-- Trim: four bright strips around the platform's top edge, in the slot's colour.
	makePart(folder, "TrimFront", Vector3.new(46, 0.5, 1.2), CFrame.new(centerX, 2.1, zCenter - 17.4), trimColor, Enum.Material.Neon, false)
	makePart(folder, "TrimBack", Vector3.new(46, 0.5, 1.2), CFrame.new(centerX, 2.1, zCenter + 17.4), trimColor, Enum.Material.Neon, false)
	makePart(folder, "TrimLeft", Vector3.new(1.2, 0.5, 36), CFrame.new(centerX - 22.4, 2.1, zCenter), trimColor, Enum.Material.Neon, false)
	makePart(folder, "TrimRight", Vector3.new(1.2, 0.5, 36), CFrame.new(centerX + 22.4, 2.1, zCenter), trimColor, Enum.Material.Neon, false)

	local pads = {}
	local padParts = {}
	for row, offsetZ in ipairs(PAD_OFFSETS_Z) do
		for col, offsetX in ipairs(PAD_OFFSETS_X) do
			local padIndex = (row - 1) * 3 + col
			local padPosition = Vector3.new(centerX + offsetX, 2.3, zCenter + offsetZ)
			local pad = makePart(folder, "Pad" .. padIndex, Vector3.new(7, 0.6, 7), CFrame.new(padPosition), Color3.fromRGB(120, 118, 128), Enum.Material.SmoothPlastic, true)
			pads[padIndex] = padPosition + Vector3.new(0, 0.3, 0)
			padParts[padIndex] = pad
		end
	end

	-- The sign stands on the lane side of the platform and carries the owner's name.
	local signX = centerX - side * 24.5
	local post = makePart(folder, "SignPost", Vector3.new(0.8, 7, 0.8), CFrame.new(signX, 3.5, zCenter - 13), Color3.fromRGB(110, 80, 55), Enum.Material.Wood, false)
	local board = makePart(folder, "SignBoard", Vector3.new(0.6, 4.6, 13), CFrame.new(signX, 7.6, zCenter - 13), trimColor, Enum.Material.Wood, false)
	local signLabel = makeBillboard(board, board, { 340, 80 }, Vector3.new(0, 1.2, 0), "EMPTY BASE", Color3.fromRGB(255, 255, 255), 30)
	post.CanCollide = false

	return {
		index = index,
		side = side,
		center = Vector3.new(centerX, 2, zCenter),
		halfSize = Vector2.new(23, 18),
		platform = platform,
		pads = pads,
		padParts = padParts,
		signLabel = signLabel,
		trimColor = trimColor,
		spawnPosition = Vector3.new(centerX - side * 16, 3.4, zCenter + 12),
		owner = nil,
		takenPads = {},
	}
end

-- A display egg for the shop: a speckled squashed ball on a pedestal, with a price
-- billboard and the ProximityPrompt the Economy module listens to.
local function buildEggDisplay(parent, egg, x, z)
	local pedestal = makePart(parent, "Pedestal_" .. egg.id, Vector3.new(4.4, 2.4, 4.4), CFrame.new(x, 1.2, z), Color3.fromRGB(90, 85, 100), Enum.Material.Concrete, true)
	local eggPart = Instance.new("Part")
	eggPart.Name = "Egg_" .. egg.id
	eggPart.Shape = Enum.PartType.Ball
	eggPart.Size = Vector3.new(3.1, 3.9, 3.1)
	eggPart.CFrame = CFrame.new(x, 4.6, z)
	eggPart.Color = Color3.fromRGB(egg.color[1], egg.color[2], egg.color[3])
	eggPart.Material = Enum.Material.SmoothPlastic
	eggPart.Anchored = true
	eggPart.CanCollide = false
	eggPart.Parent = parent
	for i = 1, 5 do
		local angle = i * 2.4
		local spot = makePart(parent, "Speckle", Vector3.new(0.55, 0.55, 0.55), CFrame.new(x + math.sin(angle) * 1.35, 4.6 + math.cos(i * 1.7) * 1.2, z + math.cos(angle) * 1.35), Color3.fromRGB(egg.speckle[1], egg.speckle[2], egg.speckle[3]), Enum.Material.SmoothPlastic, false)
		spot.Shape = Enum.PartType.Ball
	end
	makeBillboard(eggPart, eggPart, { 240, 64 }, Vector3.new(0, 3.4, 0), egg.name .. "  " .. Money.format(egg.price), Color3.fromRGB(255, 255, 255), 24)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = egg.name .. " " .. Money.format(egg.price)
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = eggPart

	return { eggId = egg.id, part = eggPart, prompt = prompt, pedestal = pedestal }
end

-- The egg shop at the north end of the lane: a roofed booth, a counter, a big sign and
-- the three egg displays.
local function buildShop(workspace)
	local shop = Instance.new("Folder")
	shop.Name = "EggShop"
	shop.Parent = workspace

	makePart(shop, "Counter", Vector3.new(40, 2.6, 5), CFrame.new(0, 1.3, -208), Color3.fromRGB(150, 105, 65), Enum.Material.Wood, true)
	makePart(shop, "Roof", Vector3.new(46, 1, 14), CFrame.new(0, 10.5, -211), Color3.fromRGB(220, 70, 80), Enum.Material.SmoothPlastic, false)
	for _, px in ipairs({ -20, 20 }) do
		for _, pz in ipairs({ -216, -206 }) do
			makePart(shop, "RoofPost", Vector3.new(1.2, 10, 1.2), CFrame.new(px, 5, pz), Color3.fromRGB(110, 80, 55), Enum.Material.Wood, false)
		end
	end
	local sign = makePart(shop, "ShopSign", Vector3.new(30, 4.4, 0.8), CFrame.new(0, 13.6, -211), Color3.fromRGB(255, 190, 60), Enum.Material.Wood, false)
	makeBillboard(sign, sign, { 460, 90 }, Vector3.new(0, 0.8, 0), "EGG SHOP", Color3.fromRGB(255, 255, 255), 44)

	local stands = {}
	local xs = { -12, 0, 12 }
	for i, egg in ipairs(BrainrotCatalog.Eggs) do
		stands[i] = buildEggDisplay(shop, egg, xs[i], -213)
	end
	return stands
end

-- Palms, lamps, the welcome arch, two tsunami siren posts and a few lazy clouds.
local function buildDecorations(workspace)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = workspace

	for _, side in ipairs({ -1, 1 }) do
		for z = -250, 250, 50 do
			if math.abs(z) % 100 == 50 or side == 1 then
				local trunk = makePart(decor, "PalmTrunk", Vector3.new(1.1, 8, 1.1), CFrame.new(side * 28, 4, z) * CFrame.Angles(0, 0, side * math.rad(7)), Color3.fromRGB(140, 105, 70), Enum.Material.Wood, false)
				trunk.Shape = Enum.PartType.Cylinder
				for leaf = 1, 3 do
					local angle = leaf * 2.1 + z
					local leafPart = makePart(decor, "PalmLeaf", Vector3.new(6.5, 1.1, 2.6), CFrame.new(side * 28 - side * 0.6 + math.sin(angle) * 1.6, 8.4, z + math.cos(angle) * 1.6) * CFrame.Angles(0, angle, 0), Color3.fromRGB(70, 170, 80), Enum.Material.SmoothPlastic, false)
					leafPart.Shape = Enum.PartType.Ball
				end
			end
		end
		for z = -225, 225, 90 do
			makePart(decor, "LampPole", Vector3.new(0.5, 6.5, 0.5), CFrame.new(side * 17.5, 3.25, z), Color3.fromRGB(60, 60, 70), Enum.Material.Metal, false)
			local bulb = makePart(decor, "LampBulb", Vector3.new(1.1, 1.1, 1.1), CFrame.new(side * 17.5, 6.9, z), Color3.fromRGB(255, 240, 170), Enum.Material.Neon, false)
			bulb.Shape = Enum.PartType.Ball
		end
	end

	-- The welcome arch over the lane by the spawn.
	for _, side in ipairs({ -1, 1 }) do
		makePart(decor, "ArchPillar", Vector3.new(2.4, 15, 2.4), CFrame.new(side * 19, 7.5, 222), Color3.fromRGB(240, 160, 70), Enum.Material.Wood, false)
	end
	local beam = makePart(decor, "ArchBeam", Vector3.new(42, 3.4, 2.4), CFrame.new(0, 15.5, 222), Color3.fromRGB(240, 160, 70), Enum.Material.Wood, false)
	makeBillboard(beam, beam, { 620, 110 }, Vector3.new(0, 1.4, 0), "BRAINROT BAY", Color3.fromRGB(255, 255, 255), 54)

	-- Clouds: flat white blobs drifting nowhere, high above the bay.
	for i = 1, 6 do
		local x = -260 + i * 85
		local z = -180 + (i % 3) * 150
		local cloud = makePart(decor, "Cloud", Vector3.new(34, 5, 18), CFrame.new(x, 64 + (i % 2) * 8, z), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic, false)
		cloud.Shape = Enum.PartType.Ball
		cloud.Transparency = 0.15
	end

	-- Tsunami sirens: a post and a lamp the Threats module flashes during a warning.
	local sirens = {}
	for _, side in ipairs({ -1, 1 }) do
		makePart(decor, "SirenPost", Vector3.new(0.7, 10, 0.7), CFrame.new(side * 19, 5, -6), Color3.fromRGB(80, 80, 90), Enum.Material.Metal, false)
		local lamp = makePart(decor, "SirenLamp", Vector3.new(1.7, 1.7, 1.7), CFrame.new(side * 19, 10.6, -6), Color3.fromRGB(120, 40, 40), Enum.Material.SmoothPlastic, false)
		lamp.Shape = Enum.PartType.Ball
		table.insert(sirens, lamp)
	end
	return sirens
end

-- WorldBuilder.build() -> { plots, eggStands, sirens, lane }
function WorldBuilder.build()
	local workspace = game:GetService("Workspace")
	buildGroundAndLane(workspace)

	local plots = {}
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, zCenter in ipairs(PLOT_Z_CENTERS) do
			index += 1
			plots[index] = buildPlot(workspace, index, side, zCenter, WorldBuilder.PlotColors[index])
		end
	end

	local eggStands = buildShop(workspace)
	local sirens = buildDecorations(workspace)

	return {
		plots = plots,
		eggStands = eggStands,
		sirens = sirens,
		lane = { minZ = -262, maxZ = 262, halfWidth = 13 },
	}
end

return WorldBuilder
