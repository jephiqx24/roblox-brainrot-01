-- Brainrot Buffet: shared game constants.
-- Required by server and client through ReplicatedStorage.Shared.

local Config = {}

Config.GameName = "Brainrot Buffet"
Config.GameSubtitle = "The Great Picnic"
Config.StartingMoney = 100

-- Rarity display colors.
Config.RarityColors = {
	Common = Color3.fromRGB(120, 200, 120),
	Rare = Color3.fromRGB(80, 140, 255),
	Epic = Color3.fromRGB(170, 90, 230),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 80, 120),
	Secret = Color3.fromRGB(255, 215, 0),
}

-- The 12 original characters. Rate is base $/s before mutation and rebirth multipliers.
Config.Characters = {
	{ Name = "Pasta Penguin", Rarity = "Common", Cost = 50, Rate = 5 },
	{ Name = "Taco Turtle", Rarity = "Common", Cost = 100, Rate = 8 },
	{ Name = "Pizza Pigeon", Rarity = "Rare", Cost = 300, Rate = 20 },
	{ Name = "Burger Beaver", Rarity = "Rare", Cost = 600, Rate = 35 },
	{ Name = "Sushi Shark", Rarity = "Epic", Cost = 1500, Rate = 80 },
	{ Name = "Donut Duck", Rarity = "Epic", Cost = 3000, Rate = 150 },
	{ Name = "Ramen Rhino", Rarity = "Legendary", Cost = 8000, Rate = 400 },
	{ Name = "Croissant Crocodile", Rarity = "Legendary", Cost = 15000, Rate = 700 },
	{ Name = "Boba Bear", Rarity = "Mythic", Cost = 40000, Rate = 1500 },
	{ Name = "Espresso Elephant", Rarity = "Mythic", Cost = 100000, Rate = 3000 },
	{ Name = "Golden Gnocchi Gorilla", Rarity = "Secret", Cost = 500000, Rate = 10000 },
	{ Name = "The Infinite Ice Cream", Rarity = "Secret", Cost = 1500000, Rate = 25000 },
}

-- Mutations rolled on spawn. Chance values are probabilities (0-1).
-- Rolled in order; the first hit wins, otherwise the character is normal.
Config.Mutations = {
	{ Name = "Golden", Multiplier = 2, Chance = 0.04 },
	{ Name = "Rainbow", Multiplier = 5, Chance = 0.015 },
	{ Name = "Diamond", Multiplier = 10, Chance = 0.005 },
}

-- Rebirth thresholds on total lifetime earnings. Each rebirth doubles income.
Config.RebirthThresholds = { 25000, 250000, 2500000, 25000000, 250000000 }

-- Conveyor.
Config.Conveyor = {
	SpawnInterval = 6, -- seconds between spawns
	MaxAlive = 8, -- max characters walking the conveyor at once
	Speed = 4, -- studs per second
	StartX = -60,
	EndX = 60,
	Z = 0,
	Y = 3,
	Length = 120,
}

-- Bases: 8 platforms in a circle around the center.
Config.Bases = {
	Count = 8,
	Radius = 100,
	Size = 26,
	Slots = 6,
}

-- Steal and base lock.
Config.StealCooldown = 30 -- seconds per player between steals
Config.LockDuration = 60 -- seconds a base lock lasts
Config.LockCooldown = 120 -- seconds before the lock can be used again

-- Hunger Wave.
Config.Wave = {
	Cycle = 180, -- seconds between waves
	Warning = 30, -- seconds of warning before the sweep
	Sweep = 10, -- seconds the sweep lasts
	LossPercent = 0.10, -- money lost when caught outside your base
}

-- Weighted spawn: rarer characters are less likely to appear.
-- Weight per rarity; a character's weight is its rarity weight.
Config.RarityWeights = {
	Common = 30,
	Rare = 22,
	Epic = 14,
	Legendary = 8,
	Mythic = 3,
	Secret = 1,
}

return Config
