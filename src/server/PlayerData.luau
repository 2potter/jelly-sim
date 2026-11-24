--[[
	PlayerData: keeps each player's Jelly, pets, zones and upgrades,
	and saves them with DataStoreService so they are still there next time.

	NOTE: saving only works in Studio if the game is published and
	"Enable Studio Access to API Services" is turned on (see README).
	If it's off, the game still works, it just won't save.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(script.Parent.Remotes)

local PlayerData = {}

-- Change the name to wipe everyone's saves and start fresh.
local STORE_NAME = "JellySimData_v1"

local store: DataStore? = nil
local storeOk, storeError = pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
if not storeOk then
	warn("[JellySim] Saving is OFF (" .. tostring(storeError) .. ")")
end

type PetEntry = { Name: string, Equipped: boolean }
type Data = {
	Jelly: number,
	ZonesUnlocked: number,
	Pets: { PetEntry },
	Upgrades: { [string]: number },
	TotalHatched: number,
}

-- profiles[player] = { Data = ..., CanSave = true/false }
local profiles: { [Player]: { Data: Data, CanSave: boolean } } = {}

local function newData(): Data
	local upgrades = {}
	for name in Config.Upgrades do
		upgrades[name] = 0
	end
	return {
		Jelly = Config.StartingJelly,
		ZonesUnlocked = 1,
		Pets = {},
		Upgrades = upgrades,
		TotalHatched = 0,
	}
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

-- Copy saved values on top of the fresh defaults, so new fields added
-- later still get a default value for old saves.
local function mergeSaved(data: Data, saved: any)
	if type(saved) ~= "table" then
		return
	end
	if type(saved.Jelly) == "number" then
		data.Jelly = saved.Jelly
	end
	if type(saved.ZonesUnlocked) == "number" then
		data.ZonesUnlocked = math.clamp(saved.ZonesUnlocked, 1, #Config.Zones)
	end
	if type(saved.TotalHatched) == "number" then
		data.TotalHatched = saved.TotalHatched
	end
	if type(saved.Pets) == "table" then
		for _, pet in saved.Pets do
			-- skip pets that were removed from Config
			if type(pet) == "table" and Config.Pets[pet.Name] then
				table.insert(data.Pets, { Name = pet.Name, Equipped = pet.Equipped == true })
			end
		end
	end
	if type(saved.Upgrades) == "table" then
		for name, info in Config.Upgrades do
			local level = saved.Upgrades[name]
			if type(level) == "number" then
				data.Upgrades[name] = math.clamp(level, 0, info.MaxLevel)
			end
		end
	end
end

local function makeLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local jelly = Instance.new("IntValue")
	jelly.Name = "Jelly"
	jelly.Parent = leaderstats

	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Parent = leaderstats

	leaderstats.Parent = player
end

-- Loads a player's save. Returns nil if they left while loading.
function PlayerData.Load(player: Player): Data?
	local data = newData()
	local loadedOk = true

	if store then
		local success, result
		for _ = 1, 3 do
			success, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if success then
				break
			end
			task.wait(1)
		end
		if success then
			mergeSaved(data, result)
		else
			-- Don't save over their real data with a blank one!
			loadedOk = false
			warn("[JellySim] Could not load data for " .. player.Name .. ": " .. tostring(result))
			Remotes.Tell(player, "Your save couldn't load, so this game won't be saved. Try rejoining!", Color3.fromRGB(255, 120, 120))
		end
	end

	if not player.Parent then
		return nil
	end

	profiles[player] = { Data = data, CanSave = store ~= nil and loadedOk }
	makeLeaderstats(player)
	PlayerData.Refresh(player)
	return data
end

function PlayerData.Get(player: Player): Data?
	local profile = profiles[player]
	return profile and profile.Data
end

function PlayerData.PetSlots(player: Player): number
	local data = PlayerData.Get(player)
	return Config.BasePetSlots + (data and data.Upgrades.PetSlots or 0)
end

-- Updates leaderstats and attributes so the player's screen shows the latest numbers.
function PlayerData.Refresh(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Jelly.Value = data.Jelly
		leaderstats.Pets.Value = #data.Pets
	end
	player:SetAttribute("ZonesUnlocked", data.ZonesUnlocked)
	player:SetAttribute("PetSlots", PlayerData.PetSlots(player))
	for name, level in data.Upgrades do
		player:SetAttribute("Upgrade_" .. name, level)
	end
end

-- Sends the pet inventory to the player's screen.
function PlayerData.SendPets(player: Player)
	local data = PlayerData.Get(player)
	if data then
		Remotes.PetsChanged:FireClient(player, data.Pets, PlayerData.PetSlots(player))
		PlayerData.Refresh(player)
	end
end

function PlayerData.AddJelly(player: Player, amount: number)
	local data = PlayerData.Get(player)
	if data then
		data.Jelly += math.floor(amount)
		PlayerData.Refresh(player)
	end
end

-- Returns true if the player had enough Jelly (and takes it away).
function PlayerData.SpendJelly(player: Player, amount: number): boolean
	local data = PlayerData.Get(player)
	if not data or data.Jelly < amount then
		return false
	end
	data.Jelly -= amount
	PlayerData.Refresh(player)
	return true
end

function PlayerData.Save(player: Player)
	local profile = profiles[player]
	if not profile or not profile.CanSave or not store then
		return
	end
	for _ = 1, 3 do
		local success, err = pcall(function()
			store:SetAsync(keyFor(player), profile.Data)
		end)
		if success then
			return
		end
		warn("[JellySim] Save failed for " .. player.Name .. ": " .. tostring(err))
		task.wait(1)
	end
end

-- Saves and forgets a player (when they leave).
function PlayerData.Release(player: Player)
	PlayerData.Save(player)
	profiles[player] = nil
end

-- Saves everyone at once (used when the server shuts down).
function PlayerData.SaveAll()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function()
			PlayerData.Save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end

return PlayerData
