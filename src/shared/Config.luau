--[[
	Config: all the numbers and names for Jelly Simulator live here.

	Want to change the game? Start in this file!
	  - Make jelly blobs worth more: change Reward in a zone's Blobs list.
	  - Add a new pet: copy a line in Config.Pets and change its name, color and power.
	  - Add a new zone: copy a zone in Config.Zones (the world is built from this list).
]]

local Config = {}

---------------------------------------------------------------------
-- Player basics
---------------------------------------------------------------------
Config.StartingJelly = 0
Config.BaseWalkSpeed = 16
Config.BasePetSlots = 3 -- how many pets can follow you at the start
Config.MaxPetsInInventory = 60
Config.StarterPet = "Jellybean Pup" -- everyone gets one free pet to start
Config.AutosaveSeconds = 120

---------------------------------------------------------------------
-- Rarities: the order here is the order from worst to best
---------------------------------------------------------------------
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

Config.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(110, 230, 110),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythical = Color3.fromRGB(255, 70, 120),
}

---------------------------------------------------------------------
-- Pets: every pet is a little jelly creature.
--   Power = how much damage it does to jelly blobs each hit.
--   Look  = "Round", "Ears", "Horn" or "Crown" (adds a little extra shape).
---------------------------------------------------------------------
Config.Pets = {
	["Jellybean Pup"] = { Rarity = "Common", Power = 1, Color = Color3.fromRGB(255, 150, 190), Look = "Ears" },
	["Wobble Cat"] = { Rarity = "Common", Power = 1.5, Color = Color3.fromRGB(255, 200, 120), Look = "Ears" },
	["Gummy Bunny"] = { Rarity = "Uncommon", Power = 3, Color = Color3.fromRGB(140, 230, 255), Look = "Ears" },
	["Squishy Snail"] = { Rarity = "Uncommon", Power = 4, Color = Color3.fromRGB(180, 255, 140), Look = "Round" },
	["Slime Fox"] = { Rarity = "Rare", Power = 8, Color = Color3.fromRGB(255, 120, 60), Look = "Ears" },
	["Berry Bat"] = { Rarity = "Rare", Power = 10, Color = Color3.fromRGB(150, 80, 220), Look = "Ears" },
	["Sparkle Squish"] = { Rarity = "Epic", Power = 25, Color = Color3.fromRGB(255, 120, 255), Look = "Horn" },
	["Lime Dragonling"] = { Rarity = "Epic", Power = 35, Color = Color3.fromRGB(150, 255, 60), Look = "Horn" },
	["Royal Blobfish"] = { Rarity = "Legendary", Power = 90, Color = Color3.fromRGB(255, 215, 80), Look = "Crown" },
	["Cosmic Goo"] = { Rarity = "Mythical", Power = 300, Color = Color3.fromRGB(60, 40, 120), Look = "Crown" },
}

---------------------------------------------------------------------
-- Zones: built in a straight line, one after another.
--   Price = Jelly needed to open the gate into this zone.
--   Blobs = the jelly blobs that spawn here (Chance is out of 100).
---------------------------------------------------------------------
Config.ZoneSize = 120

Config.Zones = {
	{
		Name = "Gummy Meadow",
		Price = 0,
		FloorColor = Color3.fromRGB(130, 215, 130),
		Blobs = {
			{ Name = "Jelly Drop", Health = 5, Reward = 2, Size = 2.5, Color = Color3.fromRGB(255, 120, 190), Chance = 80 },
			{ Name = "Jelly Pile", Health = 25, Reward = 12, Size = 4, Color = Color3.fromRGB(255, 80, 160), Chance = 18 },
			{ Name = "Giant Jelly", Health = 150, Reward = 90, Size = 7, Color = Color3.fromRGB(230, 40, 140), Chance = 2 },
		},
	},
	{
		Name = "Berry Bay",
		Price = 400,
		FloorColor = Color3.fromRGB(240, 220, 160),
		Blobs = {
			{ Name = "Berry Drop", Health = 30, Reward = 15, Size = 2.5, Color = Color3.fromRGB(130, 90, 255), Chance = 80 },
			{ Name = "Berry Pile", Health = 150, Reward = 80, Size = 4, Color = Color3.fromRGB(100, 60, 230), Chance = 18 },
			{ Name = "Giant Berry Jelly", Health = 900, Reward = 550, Size = 7, Color = Color3.fromRGB(70, 30, 200), Chance = 2 },
		},
	},
	{
		Name = "Lava Lime Peaks",
		Price = 6000,
		FloorColor = Color3.fromRGB(95, 65, 70),
		Blobs = {
			{ Name = "Lime Drop", Health = 200, Reward = 100, Size = 2.5, Color = Color3.fromRGB(170, 255, 60), Chance = 80 },
			{ Name = "Lime Pile", Health = 1000, Reward = 550, Size = 4, Color = Color3.fromRGB(120, 230, 30), Chance = 18 },
			{ Name = "Giant Lime Jelly", Health = 6000, Reward = 4000, Size = 7, Color = Color3.fromRGB(80, 200, 0), Chance = 2 },
		},
	},
}

