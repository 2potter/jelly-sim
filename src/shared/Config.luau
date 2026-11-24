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
Config.StarterPet = "Strawberry Jiggle" -- everyone gets one free pet to start
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
-- Pets: every pet is a wobbly jelly pudding with a cute face.
--   Power   = how much damage it does to jelly blobs each hit.
--   Color   = the jelly color. Colors = a list of colors for striped jelly.
--   Cream   = the whipped cream color on top.
--   Topping = "Cherry", "Berry", "Lemon", "Bean", "Star" or "Crown".
--   Stars   = true puts little glittery stars inside the jelly.
--   The game adds glow (Epic+), sparkles (Legendary+) and a halo (Mythical) by itself.
---------------------------------------------------------------------
local C = Color3.fromRGB

Config.Pets = {
	-- Common
	["Strawberry Jiggle"] = { Rarity = "Common", Power = 1, Color = C(255, 150, 190), Cream = C(255, 250, 245), Topping = "Cherry" },
	["Lemon Wobble"] = { Rarity = "Common", Power = 1.5, Color = C(255, 230, 110), Cream = C(255, 250, 235), Topping = "Lemon" },
	["Milk Pudding"] = { Rarity = "Common", Power = 2, Color = C(255, 236, 200), Cream = C(190, 120, 60), Topping = "Cherry" },
	-- Uncommon
	["Blueberry Bloop"] = { Rarity = "Uncommon", Power = 3.5, Color = C(110, 190, 255), Cream = C(190, 255, 210), Topping = "Cherry", Stars = true },
	["Matcha Mochi"] = { Rarity = "Uncommon", Power = 4.5, Color = C(160, 220, 120), Cream = C(255, 255, 245), Topping = "Bean" },
	-- Rare
	["Peach Puff"] = { Rarity = "Rare", Power = 9, Color = C(255, 175, 140), Cream = C(255, 240, 250), Topping = "Berry" },
	["Grape Galaxy"] = { Rarity = "Rare", Power = 12, Color = C(160, 100, 255), Cream = C(230, 210, 255), Topping = "Berry", Stars = true },
	-- Epic
	["Cotton Candy Swirl"] = { Rarity = "Epic", Power = 28, Color = C(255, 170, 220), Colors = { C(255, 170, 220), C(150, 210, 255) }, Cream = C(255, 255, 255), Topping = "Star" },
	["Mint Choco Jiggle"] = { Rarity = "Epic", Power = 38, Color = C(120, 240, 200), Cream = C(110, 70, 45), Topping = "Cherry", Stars = true },
	-- Legendary
	["Golden Honey Royale"] = { Rarity = "Legendary", Power = 95, Color = C(255, 200, 60), Cream = C(255, 250, 230), Topping = "Crown", Stars = true },
	-- Mythical
	["Rainbow Dream"] = {
		Rarity = "Mythical",
		Power = 250,
		Color = C(255, 140, 200),
		Colors = { C(255, 120, 140), C(255, 190, 100), C(255, 240, 120), C(140, 240, 140), C(120, 190, 255), C(190, 140, 255) },
		Cream = C(255, 255, 255),
		Topping = "Star",
		Stars = true,
	},
	["Starlight Jelly"] = { Rarity = "Mythical", Power = 320, Color = C(70, 60, 170), Cream = C(200, 220, 255), Topping = "Star", Stars = true },
}

