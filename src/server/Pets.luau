--[[
	Pets: hatching eggs, equipping pets, and making them follow you
	and swarm jelly blobs.

	Each equipped pet hits its blob every Config.PetHitSeconds for
	(pet Power x Stronger Pets upgrade) damage.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local PetModels = require(ReplicatedStorage.Shared.PetModels)
local Blobs = require(script.Parent.Blobs)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local Pets = {}

type FollowingPet = { Model: Model, Power: number }
type State = {
	Following: { FollowingPet },
	Target: BasePart?,
	Auto: boolean,
	HitTimer: number,
	LastHatch: number,
}

local states: { [Player]: State } = {}
local random = Random.new()

local petsFolder = Instance.new("Folder")
petsFolder.Name = "FollowingPets"
petsFolder.Parent = workspace

local function getState(player: Player): State
	local state = states[player]
	if not state then
		state = { Following = {}, Target = nil, Auto = false, HitTimer = 0, LastHatch = 0 }
		states[player] = state
	end
	return state
end

local function countEquipped(pets): number
	local count = 0
	for _, pet in pets do
		if pet.Equipped then
			count += 1
		end
	end
	return count
end

local function rollPet(egg): string
	local total = 0
	for _, entry in egg.Pets do
		total += entry[2]
	end
	local roll = random:NextNumber(0, total)
	for _, entry in egg.Pets do
		roll -= entry[2]
		if roll <= 0 then
			return entry[1]
		end
	end
	return egg.Pets[1][1]
end

-- Rebuilds the pet models that follow the player (call after equip changes).
function Pets.Refresh(player: Player)
	local data = PlayerData.Get(player)
	local state = getState(player)

	for _, following in state.Following do
		following.Model:Destroy()
	end
	table.clear(state.Following)
	if not data then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local startCFrame = if root then (root :: BasePart).CFrame else CFrame.new(Config.ZoneCenter(1))

	local powerMultiplier = 1 + 0.25 * data.Upgrades.PetPower
	for _, pet in data.Pets do
		if pet.Equipped then
			local model = PetModels.Build(pet.Name)
			model:PivotTo(startCFrame)
			model.Parent = petsFolder
			table.insert(state.Following, {
				Model = model,
				Power = Config.Pets[pet.Name].Power * powerMultiplier,
			})
		end
	end
end

-- Equips the strongest pets that fit in your pet slots.
function Pets.EquipBest(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local order = {}
	for index, pet in data.Pets do
		pet.Equipped = false
		table.insert(order, index)
	end
	table.sort(order, function(a, b)
		return Config.Pets[data.Pets[a].Name].Power > Config.Pets[data.Pets[b].Name].Power
	end)
	for i = 1, math.min(PlayerData.PetSlots(player), #order) do
		data.Pets[order[i]].Equipped = true
	end
	PlayerData.SendPets(player)
	Pets.Refresh(player)
end

function Pets.ToggleEquip(player: Player, index: any)
	local data = PlayerData.Get(player)
	if not data or type(index) ~= "number" then
		return
	end
	local pet = data.Pets[index]
	if not pet then
		return
	end
	if not pet.Equipped and countEquipped(data.Pets) >= PlayerData.PetSlots(player) then
		Remotes.Tell(player, "All your pet slots are full! Unequip a pet first.", Color3.fromRGB(255, 160, 120))
		return
	end
	pet.Equipped = not pet.Equipped
	PlayerData.SendPets(player)
	Pets.Refresh(player)
end

function Pets.Delete(player: Player, index: any)
	local data = PlayerData.Get(player)
	if not data or type(index) ~= "number" or not data.Pets[index] then
		return
	end
	if #data.Pets <= 1 then
		Remotes.Tell(player, "You can't delete your last pet!", Color3.fromRGB(255, 160, 120))
		return
	end
	local wasEquipped = data.Pets[index].Equipped
	table.remove(data.Pets, index)
	PlayerData.SendPets(player)
	if wasEquipped then
		Pets.Refresh(player)
	end
end

function Pets.Hatch(player: Player, eggIndex: number)
	local egg = Config.Eggs[eggIndex]
	local data = PlayerData.Get(player)
	local state = getState(player)
	if not egg or not data then
		return
	end

	-- wait for the last hatch animation to finish
	if os.clock() - state.LastHatch < 2.5 then
		return
	end
	if data.ZonesUnlocked < egg.Zone then
		return
	end
	if #data.Pets >= Config.MaxPetsInInventory then
		Remotes.Tell(player, "Your pet bag is full! Delete some pets first.", Color3.fromRGB(255, 160, 120))
		return
	end
	if not PlayerData.SpendJelly(player, egg.Price) then
		Remotes.Tell(player, "You need " .. Format.Short(egg.Price) .. " Jelly to hatch this egg!", Color3.fromRGB(255, 160, 120))
		return
	end
	state.LastHatch = os.clock()

	local petName = rollPet(egg)
	local newPet = { Name = petName, Equipped = false }
	table.insert(data.Pets, newPet)
	data.TotalHatched += 1

	-- if there's a free slot, put the new pet to work straight away
	if countEquipped(data.Pets) < PlayerData.PetSlots(player) then
		newPet.Equipped = true
	end

	Remotes.Hatched:FireClient(player, petName, eggIndex)
	PlayerData.SendPets(player)

	-- wait for the hatch animation before the new pet pops out
	task.delay(2.2, function()
		if player.Parent then
			Pets.Refresh(player)
		end
	end)

	-- tell everyone about really rare hatches
	local rarity = Config.Pets[petName].Rarity
	if Config.RarityRank(rarity) >= Config.RarityRank("Legendary") then
		for _, other in Players:GetPlayers() do
			Remotes.Tell(other, player.DisplayName .. " hatched a " .. rarity .. " " .. petName .. "!", Config.RarityColors[rarity])
		end
	end
end

-- Sends all of a player's pets to attack one blob.
function Pets.SetTarget(player: Player, blob: BasePart)
	local data = PlayerData.Get(player)
	if not data or not Blobs.IsAlive(blob) then
		return
	end
	if (blob:GetAttribute("Zone") or 99) > data.ZonesUnlocked then
		return
	end
	local state = getState(player)
	if #state.Following == 0 then
		Remotes.Tell(player, "You need a pet first! Hatch an egg.", Color3.fromRGB(255, 200, 120))
		return
	end
	state.Target = if state.Target == blob then nil else blob -- click again to call pets back
end

function Pets.SetAuto(player: Player, isOn: any)
	getState(player).Auto = isOn == true
end

function Pets.Clear(player: Player)
	local state = states[player]
	if state then
		for _, following in state.Following do
			following.Model:Destroy()
		end
		states[player] = nil
	end
end

local function updatePlayer(player: Player, state: State, dt: number, now: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end

	-- forget targets that are gone or too far away
	local target = state.Target
	if target and (not Blobs.IsAlive(target) or (target.Position - root.Position).Magnitude > Config.ClickRange + 20) then
		state.Target = nil
		target = nil
	end

	-- Auto mode: find the next blob by itself
	if not target and state.Auto and #state.Following > 0 then
		target = Blobs.FindNearest(root.Position, Config.AutoTargetRange, data.ZonesUnlocked)
		state.Target = target
	end

	local count = #state.Following
	local alpha = 1 - math.exp(-dt * 8) -- smooth movement
	local petsAtTarget = 0
	local damage = 0

	for i, following in state.Following do
		local model = following.Model
		local body = model.PrimaryPart :: BasePart
		local current = body.CFrame
		local goal: CFrame

		if target then
			-- circle around the blob and hop on it
			local angle = (i / count) * math.pi * 2
			local radius = target.Size.X / 2 + 1.4
			local hop = math.abs(math.sin(now * 8 + i)) * 1.2
			local spot = target.Position + Vector3.new(math.cos(angle) * radius, -target.Size.Y / 2 + 1.25 + hop, math.sin(angle) * radius)
			goal = CFrame.lookAt(spot, Vector3.new(target.Position.X, spot.Y, target.Position.Z))
			if (current.Position - spot).Magnitude < 4 then
				petsAtTarget += 1
				damage += following.Power
			end
		else
			-- follow behind the player in a little row
			local spread = (i - (count + 1) / 2) * 3.5
			local bob = math.sin(now * 4 + i) * 0.3
			local flat = CFrame.new(root.Position) * CFrame.Angles(0, select(2, root.CFrame:ToEulerAnglesYXZ()), 0)
			local spot = (flat * CFrame.new(spread, -1.8 + bob, 6 + math.abs(spread) * 0.3)).Position
			local wobble = math.sin(now * 6 + i) * 0.08 -- jiggly waddle
			goal = CFrame.lookAt(spot, spot + root.CFrame.LookVector) * CFrame.Angles(0, 0, wobble)
		end

		if (current.Position - goal.Position).Magnitude > 100 then
			body.CFrame = goal -- too far, just teleport
		else
			-- only the body moves; every other part is welded to it
			body.CFrame = current:Lerp(goal, alpha)
		end
	end

	-- pets that reached the blob hit it every PetHitSeconds
	state.HitTimer += dt
	if state.HitTimer >= Config.PetHitSeconds then
		state.HitTimer = 0
		if target and petsAtTarget > 0 then
			Blobs.Damage(player, target, damage)
		end
	end
end

function Pets.Start()
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for player, state in states do
			updatePlayer(player, state, dt, now)
		end
	end)
end

return Pets
