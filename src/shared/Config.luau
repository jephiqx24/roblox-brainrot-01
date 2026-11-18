-- Brainrot Buffet: the single source of truth for game data.
-- Every character, rarity, price, rate and tuning number lives here so the
-- server and the client always agree. Nothing in this module has side effects.

local Config = {}

Config.GAME_NAME = "Brainrot Buffet"
Config.WORLD_NAME = "The Great Picnic"

-- Money the player starts with.
Config.START_MONEY = 100
-- Character slots on one player's base.
Config.BASE_SLOTS = 6
-- How many bases the world builds (a circle around the plaza).
Config.BASE_COUNT = 8

-- Rarities, rarest last. Weight is the spawn weight on the conveyor.
Config.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(170, 170, 170), weight = 40 },
	{ name = "Rare", color = Color3.fromRGB(80, 180, 255), weight = 30 },
	{ name = "Epic", color = Color3.fromRGB(180, 90, 255), weight = 18 },
	{ name = "Legendary", color = Color3.fromRGB(255, 170, 0), weight = 8 },
	{ name = "Mythic", color = Color3.fromRGB(255, 80, 200), weight = 3 },
	{ name = "Secret", color = Color3.fromRGB(255, 60, 60), weight = 1 },
}

-- Mutations: a spawned character may carry one. Chance is a fraction.
Config.MUTATIONS = {
	{ name = "None", chance = 0.94, multiplier = 1, color = nil },
	{ name = "Golden", chance = 0.04, multiplier = 2, color = Color3.fromRGB(255, 210, 60) },
	{ name = "Rainbow", chance = 0.015, multiplier = 5, color = Color3.fromRGB(255, 120, 220) },
	{ name = "Diamond", chance = 0.005, multiplier = 10, color = Color3.fromRGB(180, 240, 255) },
}

-- The cast. id is stable and unique. rate is money per second, cost is the
-- buy price. color is the body colour, shape is the body part shape,
-- accessory is the extra part that makes the character absurd.
-- desc is the joke the label shows.
Config.CHARACTERS = {
	{
		id = "pasta-penguin",
		name = "Pasta Penguin",
		rarity = "Common",
		rate = 5,
		cost = 50,
		color = Color3.fromRGB(245, 235, 200),
		shape = Enum.PartType.Ball,
		accessory = "noodle",
		desc = "A penguin made of spaghetti. It waddles. It slurps.",
	},
	{
		id = "taco-turtle",
		name = "Taco Turtle",
		rarity = "Common",
		rate = 8,
		cost = 100,
		color = Color3.fromRGB(230, 180, 60),
		shape = Enum.PartType.Block,
		accessory = "shell",
		desc = "A turtle in a taco shell. Crunchy, slow, delicious.",
	},
	{
		id = "pizza-pigeon",
		name = "Pizza Pigeon",
		rarity = "Rare",
		rate = 20,
		cost = 300,
		color = Color3.fromRGB(240, 120, 60),
		shape = Enum.PartType.Ball,
		accessory = "pepperoni",
		desc = "A pigeon with a pizza for a body. It coos in Italian.",
	},
	{
		id = "burger-beaver",
		name = "Burger Beaver",
		rarity = "Rare",
		rate = 35,
		cost = 600,
		color = Color3.fromRGB(160, 110, 60),
		shape = Enum.PartType.Block,
		accessory = "bun",
		desc = "A beaver whose dam is made of buns. It gnaws sesame.",
	},
	{
		id = "sushi-shark",
		name = "Sushi Shark",
		rarity = "Epic",
		rate = 80,
		cost = 1500,
		color = Color3.fromRGB(90, 160, 200),
		shape = Enum.PartType.Block,
		accessory = "seaweed",
		desc = "A shark wrapped in seaweed like a sushi roll. Raw power.",
	},
	{
		id = "donut-duck",
		name = "Donut Duck",
		rarity = "Epic",
		rate = 150,
		cost = 3000,
		color = Color3.fromRGB(255, 170, 200),
		shape = Enum.PartType.Ball,
		accessory = "sprinkles",
		desc = "A duck with a donut body. It quacks in sprinkles.",
	},
	{
		id = "ramen-rhino",
		name = "Ramen Rhino",
		rarity = "Legendary",
		rate = 400,
		cost = 8000,
		color = Color3.fromRGB(255, 220, 120),
		shape = Enum.PartType.Block,
		accessory = "noodle-horn",
		desc = "A rhino with noodle horns and broth armor. Slurp or be slurped.",
	},
	{
		id = "croissant-croc",
		name = "Croissant Crocodile",
		rarity = "Legendary",
		rate = 700,
		cost = 15000,
		color = Color3.fromRGB(220, 170, 90),
		shape = Enum.PartType.Block,
		accessory = "flaky-tail",
		desc = "A crocodile shaped like a croissant. Dangerously flaky.",
	},
	{
		id = "boba-bear",
		name = "Boba Bear",
		rarity = "Mythic",
		rate = 1500,
		cost = 40000,
		color = Color3.fromRGB(200, 150, 110),
		shape = Enum.PartType.Ball,
		accessory = "pearls",
		desc = "A bear made of boba pearls, swimming in milk tea.",
	},
	{
		id = "espresso-elephant",
		name = "Espresso Elephant",
		rarity = "Mythic",
		rate = 3000,
		cost = 100000,
		color = Color3.fromRGB(90, 60, 40),
		shape = Enum.PartType.Block,
		accessory = "straw-trunk",
		desc = "An elephant that is a coffee cup. Its trunk is a straw. It never sleeps.",
	},
	{
		id = "gnocchi-gorilla",
		name = "Golden Gnocchi Gorilla",
		rarity = "Secret",
		rate = 10000,
		cost = 500000,
		color = Color3.fromRGB(255, 215, 90),
		shape = Enum.PartType.Ball,
		accessory = "golden-fur",
		desc = "A glowing golden gorilla made of gnocchi. It beats its chest. It beats the market.",
	},
	{
		id = "infinite-ice-cream",
		name = "The Infinite Ice Cream",
		rarity = "Secret",
		rate = 25000,
		cost = 1500000,
		color = Color3.fromRGB(255, 240, 245),
		shape = Enum.PartType.Ball,
		accessory = "cherry",
		desc = "A three-scoop cone that never melts. It has seen the end of summer.",
	},
}

