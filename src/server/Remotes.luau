--[[
	Remotes: makes the RemoteEvents the server and the players' computers
	use to talk to each other. They go in ReplicatedStorage.Remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENT_NAMES = {
	-- server -> player
	"Notify", -- (text, color) a message at the top of the screen
	"Hatched", -- (petName, eggIndex) play the egg hatch animation
	"PetsChanged", -- (petList, petSlots) your pet inventory changed
	"Reward", -- (amount, position) you broke a blob and got Jelly
	-- player -> server
	"BuyUpgrade", -- (upgradeName)
	"ToggleEquip", -- (petIndex)
	"DeletePet", -- (petIndex)
	"EquipBest", -- ()
	"SetAuto", -- (isOn)
}

local Remotes = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"
for _, name in EVENT_NAMES do
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	Remotes[name] = event
end
folder.Parent = ReplicatedStorage

-- Shortcut for sending a message to one player.
function Remotes.Tell(player: Player, text: string, color: Color3?)
	Remotes.Notify:FireClient(player, text, color or Color3.new(1, 1, 1))
end

return Remotes