Config.BlobsPerZone = 30
Config.BlobRespawnSeconds = 0.4

---------------------------------------------------------------------
-- Eggs: each egg sits in a zone and has its own pet chances (out of 100).
---------------------------------------------------------------------
Config.Eggs = {
	{
		Name = "Wobbly Egg",
		Price = 50,
		Zone = 1,
		Color = Color3.fromRGB(255, 180, 220),
		Pets = {
			{ "Jellybean Pup", 50 },
			{ "Wobble Cat", 35 },
			{ "Gummy Bunny", 10 },
			{ "Squishy Snail", 4 },
			{ "Slime Fox", 1 },
		},
	},
	{
		Name = "Berry Egg",
		Price = 600,
		Zone = 2,
		Color = Color3.fromRGB(150, 110, 255),
		Pets = {
			{ "Gummy Bunny", 45 },
			{ "Squishy Snail", 30 },
			{ "Slime Fox", 15 },
			{ "Berry Bat", 8 },
			{ "Sparkle Squish", 2 },
		},
	},
	{
		Name = "Lava Lime Egg",
		Price = 9000,
		Zone = 3,
		Color = Color3.fromRGB(170, 255, 80),
		Pets = {
			{ "Berry Bat", 50 },
			{ "Sparkle Squish", 30 },
			{ "Lime Dragonling", 17 },
			{ "Royal Blobfish", 2.9 },
			{ "Cosmic Goo", 0.1 },
		},
	},
}

---------------------------------------------------------------------
-- Upgrades: buy them in the Upgrades menu. Cost = BaseCost * CostGrowth ^ level.
---------------------------------------------------------------------
Config.UpgradeOrder = { "PetPower", "JellyBonus", "PetSlots", "WalkSpeed" }

Config.Upgrades = {
	PetPower = { Title = "Stronger Pets", Info = "+25% pet damage per level", BaseCost = 75, CostGrowth = 2.4, MaxLevel = 10 },
	JellyBonus = { Title = "Jelly Bonus", Info = "+20% Jelly from blobs per level", BaseCost = 100, CostGrowth = 2.5, MaxLevel = 10 },
	PetSlots = { Title = "More Pets", Info = "+1 pet can follow you", BaseCost = 300, CostGrowth = 5, MaxLevel = 3 },
	WalkSpeed = { Title = "Speedy Shoes", Info = "+3 walk speed per level", BaseCost = 150, CostGrowth = 3, MaxLevel = 5 },
}

---------------------------------------------------------------------
-- Pet behaviour
---------------------------------------------------------------------
Config.PetHitSeconds = 0.5 -- how often each pet hits its blob
Config.AutoTargetRange = 45 -- how far "Auto" looks for blobs
Config.ClickRange = 120 -- how far away you can send pets

---------------------------------------------------------------------
-- Helper functions (used by both server and client)
---------------------------------------------------------------------
function Config.ZoneCenter(zoneIndex: number): Vector3
	return Vector3.new(0, 0, -(zoneIndex - 1) * Config.ZoneSize)
end

function Config.UpgradeCost(upgradeName: string, currentLevel: number): number
	local info = Config.Upgrades[upgradeName]
	return math.floor(info.BaseCost * info.CostGrowth ^ currentLevel)
end

function Config.RarityRank(rarity: string): number
	return table.find(Config.RarityOrder, rarity) or 0
end

return Config