-- Rebirth: total money ever earned needed for rebirth n (1-based).
Config.REBIRTH_COSTS = { 25000, 250000, 2500000, 25000000, 250000000 }
-- Each rebirth doubles all earnings.
Config.REBIRTH_MULTIPLIER = 2

-- Conveyor: a new character every SPAWN_INTERVAL seconds while fewer than
-- MAX_ON_CONVEYOR are walking it. Walk speed in studs per second.
Config.SPAWN_INTERVAL = 6
Config.MAX_ON_CONVEYOR = 8
Config.WALK_SPEED = 4
-- The conveyor runs this long, in studs, from spawn to despawn.
Config.CONVEYOR_LENGTH = 120

-- Base lock: how long a lock lasts, and its cooldown, in seconds.
Config.LOCK_DURATION = 60
Config.LOCK_COOLDOWN = 120
-- Steal: seconds a player must wait between steals.
Config.STEAL_COOLDOWN = 30

-- Hunger Wave: seconds between waves, seconds of warning, seconds the wave
-- takes to cross the map, and the share of money a caught player loses.
Config.WAVE_INTERVAL = 180
Config.WAVE_WARNING = 30
Config.WAVE_SWEEP = 10
Config.WAVE_PENALTY = 0.10

-- Lookups, built once.

local byId = {}
for _, c in ipairs(Config.CHARACTERS) do
	byId[c.id] = c
end

local byRarity = {}
for _, r in ipairs(Config.RARITIES) do
	byRarity[r.name] = r
end

function Config.getCharacter(id)
	return byId[id]
end

function Config.getRarity(name)
	return byRarity[name]
end

-- Total spawn weight of all rarities.
local totalWeight = 0
for _, r in ipairs(Config.RARITIES) do
	totalWeight += r.weight
end

-- Pick a rarity by weight.
function Config.rollRarity()
	local roll = math.random() * totalWeight
	for _, r in ipairs(Config.RARITIES) do
		roll -= r.weight
		if roll <= 0 then
			return r.name
		end
	end
	return Config.RARITIES[1].name
end

-- Pick a random character of a rarity.
function Config.rollCharacter(rarity)
	local pool = {}
	for _, c in ipairs(Config.CHARACTERS) do
		if c.rarity == rarity then
			table.insert(pool, c)
		end
	end
	if #pool == 0 then
		return Config.CHARACTERS[1]
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation by chance.
function Config.rollMutation()
	local roll = math.random()
	local acc = 0
	for _, m in ipairs(Config.MUTATIONS) do
		acc += m.chance
		if roll <= acc then
			return m
		end
	end
	return Config.MUTATIONS[1]
end

-- Money a character earns per second with its mutation and the owner's
-- rebirth multiplier.
function Config.rateFor(char, mutationName, rebirthMultiplier)
	local m = Config.MUTATIONS[1]
	for _, cand in ipairs(Config.MUTATIONS) do
		if cand.name == mutationName then
			m = cand
			break
		end
	end
	return char.rate * m.multiplier * rebirthMultiplier
end

return Config
