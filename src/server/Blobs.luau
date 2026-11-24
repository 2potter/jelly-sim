--[[
	Blobs: the jelly blobs you break to earn Jelly.
	Click or tap a blob and your pets swarm it! Each blob has health;
	when it hits 0 it pops and gives Jelly to the player whose pets broke it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
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
	gui.Enabled = false -- only shows up once the blob gets hit, so the screen stays clean
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

-- How tall a jelly cube is compared to how wide it is (jelly sags a little).
local CUBE_HEIGHT = 0.85

local function cubePart(model: Model, name: string, shape: Enum.PartType, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, transparency: number, castShadow: boolean?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape -- set before Size so Roblox doesn't resize it
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = castShadow == true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- Builds a wobbly see-through jelly cube with rounded edges.
-- The model's center is the middle of the cube.
local function buildJellyCube(info): Model
	local model = Instance.new("Model")
	local w = info.Size
	local h = info.Size * CUBE_HEIGHT
	local r = w * 0.16 -- how round the edges are
	local hw, hh = w / 2, h / 2
	local color = info.Color
	local GLASS = Enum.Material.Glass
	local NEON = Enum.Material.Neon
	local BALL = Enum.PartType.Ball
	local BLOCK = Enum.PartType.Block
	local CYLINDER = Enum.PartType.Cylinder
	local jellyT = 0.42 -- see-through, like real jelly

	-- rounded box: three overlapping slabs, plus round edges and corners on the top half.
	-- (where slabs overlap, the jelly looks thicker and darker, just like real jelly)
	local core = cubePart(model, "Jelly", BLOCK, Vector3.new(w - r * 2, h - r * 2, w - r * 2), CFrame.new(), color, GLASS, jellyT, true)
	cubePart(model, "SlabX", BLOCK, Vector3.new(w, h - r * 2, w - r * 2), CFrame.new(), color, GLASS, jellyT)
	cubePart(model, "SlabZ", BLOCK, Vector3.new(w - r * 2, h - r * 2, w), CFrame.new(), color, GLASS, jellyT)
	cubePart(model, "SlabY", BLOCK, Vector3.new(w - r * 2, h, w - r * 2), CFrame.new(), color:Lerp(Color3.new(1, 1, 1), 0.08), GLASS, jellyT)
	-- the 4 standing edges
	for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		local x, z = corner[1] * (hw - r), corner[2] * (hw - r)
		cubePart(model, "Edge", CYLINDER, Vector3.new(h - r * 2, r * 2, r * 2), CFrame.new(x, 0, z) * CFrame.Angles(0, 0, math.rad(90)), color, GLASS, jellyT)
		cubePart(model, "Corner", BALL, Vector3.new(r * 2, r * 2, r * 2), CFrame.new(x, hh - r, z), color, GLASS, jellyT)
		cubePart(model, "BottomCorner", BALL, Vector3.new(r * 2, r * 2, r * 2), CFrame.new(x, -hh + r, z), color, GLASS, jellyT)
	end
	-- the 4 top edges and 4 bottom edges
	for _, y in { hh - r, -hh + r } do
		for _, side in { 1, -1 } do
			cubePart(model, "Edge", CYLINDER, Vector3.new(w - r * 2, r * 2, r * 2), CFrame.new(0, y, side * (hw - r)), color, GLASS, jellyT)
			cubePart(model, "Edge", CYLINDER, Vector3.new(w - r * 2, r * 2, r * 2), CFrame.new(side * (hw - r), y, 0) * CFrame.Angles(0, math.rad(90), 0), color, GLASS, jellyT)
		end
	end

	-- a deeper, darker heart in the middle (real jelly looks darker where it's thick)
	cubePart(model, "Heart", BLOCK, Vector3.new(w * 0.5, h * 0.45, w * 0.5), CFrame.new(0, -h * 0.05, 0), color:Lerp(Color3.new(0, 0, 0), 0.35), GLASS, 0.3)

	-- tiny air bubbles trapped inside
	local bubbleSpots = { { 0.22, 0.15, -0.18 }, { -0.25, -0.2, 0.1 }, { 0.05, 0.28, 0.25 }, { -0.12, 0.05, -0.3 } }
	for _, spot in bubbleSpots do
		local size = w * random:NextNumber(0.04, 0.07)
		cubePart(model, "Bubble", BALL, Vector3.new(size, size, size), CFrame.new(spot[1] * w, spot[2] * h, spot[3] * w), Color3.new(1, 1, 1), GLASS, 0.5)
	end

	-- bright shiny highlights, like light bouncing off wet jelly
	cubePart(model, "Shine", BLOCK, Vector3.new(w * 0.55, w * 0.035, w * 0.035), CFrame.new(-w * 0.05, hh - r * 0.35, -hw + r * 0.35), Color3.new(1, 1, 1), NEON, 0.25)
	cubePart(model, "Shine", BLOCK, Vector3.new(w * 0.035, h * 0.45, w * 0.035), CFrame.new(-hw + r * 0.3, h * 0.05, -hw + r * 0.3), Color3.new(1, 1, 1), NEON, 0.35)
	cubePart(model, "ShineSpot", BALL, Vector3.new(w * 0.09, w * 0.09, w * 0.09), CFrame.new(-w * 0.22, hh, -w * 0.12), Color3.new(1, 1, 1), NEON, 0.2)

	-- big ones get whipped cream and a cherry on top
	if info.Style == "Giant" then
		local cream = Color3.fromRGB(255, 250, 245)
		for i = 1, 6 do
			local angle = i / 6 * math.pi * 2
			cubePart(model, "Cream", BALL, Vector3.new(w * 0.16, w * 0.16, w * 0.16), CFrame.new(math.sin(angle) * w * 0.15, hh + w * 0.04, math.cos(angle) * w * 0.15), cream, Enum.Material.SmoothPlastic, 0)
		end
		cubePart(model, "Cream", BALL, Vector3.new(w * 0.22, w * 0.22, w * 0.22), CFrame.new(0, hh + w * 0.1, 0), cream, Enum.Material.SmoothPlastic, 0)
		cubePart(model, "Cherry", BALL, Vector3.new(w * 0.14, w * 0.14, w * 0.14), CFrame.new(0, hh + w * 0.24, 0), Color3.fromRGB(235, 35, 65), GLASS, 0.05)
	end

	-- soft shadow on the ground under the cube
	cubePart(model, "Shadow", CYLINDER, Vector3.new(0.05, w * 1.25, w * 1.25), CFrame.new(0, -hh + 0.03, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 0.7)

	model.PrimaryPart = core
	return model
end

-- How tall the clickable box around a blob should be.
local function blobHeight(info): number
	local height = info.Size * CUBE_HEIGHT
	if info.Style == "Giant" then
		height += info.Size * 0.3 -- room for the cream and cherry
	end
	return height
end

-- Makes the jelly you see. Everything is welded to the invisible hitbox.
local function buildLook(hitbox: Part, info)
	local model = buildJellyCube(info)

	-- sit the cube on the ground at the bottom of the hitbox, turned a random way
	local hitboxBottom = hitbox.Position.Y - hitbox.Size.Y / 2
	local cubeCenterY = hitboxBottom + info.Size * CUBE_HEIGHT / 2
	model:PivotTo(CFrame.new(hitbox.Position.X, cubeCenterY, hitbox.Position.Z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hitbox
			weld.Part1 = part
			weld.Parent = part
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
	local hitboxHeight = blobHeight(info)
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
		bar.Enabled = true
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
