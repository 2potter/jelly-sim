--[[
	Main: starts the game on the server.
	It builds the world, spawns jelly blobs, and hooks up eggs, gates,
	upgrades and saving.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(script.Parent.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Blobs = require(script.Parent.Blobs)
local Pets = require(script.Parent.Pets)

local GOOD = Color3.fromRGB(140, 255, 140)
local BAD = Color3.fromRGB(255, 160, 120)

---------------------------------------------------------------------
-- Build the world
---------------------------------------------------------------------
local world = WorldBuilder.Build()

Blobs.Start(function(player, blob)
	Pets.SetTarget(player, blob)
end)
Pets.Start()

---------------------------------------------------------------------
-- Eggs
---------------------------------------------------------------------
for eggIndex, prompt in world.EggPrompts do
	prompt.Triggered:Connect(function(player)
		Pets.Hatch(player, eggIndex)
	end)
end

---------------------------------------------------------------------
-- Zone gates
---------------------------------------------------------------------
for zoneIndex, prompt in world.GatePrompts do
	prompt.Triggered:Connect(function(player)
		local data = PlayerData.Get(player)
		if not data or data.ZonesUnlocked >= zoneIndex then
			return
		end
		local zone = Config.Zones[zoneIndex]
		if data.ZonesUnlocked < zoneIndex - 1 then
			Remotes.Tell(player, "Unlock " .. Config.Zones[zoneIndex - 1].Name .. " first!", BAD)
		elseif PlayerData.SpendJelly(player, zone.Price) then
			data.ZonesUnlocked = zoneIndex
			PlayerData.Refresh(player) -- the player's screen opens the gate
			Remotes.Tell(player, "🎉 You unlocked " .. zone.Name .. "!", GOOD)
		else
			Remotes.Tell(player, "You need " .. Format.Short(zone.Price) .. " Jelly to open " .. zone.Name .. "!", BAD)
		end
	end)
end

---------------------------------------------------------------------
-- Upgrades
---------------------------------------------------------------------
local function applyWalkSpeed(player: Player)
	local data = PlayerData.Get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		humanoid.WalkSpeed = Config.BaseWalkSpeed + 3 * data.Upgrades.WalkSpeed
	end
end

Remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeName)
	local data = PlayerData.Get(player)
	local info = Config.Upgrades[upgradeName]
	if not data or not info then
		return
	end
	local level = data.Upgrades[upgradeName]
	if level >= info.MaxLevel then
		Remotes.Tell(player, info.Title .. " is already maxed out!", BAD)
		return
	end
	local cost = Config.UpgradeCost(upgradeName, level)
	if not PlayerData.SpendJelly(player, cost) then
		Remotes.Tell(player, "You need " .. Format.Short(cost) .. " Jelly for that upgrade!", BAD)
		return
	end
	data.Upgrades[upgradeName] = level + 1
	PlayerData.Refresh(player)
	Remotes.Tell(player, "⬆️ " .. info.Title .. " is now level " .. (level + 1) .. "!", GOOD)

	if upgradeName == "WalkSpeed" then
		applyWalkSpeed(player)
	elseif upgradeName == "PetSlots" then
		PlayerData.SendPets(player)
	elseif upgradeName == "PetPower" then
		Pets.Refresh(player)
	end
end)

---------------------------------------------------------------------
-- Pet buttons from the player's screen
---------------------------------------------------------------------
Remotes.ToggleEquip.OnServerEvent:Connect(Pets.ToggleEquip)
Remotes.DeletePet.OnServerEvent:Connect(Pets.Delete)
Remotes.EquipBest.OnServerEvent:Connect(Pets.EquipBest)
Remotes.SetAuto.OnServerEvent:Connect(Pets.SetAuto)

---------------------------------------------------------------------
-- Players joining and leaving
---------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	local data = PlayerData.Load(player)
	if not data then
		return -- they left while loading
	end

	player.CharacterAdded:Connect(function()
		applyWalkSpeed(player)
		Pets.Refresh(player)
	end)
	if player.Character then
		applyWalkSpeed(player)
	end

	-- brand new players get a free starter pet
	if #data.Pets == 0 and data.TotalHatched == 0 then
		table.insert(data.Pets, { Name = Config.StarterPet, Equipped = true })
		Remotes.Tell(player, "Welcome to Jelly Simulator! Click a jelly blob to send your pet at it!", GOOD)
	end

	Pets.Refresh(player)
	PlayerData.SendPets(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	Pets.Clear(player)
	PlayerData.Release(player)
end)

-- Save every couple of minutes, just in case
task.spawn(function()
	while true do
		task.wait(Config.AutosaveSeconds)
		for _, player in Players:GetPlayers() do
			task.spawn(PlayerData.Save, player)
		end
	end
end)

-- Save everyone when the server shuts down
game:BindToClose(function()
	PlayerData.SaveAll()
end)
