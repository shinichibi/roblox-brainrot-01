-- BrainrotCatalog.luau
-- The single source of truth for Brainrot Bay: every brainrot character, egg and mutation.
-- Pure data plus the two dice rolls (egg hatching and mutation rolling). No Instances here,
-- so the client can require it for the shop and index panels and the server for the economy.

local BrainrotCatalog = {}

-- Rarity ladder, weakest to strongest. The index panel and the egg odds speak in these names.
BrainrotCatalog.Rarities = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- One entry per brainrot. `body` describes how BrainrotBuilder composes the character out of
-- primitive parts: a shape, a size in studs, a paint colour and an optional belly colour.
-- `accessory` names the extra prop the builder bolts on. `income` is dollars per second on a
-- base pad before mutation and rebirth multipliers; `value` is its catalogue price, used for
-- selling (half back) and for showing off in the index.
BrainrotCatalog.Characters = {
	{
		id = "sir-wobbles",
		name = "Sir Wobbles",
		rarity = "Common",
		income = 1,
		value = 60,
		desc = "A jelly blob knighted for wobbling bravely at a garden party.",
		body = { shape = "Ball", size = { 3, 3, 3 }, color = { 140, 230, 170 }, belly = { 210, 250, 225 } },
		accessory = "crown",
	},
	{
		id = "capn-crumb",
		name = "Cap'n Crumb",
		rarity = "Common",
		income = 2,
		value = 110,
		desc = "A pirate cookie who sails the milk seas and fears the dunk.",
		body = { shape = "Cylinder", axis = "front", size = { 3.2, 1.4, 3.2 }, color = { 196, 144, 84 }, belly = { 226, 182, 120 } },
		accessory = "eyepatch",
	},
	{
		id = "noodle-knight",
		name = "Noodle Knight",
		rarity = "Common",
		income = 3,
		value = 170,
		desc = "Sworn to protect the pantry. His fork has never lost a duel.",
		body = { shape = "Block", size = { 1.8, 4.2, 1.8 }, color = { 245, 222, 150 }, belly = { 250, 238, 190 } },
		accessory = "fork",
	},
	{
		id = "dj-pickle",
		name = "DJ Pickle",
		rarity = "Common",
		income = 4,
		value = 240,
		desc = "Drops the beet every Friday. Brined, not stirred.",
		body = { shape = "Cylinder", size = { 2, 3.6, 2 }, color = { 92, 178, 84 }, belly = { 150, 214, 140 } },
		accessory = "headphones",
	},
	{
		id = "turbo-toaster",
		name = "Turbo Toaster",
		rarity = "Rare",
		income = 9,
		value = 520,
		desc = "Toasts at 400 km/h. Breakfast is served before you wake up.",
		body = { shape = "Block", size = { 3.4, 2.6, 2.4 }, color = { 198, 202, 210 }, belly = { 160, 164, 175 } },
		accessory = "toast",
	},
	{
		id = "baron-banana",
		name = "Baron von Banana",
		rarity = "Rare",
		income = 12,
		value = 700,
		desc = "Old money. Old fruit. Impeccable peel, impeccable manners.",
		body = { shape = "Ball", size = { 2.6, 3.8, 2.6 }, color = { 250, 216, 74 }, belly = { 252, 236, 150 } },
		accessory = "tophat",
	},
	{
		id = "prof-pancake",
		name = "Professor Pancake",
		rarity = "Rare",
		income = 15,
		value = 880,
		desc = "Holds a PhD in syrup studies. Publishes only in butter.",
		body = { shape = "Cylinder", size = { 3.6, 1.8, 3.6 }, color = { 222, 170, 100 }, belly = { 240, 205, 145 } },
		accessory = "glasses",
	},
	{
		id = "bubble-duck",
		name = "Bubble Duck",
		rarity = "Rare",
		income = 18,
		value = 1050,
		desc = "A bath-time celebrity. Every bubble is a tiny autograph.",
		body = { shape = "Ball", size = { 3, 2.8, 3 }, color = { 250, 224, 92 }, belly = { 252, 240, 170 } },
		accessory = "beak",
	},
	{
		id = "sir-bounces",
		name = "Sir Bounces-a-Lot",
		rarity = "Epic",
		income = 40,
		value = 2400,
		desc = "A teapot on springs. Pours tea exclusively mid-bounce.",
		body = { shape = "Ball", size = { 3, 2.6, 3 }, color = { 96, 196, 205 }, belly = { 180, 236, 240 } },
		accessory = "cap",
	},
	{
		id = "count-quackula",
		name = "Count Quackula",
		rarity = "Epic",
		income = 55,
		value = 3300,
		desc = "He vants to quack your blood. Settles for breadcrumbs.",
		body = { shape = "Ball", size = { 3, 3, 3 }, color = { 236, 232, 245 }, belly = { 120, 90, 170 } },
		accessory = "cape",
	},
	{
		id = "major-moonpie",
		name = "Major Moonpie",
		rarity = "Epic",
		income = 75,
		value = 4500,
		desc = "First pastry on the moon. The flag is also a napkin.",
		body = { shape = "Ball", size = { 3.2, 3.2, 3.2 }, color = { 240, 226, 200 }, belly = { 200, 160, 120 } },
		accessory = "dome",
	},
	{
		id = "gilded-gnome",
		name = "The Gilded Gnome",
		rarity = "Legendary",
		income = 160,
		value = 9800,
		desc = "Solid gold, solid opinions. Guards lawns and portfolios.",
		body = { shape = "Block", size = { 2.2, 3, 2.2 }, color = { 245, 190, 60 }, belly = { 250, 215, 120 } },
		accessory = "conehat",
	},
	{
		id = "mecha-milkshake",
		name = "Mecha Milkshake",
		rarity = "Legendary",
		income = 220,
		value = 13500,
		desc = "A robot milkshake with a 40-year warranty and sprinkles.",
		body = { shape = "Cylinder", size = { 2.6, 3.8, 2.6 }, color = { 248, 178, 205 }, belly = { 252, 225, 236 } },
		accessory = "straw",
	},
	{
		id = "emperor-eggplant",
		name = "Emperor Eggplant III",
		rarity = "Mythic",
		income = 500,
		value = 30000,
		desc = "Third of his line. Rules the vegetable drawer with an iron leaf.",
		body = { shape = "Ball", size = { 3, 4, 3 }, color = { 128, 84, 190 }, belly = { 178, 140, 225 } },
		accessory = "crown",
	},
	{
		id = "cosmic-burrito",
		name = "Cosmic Burrito",
		rarity = "Mythic",
		income = 750,
		value = 45000,
		desc = "Wrapped in a tortilla of stars. Salsa sold separately by fate.",
		body = { shape = "Cylinder", size = { 2.4, 4.2, 2.4 }, color = { 232, 198, 148 }, belly = { 244, 222, 180 } },
		accessory = "star",
	},
	{
		id = "forbidden-meatball",
		name = "The Forbidden Meatball",
		rarity = "Secret",
		income = 2000,
		value = 120000,
		desc = "No menu lists it. No chef admits making it. It knows things.",
		body = { shape = "Ball", size = { 3.6, 3.6, 3.6 }, color = { 128, 80, 58 }, belly = { 160, 108, 80 } },
		accessory = "shades",
	},
}