-- Pets from older versions of the game get turned into the new ones
-- so nobody loses their pets.
Config.RenamedPets = {
	["Jellybean Pup"] = "Strawberry Jiggle",
	["Wobble Cat"] = "Lemon Wobble",
	["Gummy Bunny"] = "Blueberry Bloop",
	["Squishy Snail"] = "Matcha Mochi",
	["Slime Fox"] = "Peach Puff",
	["Berry Bat"] = "Grape Galaxy",
	["Sparkle Squish"] = "Cotton Candy Swirl",
	["Lime Dragonling"] = "Mint Choco Jiggle",
	["Royal Blobfish"] = "Golden Honey Royale",
	["Cosmic Goo"] = "Starlight Jelly",
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
		FloorColor = C(150, 225, 140),
		PathColor = C(255, 230, 240),
		Decor = { C(255, 150, 200), C(255, 220, 120), C(170, 230, 255) },
		Blobs = {
			{ Name = "Jelly Cube", Style = "Drop", Health = 5, Reward = 2, Size = 2.6, Color = C(255, 120, 190), Chance = 80 },
			{ Name = "Big Jelly Cube", Style = "Pudding", Health = 25, Reward = 12, Size = 4, Color = C(255, 90, 170), Chance = 18 },
			{ Name = "Giant Jelly Cube", Style = "Giant", Health = 150, Reward = 90, Size = 7, Color = C(240, 60, 150), Chance = 2 },
		},
	},
	{
		Name = "Berry Bay",
		Price = 400,
		FloorColor = C(250, 230, 180),
		PathColor = C(200, 235, 255),
		Decor = { C(140, 110, 255), C(90, 200, 255), C(255, 160, 220) },
		Blobs = {
			{ Name = "Berry Cube", Style = "Drop", Health = 30, Reward = 15, Size = 2.6, Color = C(140, 100, 255), Chance = 80 },
			{ Name = "Big Berry Cube", Style = "Pudding", Health = 150, Reward = 80, Size = 4, Color = C(110, 80, 240), Chance = 18 },
			{ Name = "Giant Berry Cube", Style = "Giant", Health = 900, Reward = 550, Size = 7, Color = C(80, 60, 220), Chance = 2 },
		},
	},
	{
		Name = "Lava Lime Peaks",
		Price = 6000,
		FloorColor = C(110, 80, 90),
		PathColor = C(255, 170, 90),
		Decor = { C(170, 255, 80), C(255, 120, 60), C(255, 220, 90) },
		Blobs = {
			{ Name = "Lime Cube", Style = "Drop", Health = 200, Reward = 100, Size = 2.6, Color = C(170, 255, 70), Chance = 80 },
			{ Name = "Big Lime Cube", Style = "Pudding", Health = 1000, Reward = 550, Size = 4, Color = C(120, 235, 40), Chance = 18 },
			{ Name = "Giant Lime Cube", Style = "Giant", Health = 6000, Reward = 4000, Size = 7, Color = C(80, 210, 20), Chance = 2 },
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
		Name = "Pudding Egg",
		Price = 50,
		Zone = 1,
		Color = C(255, 190, 220),
		SpotColor = C(255, 255, 255),
		Pets = {
			{ "Strawberry Jiggle", 45 },
			{ "Lemon Wobble", 32 },
			{ "Milk Pudding", 15 },
			{ "Blueberry Bloop", 6 },
			{ "Matcha Mochi", 1.9 },
			{ "Peach Puff", 0.1 },
		},
	},
	{
		Name = "Berry Egg",
		Price = 600,
		Zone = 2,
		Color = C(150, 120, 255),
		SpotColor = C(255, 200, 240),
		Pets = {
			{ "Blueberry Bloop", 42 },
			{ "Matcha Mochi", 30 },
			{ "Peach Puff", 17 },
			{ "Grape Galaxy", 9 },
			{ "Cotton Candy Swirl", 1.95 },
			{ "Golden Honey Royale", 0.05 },
		},
	},
	{
		Name = "Lava Lime Egg",
		Price = 9000,
		Zone = 3,
		Color = C(170, 255, 90),
		SpotColor = C(255, 140, 60),
		Pets = {
			{ "Grape Galaxy", 48 },
			{ "Cotton Candy Swirl", 30 },
			{ "Mint Choco Jiggle", 18.9 },
			{ "Golden Honey Royale", 3 },
			{ "Rainbow Dream", 0.08 },
			{ "Starlight Jelly", 0.02 },
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
