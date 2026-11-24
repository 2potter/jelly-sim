--[[
	WorldBuilder: builds the whole map when the server starts, using Config.
	Zones sit in a line going forward (towards -Z), with a locked gate
	between each one and an egg in every zone.

	Everything goes in Workspace.JellyWorld. You can also build your own
	map in Studio and keep this as the "game stuff" layer.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local WorldBuilder = {}

local FLOOR_Y = 0 -- floors are 1 stud thick, so their top is at Y = 0.5

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

-- A floating sign with big text.
local function sign(parent: Instance, lines: { { Text: string, Color: Color3?, Size: number? } }, height: number, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromScale(10, #lines * 1.4)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 120
	gui.LightInfluence = 0

	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui

	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = i
		label.Size = UDim2.fromScale(1, (line.Size or 1) / #lines)
		label.BackgroundTransparency = 1
		label.Text = line.Text
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = line.Color or Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.2
		label.Parent = gui
	end

	gui.Parent = parent
	return gui
end

local function buildZone(world: Folder, zoneIndex: number)
	local zone = Config.Zones[zoneIndex]
	local center = Config.ZoneCenter(zoneIndex)

	local floor = part({
		Name = "Zone" .. zoneIndex .. "_Floor",
		Size = Vector3.new(Config.ZoneSize, 1, Config.ZoneSize),
		Position = center + Vector3.new(0, FLOOR_Y, 0),
		Color = zone.FloorColor,
		Material = Enum.Material.Grass,
	})
	floor:SetAttribute("ZoneIndex", zoneIndex)
	floor.Parent = world

	-- A post with the zone's name near the start of the zone
	local post = part({
		Name = "Zone" .. zoneIndex .. "_Sign",
		Size = Vector3.new(1, 8, 1),
		Position = center + Vector3.new(-12, 4.5, Config.ZoneSize / 2 - 10),
		Color = Color3.fromRGB(120, 80, 50),
		Material = Enum.Material.Wood,
	})
	post.Parent = world
	sign(post, { { Text = zone.Name, Color = Color3.new(1, 1, 1) } }, 6, 150)
end

local function buildGate(gatesFolder: Folder, zoneIndex: number): ProximityPrompt
	local zone = Config.Zones[zoneIndex]
	local gateZ = Config.ZoneCenter(zoneIndex).Z + Config.ZoneSize / 2

	local gate = Instance.new("Model")
	gate.Name = "Gate" .. zoneIndex
	gate:SetAttribute("ZoneIndex", zoneIndex)

	local wall = part({
		Name = "Wall",
		Size = Vector3.new(Config.ZoneSize, 24, 2),
		Position = Vector3.new(0, 12.5, gateZ),
		Color = Config.Zones[zoneIndex].Blobs[1].Color,
		Material = Enum.Material.ForceField,
		Transparency = 0.2,
	})
	wall.Parent = gate
	sign(wall, {
		{ Text = "🔒 " .. zone.Name, Color = Color3.new(1, 1, 1) },
		{ Text = Format.Short(zone.Price) .. " Jelly", Color = Color3.fromRGB(255, 230, 120) },
	}, 0, 150)

	-- The button you walk up to, on the side you come from
	local button = part({
		Name = "Button",
		Size = Vector3.new(6, 1, 6),
		Position = Vector3.new(0, 0.6, gateZ + 6),
		Color = Color3.fromRGB(255, 220, 80),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	button.Parent = gate

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock (" .. Format.Short(zone.Price) .. " Jelly)"
	prompt.ObjectText = zone.Name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	gate.PrimaryPart = wall
	gate.Parent = gatesFolder
	return prompt
end

local function buildEgg(eggsFolder: Folder, eggIndex: number): ProximityPrompt
	local egg = Config.Eggs[eggIndex]
	local center = Config.ZoneCenter(egg.Zone)
	local base = center + Vector3.new(22, 0, 25)

	local model = Instance.new("Model")
	model.Name = egg.Name

	local pedestal = part({
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 8, 8),
		CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(245, 245, 255),
		Material = Enum.Material.Marble,
	})
	pedestal.Parent = model

	local eggPart = part({
		Name = "Egg",
		Size = Vector3.new(4.5, 5.5, 4.5),
		Position = base + Vector3.new(0, 5.3, 0),
		Color = egg.Color,
		Material = Enum.Material.SmoothPlastic,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- stretched sphere = egg shape
	mesh.Parent = eggPart
	eggPart.Parent = model

	-- Sign: egg name, price and the chance of every pet
	local lines = {
		{ Text = egg.Name, Color = egg.Color, Size = 1.4 },
		{ Text = Format.Short(egg.Price) .. " Jelly", Color = Color3.fromRGB(255, 230, 120) },
	}
	for _, entry in egg.Pets do
		local petName, chance = entry[1], entry[2]
		local rarity = Config.Pets[petName].Rarity
		table.insert(lines, {
			Text = string.format("%s  %s%%", petName, tostring(chance)),
			Color = Config.RarityColors[rarity],
			Size = 0.8,
		})
	end
	sign(eggPart, lines, 9, 80)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hatch (" .. Format.Short(egg.Price) .. " Jelly)"
	prompt.ObjectText = egg.Name
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = eggPart

	model.PrimaryPart = eggPart
	model.Parent = eggsFolder
	return prompt
end

local function buildBorders(world: Folder)
	local zoneCount = #Config.Zones
	local length = Config.ZoneSize * zoneCount
	local half = Config.ZoneSize / 2
	local midZ = -(zoneCount - 1) * Config.ZoneSize / 2
	local fence = {
		{ Size = Vector3.new(2, 14, length), Position = Vector3.new(-half - 1, 7.5, midZ) },
		{ Size = Vector3.new(2, 14, length), Position = Vector3.new(half + 1, 7.5, midZ) },
		{ Size = Vector3.new(Config.ZoneSize + 4, 14, 2), Position = Vector3.new(0, 7.5, half + 1) },
		{ Size = Vector3.new(Config.ZoneSize + 4, 14, 2), Position = Vector3.new(0, 7.5, midZ - length / 2 - 1) },
	}
	for i, info in fence do
		part({
			Name = "Fence" .. i,
			Size = info.Size,
			Position = info.Position,
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.7,
		}).Parent = world
	end
end

-- Builds everything and returns the prompts so Main can listen to them.
function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "JellyWorld"

	local gatesFolder = Instance.new("Folder")
	gatesFolder.Name = "Gates"
	gatesFolder.Parent = world

	local eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "Eggs"
	eggsFolder.Parent = world

	for zoneIndex in Config.Zones do
		buildZone(world, zoneIndex)
	end

	local gatePrompts = {}
	for zoneIndex = 2, #Config.Zones do
		gatePrompts[zoneIndex] = buildGate(gatesFolder, zoneIndex)
	end

	local eggPrompts = {}
	for eggIndex in Config.Eggs do
		eggPrompts[eggIndex] = buildEgg(eggsFolder, eggIndex)
	end

	buildBorders(world)

	-- Make sure players start in the first zone
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "JellySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Config.ZoneCenter(1) + Vector3.new(0, 0.6, 20)
	spawn.Color = Color3.fromRGB(255, 150, 200)
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0 -- no spawn forcefield
	spawn.Parent = world

	world.Parent = workspace
	return {
		GatePrompts = gatePrompts,
		EggPrompts = eggPrompts,
	}
end

-- A random spot on top of a zone's floor (kept away from the edges and gates).
function WorldBuilder.RandomSpot(zoneIndex: number, random: Random): Vector3
	local center = Config.ZoneCenter(zoneIndex)
	local half = Config.ZoneSize / 2 - 10
	return center + Vector3.new(random:NextNumber(-half, half), FLOOR_Y + 0.5, random:NextNumber(-half, half))
end

return WorldBuilder
