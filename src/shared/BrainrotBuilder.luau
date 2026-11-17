-- BrainrotBuilder.luau
-- Composes a brainrot character out of primitive parts from its BrainrotCatalog spec:
-- a shaped body, a belly, two eyes, a mouth, feet and one signature accessory (a crown,
-- a tophat, a vampire cape, a pair of shades...). Every model is anchored and collision-free,
-- with the Body as its PrimaryPart and a billboard label riding on top, so the server can
-- stand it on a base pad, wander it down the lane or park it on a carrier's head by PivotTo.

local BrainrotCatalog = require(script.Parent.BrainrotCatalog)
local Money = require(script.Parent.Money)

local BrainrotBuilder = {}

local function makePart(name, shape, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

local function rgb(triple)
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

-- The extra prop that makes a character itself. Positions are relative to a body of
-- width w, height h, depth d whose feet stand on y = 0 and whose face looks along +Z.
local ACCESSORY_BUILDERS = {}

ACCESSORY_BUILDERS.crown = function(add, w, h, d)
	local gold = Color3.fromRGB(255, 200, 40)
	add("CrownBand", Enum.PartType.Cylinder, Vector3.new(0.35, w * 0.56, w * 0.56), CFrame.new(0, h - 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal)
	for i = 1, 3 do
		local angle = (i - 2) * 0.7
		add("CrownSpike", Enum.PartType.Block, Vector3.new(0.34, 0.55, 0.34), CFrame.new(math.sin(angle) * w * 0.24, h + 0.22, math.cos(angle) * w * 0.24 - w * 0.1), gold, Enum.Material.Metal)
	end
end

ACCESSORY_BUILDERS.tophat = function(add, w, h, d)
	local black = Color3.fromRGB(35, 35, 42)
	add("HatBrim", Enum.PartType.Cylinder, Vector3.new(0.14, w * 0.8, w * 0.8), CFrame.new(0, h - 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), black)
	add("HatTop", Enum.PartType.Cylinder, Vector3.new(1, w * 0.52, w * 0.52), CFrame.new(0, h + 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), black)
	add("HatBand", Enum.PartType.Cylinder, Vector3.new(0.22, w * 0.56, w * 0.56), CFrame.new(0, h + 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 40, 50))
end

ACCESSORY_BUILDERS.eyepatch = function(add, w, h, d, frontZ, eyeY)
	add("Eyepatch", Enum.PartType.Block, Vector3.new(0.8, 0.8, 0.1), CFrame.new(w * 0.18, eyeY, frontZ + 0.1), Color3.fromRGB(25, 25, 30))
	add("PatchStrap", Enum.PartType.Block, Vector3.new(w * 0.95, 0.14, 0.08), CFrame.new(0, eyeY + h * 0.16, frontZ + 0.02) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(25, 25, 30))
end

ACCESSORY_BUILDERS.headphones = function(add, w, h, d)
	local shell = Color3.fromRGB(45, 45, 60)
	add("LeftCup", Enum.PartType.Cylinder, Vector3.new(0.3, 0.85, 0.85), CFrame.new(-(w / 2 + 0.1), h * 0.62, 0), shell)
	add("RightCup", Enum.PartType.Cylinder, Vector3.new(0.3, 0.85, 0.85), CFrame.new(w / 2 + 0.1, h * 0.62, 0), shell)
	add("HeadBand", Enum.PartType.Block, Vector3.new(w + 0.5, 0.18, 0.36), CFrame.new(0, h * 0.99, 0), shell)
end

ACCESSORY_BUILDERS.glasses = function(add, w, h, d, frontZ, eyeY)
	local frame = Color3.fromRGB(30, 30, 38)
	local function lens(x)
		local glass = add("Lens", Enum.PartType.Block, Vector3.new(0.66, 0.66, 0.08), CFrame.new(x, eyeY, frontZ + 0.12), frame)
		glass.Transparency = 0.35
	end
	lens(-w * 0.18)
	lens(w * 0.18)
	add("Bridge", Enum.PartType.Block, Vector3.new(0.34, 0.1, 0.08), CFrame.new(0, eyeY + 0.05, frontZ + 0.12), frame)
end

ACCESSORY_BUILDERS.fork = function(add, w, h, d)
	local silver = Color3.fromRGB(215, 218, 225)
	local tilt = CFrame.Angles(0, 0, math.rad(-14))
	add("ForkHandle", Enum.PartType.Cylinder, Vector3.new(1.7, 0.16, 0.16), CFrame.new(w / 2 + 0.45, h * 0.42, 0.25) * tilt, silver, Enum.Material.Metal)
	for i = -1, 1 do
		add("ForkProng", Enum.PartType.Block, Vector3.new(0.11, 0.55, 0.11), CFrame.new(w / 2 + 0.45 + i * 0.16, h * 0.42 + 1.05, 0.25) * tilt, silver, Enum.Material.Metal)
	end
end

ACCESSORY_BUILDERS.toast = function(add, w, h, d)
	local crust = Color3.fromRGB(196, 138, 76)
	local crumb = Color3.fromRGB(240, 205, 150)
	add("ToastOne", Enum.PartType.Block, Vector3.new(1, 1.1, 0.24), CFrame.new(-0.3, h + 0.3, 0) * CFrame.Angles(0, 0, math.rad(-9)), crumb)
	add("ToastTwo", Enum.PartType.Block, Vector3.new(1, 1.1, 0.24), CFrame.new(0.35, h + 0.36, -0.1) * CFrame.Angles(0, 0, math.rad(11)), crust)
end

ACCESSORY_BUILDERS.beak = function(add, w, h, d, frontZ, eyeY)
	local orange = Color3.fromRGB(255, 140, 40)
	add("BeakTop", Enum.PartType.Block, Vector3.new(0.75, 0.3, 0.55), CFrame.new(0, eyeY - h * 0.14, frontZ + 0.18), orange)
	add("BeakBottom", Enum.PartType.Block, Vector3.new(0.6, 0.2, 0.4), CFrame.new(0, eyeY - h * 0.24, frontZ + 0.12), orange)
	add("Bowtie", Enum.PartType.Block, Vector3.new(0.85, 0.4, 0.2), CFrame.new(0, h * 0.18, frontZ + 0.02), Color3.fromRGB(220, 50, 80))
end

ACCESSORY_BUILDERS.cap = function(add, w, h, d)
	add("CapDome", Enum.PartType.Ball, Vector3.new(w * 0.66, 0.55, d * 0.66), CFrame.new(0, h - 0.12, 0), Color3.fromRGB(220, 60, 60))
	add("CapBrim", Enum.PartType.Block, Vector3.new(w * 0.5, 0.12, 0.8), CFrame.new(0, h - 0.2, d / 2 + 0.2), Color3.fromRGB(220, 60, 60))
end

ACCESSORY_BUILDERS.cape = function(add, w, h, d)
	add("Cape", Enum.PartType.Block, Vector3.new(w * 0.92, h * 0.88, 0.14), CFrame.new(0, h * 0.46, -(d / 2 + 0.12)) * CFrame.Angles(math.rad(6), 0, 0), Color3.fromRGB(120, 30, 45))
	add("CapeGem", Enum.PartType.Ball, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, h * 0.82, d / 2 + 0.05), Color3.fromRGB(255, 70, 90), Enum.Material.Neon)
end

ACCESSORY_BUILDERS.dome = function(add, w, h, d)
	local dome = add("HelmetDome", Enum.PartType.Ball, Vector3.new(w * 1.28, h * 0.78, d * 1.28), CFrame.new(0, h * 0.62, 0), Color3.fromRGB(235, 245, 255), Enum.Material.Glass)
	dome.Transparency = 0.55
	add("HelmetRing", Enum.PartType.Cylinder, Vector3.new(0.3, w * 1.1, w * 1.1), CFrame.new(0, h * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 170, 90), Enum.Material.Metal)
end

ACCESSORY_BUILDERS.conehat = function(add, w, h, d)
	local red = Color3.fromRGB(205, 45, 55)
	add("HatTierOne", Enum.PartType.Cylinder, Vector3.new(0.5, w * 0.66, w * 0.66), CFrame.new(0, h + 0.18, 0) * CFrame.Angles(0, 0, math.rad(90)), red)
	add("HatTierTwo", Enum.PartType.Cylinder, Vector3.new(0.5, w * 0.44, w * 0.44), CFrame.new(0, h + 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)), red)
	add("HatTierThree", Enum.PartType.Cylinder, Vector3.new(0.45, w * 0.22, w * 0.22), CFrame.new(0, h + 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
end

ACCESSORY_BUILDERS.straw = function(add, w, h, d)
	local pink = Color3.fromRGB(255, 90, 150)
	add("StrawUp", Enum.PartType.Cylinder, Vector3.new(1.5, 0.3, 0.3), CFrame.new(0.25, h + 0.55, 0) * CFrame.Angles(0, 0, math.rad(-18)), pink)
	add("StrawBend", Enum.PartType.Cylinder, Vector3.new(0.7, 0.3, 0.3), CFrame.new(0.62, h + 1.2, 0) * CFrame.Angles(0, 0, math.rad(55)), pink)
	add("Sprinkles", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(-0.5, h * 0.85, d * 0.3), Color3.fromRGB(120, 220, 255), Enum.Material.Neon)
end

ACCESSORY_BUILDERS.star = function(add, w, h, d)
	local gold = Color3.fromRGB(255, 215, 70)
	add("StarArmOne", Enum.PartType.Block, Vector3.new(1.05, 1.05, 0.16), CFrame.new(w * 0.42, h + 0.3, 0), gold, Enum.Material.Neon)
	add("StarArmTwo", Enum.PartType.Block, Vector3.new(1.05, 1.05, 0.16), CFrame.new(w * 0.42, h + 0.3, 0) * CFrame.Angles(0, 0, math.rad(45)), gold, Enum.Material.Neon)
end

ACCESSORY_BUILDERS.shades = function(add, w, h, d, frontZ, eyeY)
	add("Shades", Enum.PartType.Block, Vector3.new(w * 0.64, 0.52, 0.12), CFrame.new(0, eyeY, frontZ + 0.12), Color3.fromRGB(15, 15, 20), Enum.Material.Glass)
end

-- Build the billboard label that rides over a brainrot: its name, its rarity (and mutation
-- when it has one) and what it earns a second.
local function buildLabel(model, body, spec, mutationName, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(230, 78)
	gui.StudsOffset = Vector3.new(0, height / 2 + 1.7, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui

	local function line(name, text, size, color)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, 0, 0, size + 6)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextSize = size
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.35
		label.Parent = gui
		return label
	end

	line("NameLine", spec.name, 20, Color3.fromRGB(255, 255, 255))
	local infoText = spec.rarity
	local infoColor = Money.RarityColors[spec.rarity]
	if mutationName and mutationName ~= "Normal" then
		infoText = mutationName .. " " .. spec.rarity
		infoColor = Money.MutationColors[mutationName] or infoColor
	end
	line("InfoLine", infoText, 15, infoColor)
	local mutation = BrainrotCatalog.MutationByName[mutationName or "Normal"]
	local income = spec.income * (mutation and mutation.mult or 1)
	line("IncomeLine", Money.format(income) .. "/s", 16, Color3.fromRGB(140, 255, 150))

	gui.Adornee = body
	gui.Parent = model
end

-- BrainrotBuilder.build(spec, mutationName) -> Model
-- The model's pivot sits at the ground between its feet; stand it anywhere with PivotTo.
function BrainrotBuilder.build(spec, mutationName)
	local bodySpec = spec.body
	local w, h, d = bodySpec.size[1], bodySpec.size[2], bodySpec.size[3]
	local bodyColor = rgb(bodySpec.color)
	local mutation = BrainrotCatalog.MutationByName[mutationName or "Normal"]

	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. spec.id
	model:SetAttribute("BrainrotId", spec.id)
	model:SetAttribute("Mutation", mutationName or "Normal")
	if mutationName == "Rainbow" then
		model:SetAttribute("Rainbow", true)
	end

	local parts = {}
	local function add(name, shape, size, cframe, color, material)
		local part = makePart(name, shape, size, cframe, color, material)
		part.Parent = model
		table.insert(parts, part)
		return part
	end

	-- The body. A cylinder either stands upright (pickle, burrito) or faces forward like a
	-- coin (the cookie), which is the spec's optional `axis = "front"`. A cylinder part's
	-- length runs along its local X, so each orientation rotates that axis into place.
	-- `frontZ` tracks where the face sits so the eyes and belly land on it.
	local body
	local frontZ = d / 2
	if bodySpec.shape == "Cylinder" and bodySpec.axis == "front" then
		body = add("Body", Enum.PartType.Cylinder, Vector3.new(h, w, w), CFrame.new(0, w / 2, 0) * CFrame.Angles(0, math.rad(90), 0), bodyColor)
		frontZ = h / 2
		h = w
	elseif bodySpec.shape == "Cylinder" then
		body = add("Body", Enum.PartType.Cylinder, Vector3.new(h, w, w), CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), bodyColor)
		frontZ = w / 2
	else
		local shape = bodySpec.shape == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
		body = add("Body", shape, Vector3.new(w, h, d), CFrame.new(0, h / 2, 0), bodyColor)
	end
	body.CanQuery = true
	model.PrimaryPart = body

	-- Mutation repaint: gold plate, glassy diamond, or a rainbow the animation loop cycles.
	if mutationName == "Golden" then
		body.Color = Color3.fromRGB(255, 196, 45)
		body.Material = Enum.Material.Metal
	elseif mutationName == "Diamond" then
		body.Color = Color3.fromRGB(165, 235, 255)
		body.Material = Enum.Material.Glass
		body.Transparency = 0.25
	end

	-- A soft shadow disc so the character reads as standing on the ground.
	local shadow = add("Shadow", Enum.PartType.Cylinder, Vector3.new(0.08, w * 1.15, w * 1.15), CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 40, 30))
	shadow.Transparency = 0.55

	-- Belly patch on the front, when the spec paints one.
	if bodySpec.belly then
		local belly = add("Belly", Enum.PartType.Ball, Vector3.new(w * 0.62, h * 0.52, 0.5), CFrame.new(0, h * 0.36, frontZ - 0.12), rgb(bodySpec.belly))
		if mutationName == "Golden" then
			belly.Color = Color3.fromRGB(255, 224, 130)
		end
	end

	-- Face: two white eyes with pupils and a small smile-dark mouth, all on the +Z front.
	local eyeY = h * 0.62
	local eyeX = w * 0.18
	for _, side in ipairs({ -1, 1 }) do
		add("Eye", Enum.PartType.Ball, Vector3.new(0.52, 0.62, 0.3), CFrame.new(side * eyeX, eyeY, frontZ - 0.05), Color3.fromRGB(255, 255, 255))
		add("Pupil", Enum.PartType.Ball, Vector3.new(0.26, 0.3, 0.18), CFrame.new(side * eyeX, eyeY - 0.03, frontZ + 0.1), Color3.fromRGB(20, 20, 26))
	end
	add("Mouth", Enum.PartType.Block, Vector3.new(w * 0.26, 0.12, 0.1), CFrame.new(0, h * 0.4, frontZ + 0.02), Color3.fromRGB(60, 35, 35))

	-- Two little feet peeking out at the front.
	for _, side in ipairs({ -1, 1 }) do
		add("Foot", Enum.PartType.Block, Vector3.new(0.72, 0.3, 0.95), CFrame.new(side * w * 0.22, 0.15, d * 0.16), Color3.fromRGB(70, 55, 50))
	end

	-- The signature accessory.
	local accessoryBuilder = ACCESSORY_BUILDERS[spec.accessory]
	if accessoryBuilder then
		accessoryBuilder(add, w, h, d, frontZ, eyeY)
	end

	buildLabel(model, body, spec, mutationName, h)

	return model
end

return BrainrotBuilder