-- Lookup by id, filled in below.
BrainrotCatalog.ById = {}
for _, character in ipairs(BrainrotCatalog.Characters) do
	BrainrotCatalog.ById[character.id] = character
end

-- Mutations rolled on every acquisition (egg hatch or wild catch). A mutation multiplies the
-- brainrot's income and its sell value, and repaints it (see BrainrotBuilder).
BrainrotCatalog.Mutations = {
	{ name = "Normal", mult = 1, chance = 70 },
	{ name = "Golden", mult = 2.5, chance = 20 },
	{ name = "Diamond", mult = 5, chance = 8 },
	{ name = "Rainbow", mult = 12, chance = 2 },
}

BrainrotCatalog.MutationByName = {}
for _, mutation in ipairs(BrainrotCatalog.Mutations) do
	BrainrotCatalog.MutationByName[mutation.name] = mutation
end

-- The three eggs on sale at the shop. `odds` is the percent chance of each rarity inside.
BrainrotCatalog.Eggs = {
	{
		id = "cracked",
		name = "Cracked Egg",
		price = 150,
		color = { 235, 228, 210 },
		speckle = { 170, 150, 120 },
		odds = { Common = 68, Rare = 26, Epic = 6 },
	},
	{
		id = "golden",
		name = "Golden Egg",
		price = 2500,
		color = { 250, 200, 60 },
		speckle = { 255, 240, 170 },
		odds = { Rare = 52, Epic = 33, Legendary = 13, Mythic = 2 },
	},
	{
		id = "void",
		name = "Void Egg",
		price = 40000,
		color = { 60, 50, 95 },
		speckle = { 190, 140, 255 },
		odds = { Epic = 42, Legendary = 36, Mythic = 18, Secret = 4 },
	},
}

BrainrotCatalog.EggById = {}
for _, egg in ipairs(BrainrotCatalog.Eggs) do
	BrainrotCatalog.EggById[egg.id] = egg
end

-- Pick a random character of one rarity (nil when the rarity has no characters).
local function randomCharacterOfRarity(rarity)
	local pool = {}
	for _, character in ipairs(BrainrotCatalog.Characters) do
		if character.rarity == rarity then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

-- Roll an egg: first its rarity by the egg's odds, then a random character of that rarity.
function BrainrotCatalog.rollEgg(egg)
	local roll = math.random(1, 100)
	local cumulative = 0
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		local chance = egg.odds[rarity]
		if chance then
			cumulative += chance
			if roll <= cumulative then
				return randomCharacterOfRarity(rarity)
			end
		end
	end
	-- Odds that do not add to 100 land here: fall back to the egg's weakest rarity.
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		if egg.odds[rarity] then
			return randomCharacterOfRarity(rarity)
		end
	end
	return nil
end

-- Roll a mutation by the table's chances.
function BrainrotCatalog.rollMutation()
	local roll = math.random(1, 100)
	local cumulative = 0
	for _, mutation in ipairs(BrainrotCatalog.Mutations) do
		cumulative += mutation.chance
		if roll <= cumulative then
			return mutation
		end
	end
	return BrainrotCatalog.Mutations[1]
end

-- The rarity a wild spawn on the lane rolls: mostly Commons, a few Rares, a whisper of Epic.
function BrainrotCatalog.rollWildCharacter()
	local roll = math.random(1, 100)
	if roll <= 3 then
		return randomCharacterOfRarity("Epic")
	elseif roll <= 25 then
		return randomCharacterOfRarity("Rare")
	end
	return randomCharacterOfRarity("Common")
end

return BrainrotCatalog
