--[[
	Blobs: the jelly blobs you break to earn Jelly.
	Click or tap a blob and your pets swarm it! Each blob has health;
	when it hits 0 it pops and gives Jelly to the player whose pets broke it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local PetModels = require(ReplicatedStorage.Shared.PetModels)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Blobs = {}

local random = Random.new()
local folder: Folder
local countInZone: { [number]: number } = {}

local SQUISH = TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)

local function pickBlobType(zoneIndex: number)
	local blobs = Config.Zones[zoneIndex].Blobs
	local total = 0
	for _, blob in blobs do
		total += blob.Chance
	end
	local roll = random:NextNumber(0, total)
	for _, blob in blobs do
		roll -= blob.Chance
		if roll <= 0 then
			return blob
		end
	end
	return blobs[1]
end

local function makeHealthBar(blob: Part, title: string, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffset = Vector3.new(0, blob.Size.Y / 2 + 1.5, 0)
	gui.MaxDistance = 60
	gui.LightInfluence = 0

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 16)
	name.BackgroundTransparency = 1
	name.Text = title
	name.TextScaled = true
	name.Font = Enum.Font.FredokaOne
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.3
	name.Parent = gui

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Position = UDim2.fromOffset(0, 18)
	back.Size = UDim2.new(1, 0, 0, 12)
	back.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
	back.Parent = gui
	Instance.new("UICorner").Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.Parent = back
	Instance.new("UICorner").Parent = fill

	gui.Parent = blob
end

-- Makes the jelly you see. Everything is welded to the invisible hitbox.
local function buildLook(hitbox: Part, info)
	local size = info.Size
	local model: Model

	if info.Style == "Drop" then
		-- a squishy jelly gumdrop
		model = Instance.new("Model")
		local function piece(name: string, partSize: Vector3, offsetY: number, color: Color3, material: Enum.Material, transparency: number)
			local part = Instance.new("Part")
			part.Name = name
			part.Size = partSize
			part.Color = color
			part.Material = material
			part.Transparency = transparency
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.CFrame = CFrame.new(0, offsetY, 0)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
			part.Parent = model
			return part
		end
		local base = piece("Jelly", Vector3.new(size, size * 0.7, size), -size * 0.15, info.Color, Enum.Material.Glass, 0.25)
		piece("JellyTop", Vector3.new(size * 0.6, size * 0.55, size * 0.6), size * 0.2, info.Color, Enum.Material.Glass, 0.25)
		local shine = piece("Shine", Vector3.new(size * 0.12, size * 0.3, size * 0.06), 0, Color3.new(1, 1, 1), Enum.Material.Neon, 0.35)
		shine.CFrame = CFrame.new(-size * 0.28, size * 0.05, -size * 0.38) * CFrame.Angles(0, math.rad(-35), math.rad(15))
		model.PrimaryPart = base
	else
		-- a pudding! Giant ones get cream and a cherry
		local isGiant = info.Style == "Giant"
		model = PetModels.Pudding({
			Color = info.Color,
			Cream = if isGiant then Color3.fromRGB(255, 250, 245) else nil,
			Topping = if isGiant then "Cherry" else nil,
			Stars = isGiant,
			Scale = size / 3.4,
			Transparency = 0.25,
		})
	end

	-- line the jelly up with the hitbox, then weld it on
	local hitboxBottom = hitbox.Position.Y - hitbox.Size.Y / 2
	local modelBottom = if info.Style == "Drop" then -size * 0.35 else -1.2 * size / 3.4 -- how far below its center the jelly reaches
	model:PivotTo(CFrame.new(hitbox.Position.X, hitboxBottom - modelBottom, hitbox.Position.Z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			local weld = part:FindFirstChildOfClass("WeldConstraint")
			if weld then
				weld:Destroy()
			end
			local newWeld = Instance.new("WeldConstraint")
			newWeld.Part0 = hitbox
			newWeld.Part1 = part
			newWeld.Parent = part
			part.Parent = hitbox
		end
	end
	model:Destroy()
end

local function spawnBlob(zoneIndex: number, onClicked: (Player, BasePart) -> ())
	local info = pickBlobType(zoneIndex)
	local spot = WorldBuilder.RandomSpot(zoneIndex, random)
	local size = info.Size

	-- the invisible box you click on (and that pets attack)
	local hitboxHeight = if info.Style == "Giant" then size * 1.05 else size * 0.85
	local blob = Instance.new("Part")
	blob.Name = info.Name
	blob.Size = Vector3.new(size * 1.1, hitboxHeight, size * 1.1)
	blob.Position = spot + Vector3.new(0, hitboxHeight / 2, 0)
	blob.Transparency = 1
	blob.Color = info.Color -- used for the color of the jelly bits when it pops
	blob.Anchored = true
	blob.CanCollide = false
	blob.CanTouch = false
	blob:SetAttribute("Zone", zoneIndex)
	blob:SetAttribute("Health", info.Health)
	blob:SetAttribute("MaxHealth", info.Health)
	blob:SetAttribute("Reward", info.Reward)
	blob:SetAttribute("HomeCFrame", blob.CFrame)

	buildLook(blob, info)
	makeHealthBar(blob, info.Name .. "  " .. Format.Short(info.Reward), info.Color)

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = Config.ClickRange
	click.MouseClick:Connect(function(player)
		onClicked(player, blob)
	end)
	click.Parent = blob

	countInZone[zoneIndex] += 1
	blob.Destroying:Connect(function()
		countInZone[zoneIndex] -= 1
	end)

	blob.Parent = folder
end

-- Starts spawning blobs in every zone. onClicked runs when someone clicks a blob.
function Blobs.Start(onClicked: (Player, BasePart) -> ())
	folder = Instance.new("Folder")
	folder.Name = "Blobs"
	folder.Parent = workspace

	for zoneIndex in Config.Zones do
		countInZone[zoneIndex] = 0
		-- fill every zone right away
		for _ = 1, Config.BlobsPerZone do
			spawnBlob(zoneIndex, onClicked)
		end
	end

	-- then keep topping them up
	task.spawn(function()
		while true do
			task.wait(Config.BlobRespawnSeconds)
			for zoneIndex in Config.Zones do
				if countInZone[zoneIndex] < Config.BlobsPerZone then
					spawnBlob(zoneIndex, onClicked)
				end
			end
		end
	end)
end

function Blobs.IsAlive(blob: BasePart?): boolean
	return blob ~= nil and blob.Parent ~= nil and (blob:GetAttribute("Health") or 0) > 0
end

-- Finds the closest blob to a position that the player is allowed to reach.
function Blobs.FindNearest(position: Vector3, range: number, maxZone: number): BasePart?
	local best, bestDistance = nil, range
	for _, blob in folder:GetChildren() do
		if blob:IsA("BasePart") and (blob:GetAttribute("Zone") or 99) <= maxZone and Blobs.IsAlive(blob) then
			local distance = (blob.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = blob, distance
			end
		end
	end
	return best
end

-- Hurts a blob. If it pops, the player gets the Jelly.
function Blobs.Damage(player: Player, blob: BasePart, amount: number)
	if not Blobs.IsAlive(blob) then
		return
	end

	local maxHealth = blob:GetAttribute("MaxHealth")
	local health = math.max(0, blob:GetAttribute("Health") - amount)
	blob:SetAttribute("Health", health)

	local bar = blob:FindFirstChild("HealthBar")
	if bar then
		bar.Back.Fill.Size = UDim2.fromScale(health / maxHealth, 1)
	end

	if health > 0 then
		-- a little jiggle so you can see it getting hit
		local home = blob:GetAttribute("HomeCFrame")
		blob.CFrame = home * CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(random:NextNumber(-8, 8)), 0, math.rad(random:NextNumber(-8, 8)))
		TweenService:Create(blob, SQUISH, { CFrame = home }):Play()
		return
	end

	-- POP!
	local data = PlayerData.Get(player)
	local bonus = 1 + 0.2 * (data and data.Upgrades.JellyBonus or 0)
	local reward = math.floor(blob:GetAttribute("Reward") * bonus)
	PlayerData.AddJelly(player, reward)
	Remotes.Reward:FireClient(player, reward, blob.Position, blob.Color)
	blob:Destroy()
end

return Blobs
