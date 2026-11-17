-- Money.luau
-- Small shared helpers: pretty cash formatting and the rarity / mutation colours every
-- label in the game (world billboards and the client panels) paints with.

local Money = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

-- 950 -> "$950", 12500 -> "$12.5K", 3400000 -> "$3.4M". Whole dollars only; the game
-- never deals in cents.
function Money.format(amount)
	amount = math.floor(amount)
	local sign = ""
	if amount < 0 then
		sign = "-"
		amount = -amount
	end
	local tier = 1
	local value = amount
	while value >= 1000 and tier < #SUFFIXES do
		value = value / 1000
		tier += 1
	end
	if tier == 1 then
		return sign .. "$" .. tostring(value)
	end
	local text
	if value >= 100 then
		text = string.format("%.0f", value)
	elseif value >= 10 then
		text = string.format("%.1f", value)
	else
		text = string.format("%.2f", value)
	end
	text = string.gsub(text, "%.?0+$", "")
	return sign .. "$" .. text .. SUFFIXES[tier]
end

-- The colour each rarity is labelled with, from pavement grey to secret crimson.
Money.RarityColors = {
	Common = Color3.fromRGB(205, 208, 215),
	Rare = Color3.fromRGB(84, 150, 255),
	Epic = Color3.fromRGB(178, 102, 255),
	Legendary = Color3.fromRGB(255, 164, 40),
	Mythic = Color3.fromRGB(255, 92, 178),
	Secret = Color3.fromRGB(255, 70, 70),
}

-- Mutation label colours (Normal keeps the rarity colour, handled by callers).
Money.MutationColors = {
	Golden = Color3.fromRGB(255, 205, 50),
	Diamond = Color3.fromRGB(140, 235, 255),
	Rainbow = Color3.fromRGB(255, 120, 220),
}

return Money
