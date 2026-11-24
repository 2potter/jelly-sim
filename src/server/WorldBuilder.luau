--[[
	WorldBuilder: builds the whole map when the server starts, using Config.
	Zones sit in a line going forward (towards -Z), with a locked gate
	between each one and an egg in every zone.

	It also sets up the lighting (soft pastel sky, glow on neon things)
	and sprinkles candy decorations around the edges of each zone.

	Everything goes in Workspace.JellyWorld. You can also build your own
	map in Studio and keep this as the "game stuff" layer.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local PetModels = require(ReplicatedStorage.Shared.PetModels)

local WorldBuilder = {}

local FLOOR_Y = 0 -- floors are 1 stud thick, so their top is at Y = 0.5
local GROUND = FLOOR_Y + 0.5
local EGG_OFFSET = Vector3.new(24, 0, 28) -- where the egg sits in its zone
local WHITE = Color3.new(1, 1, 1)

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	-- Shape has to be set before Size, or Roblox resizes the part
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Shape" and key ~= "Parent" then
			(p :: any)[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

-- A decoration: can't be bumped into or clicked, so it never blocks blobs.
local function decor(props: { [string]: any }): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return part(props)
end

-- A stretched ball (great for gumdrops, clouds, tree tops...).
local function ball(parent: Instance, size: Vector3, color: Color3, cframe: CFrame, material: Enum.Material?, transparency: number?): Part
	local p = decor({
		Size = size,
		Color = color,
		CFrame = cframe,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = transparency or 0,
		Parent = parent,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- A floating sign with big chunky text.
local function sign(parent: Instance, lines: { { Text: string, Color: Color3?, Size: number? } }, height: number, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromScale(12, #lines * 1.5)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = maxDistance or 120
	gui.LightInfluence = 0

	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui

	local totalSize = 0
	for _, line in lines do
		totalSize += line.Size or 1
	end
	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = i
		label.Size = UDim2.fromScale(1, (line.Size or 1) / totalSize)
		label.BackgroundTransparency = 1
		label.Text = line.Text
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = line.Color or WHITE
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(60, 30, 80)
		stroke.Thickness = 2.5
		stroke.Parent = label
	end

	gui.Parent = parent
	return gui
end

---------------------------------------------------------------------
-- Lighting: bright, soft and a little bit dreamy
---------------------------------------------------------------------
local function setupLighting()
	-- The main lighting settings (Future lighting, sun, brightness) live in
	-- default.project.json, because a script isn't allowed to switch on Future
	-- lighting. These are the same values, in case the project file wasn't used.
	Lighting.ClockTime = 14.2
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.1
	Lighting.Ambient = Color3.fromRGB(72, 64, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 128, 152)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 237, 214) -- warm sunshine
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1 -- shiny reflections on the jelly
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35

	local function effect(className: string, props: { [string]: any })
		local existing = Lighting:FindFirstChild("Jelly" .. className)
		if existing then
			existing:Destroy()
		end
		local instance = Instance.new(className)
		instance.Name = "Jelly" .. className
		for key, value in props do
			(instance :: any)[key] = value
		end
		instance.Parent = Lighting
	end

	-- a soft pink-and-lilac sky haze, without washing the colors out
	effect("Atmosphere", {
		Density = 0.22,
		Offset = 0.25,
		Color = Color3.fromRGB(255, 226, 236),
		Decay = Color3.fromRGB(175, 145, 225),
		Glare = 0.15,
		Haze = 0.8,
	})
	-- a gentle glow on bright and neon things
	effect("BloomEffect", { Intensity = 0.35, Size = 24, Threshold = 1.8 })
	-- a little extra color and contrast so it pops
	effect("ColorCorrectionEffect", {
		Saturation = 0.12,
		Contrast = 0.1,
		Brightness = 0,
		TintColor = Color3.fromRGB(255, 249, 246),
	})
	effect("SunRaysEffect", { Intensity = 0.06, Spread = 0.5 })
end

---------------------------------------------------------------------
-- Candy decorations
---------------------------------------------------------------------
local function lollipop(parent: Instance, base: Vector3, color: Color3, random: Random)
	local height = random:NextNumber(7, 11)
	decor({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 0.5, 0.5),
		CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = WHITE,
		Parent = parent,
	})
	local top = CFrame.new(base + Vector3.new(0, height + 1.5, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
	-- the candy disc, with a white swirl ring
	decor({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 4.5, 4.5),
		CFrame = top * CFrame.Angles(0, math.rad(90), 0),
		Color = color,
		Parent = parent,
	})
	decor({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.85, 3, 3),
		CFrame = top * CFrame.Angles(0, math.rad(90), 0),
		Color = WHITE,
		Parent = parent,
	})
	decor({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.9, 1.6, 1.6),
		CFrame = top * CFrame.Angles(0, math.rad(90), 0),
		Color = color,
		Parent = parent,
	})
end

local function gumdrop(parent: Instance, base: Vector3, color: Color3, random: Random)
	local size = random:NextNumber(3, 5)
	ball(parent, Vector3.new(size, size * 0.9, size), color, CFrame.new(base + Vector3.new(0, size * 0.3, 0)), Enum.Material.Glass, 0.2)
	ball(parent, Vector3.new(size * 0.15, size * 0.3, size * 0.08), WHITE, CFrame.new(base + Vector3.new(-size * 0.22, size * 0.45, -size * 0.38)), Enum.Material.Neon, 0.3)
end

local function candyTree(parent: Instance, base: Vector3, color: Color3, random: Random)
	local height = random:NextNumber(9, 13)
	decor({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.6, 1.6),
		CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 235, 245),
		Parent = parent,
	})
	-- fluffy cotton candy puffs
	for _, puff in { { 0, 0, 0, 7 }, { 2.4, -0.8, 1, 5 }, { -2.2, -0.6, -1, 5.5 }, { 0.5, 1.8, -0.5, 4.5 } } do
		local size = puff[4]
		ball(parent, Vector3.new(size, size * 0.85, size), color, CFrame.new(base + Vector3.new(puff[1], height + puff[2], puff[3])))
	end
end

local function bigPudding(parent: Instance, base: Vector3, color: Color3, random: Random)
	local scale = random:NextNumber(2.2, 3)
	local model = PetModels.Pudding({
		Color = color,
		Cream = WHITE,
		Topping = "Cherry",
		Face = true,
		Scale = scale,
	})
	model.Name = "BigPudding"
	model:PivotTo(CFrame.new(base + Vector3.new(0, 1.2 * scale, 0)) * CFrame.Angles(0, random:NextNumber(-0.6, 0.6) + (if base.X > 0 then math.rad(90) else math.rad(-90)), 0)) -- face the middle
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	model.Parent = parent
end

local DECOR_MAKERS = { lollipop, gumdrop, candyTree, gumdrop, bigPudding, lollipop, candyTree }

local function decorateZone(parent: Instance, zoneIndex: number)
	local zone = Config.Zones[zoneIndex]
	local center = Config.ZoneCenter(zoneIndex)
	local random = Random.new(zoneIndex * 1000) -- same layout every time
	local half = Config.ZoneSize / 2

	-- along both side fences
	local z = -half + 6
	local i = 0
	while z < half - 6 do
		for _, side in { -1, 1 } do
			i += 1
			local x = side * random:NextNumber(half - 8, half - 4)
			local maker = DECOR_MAKERS[(i - 1) % #DECOR_MAKERS + 1]
			local color = zone.Decor[random:NextInteger(1, #zone.Decor)]
			maker(parent, center + Vector3.new(x, GROUND, z + random:NextNumber(-3, 3)), color, random)
		end
		z += random:NextNumber(11, 16)
	end
end

---------------------------------------------------------------------
-- Zones, gates, eggs
---------------------------------------------------------------------
local function buildZone(world: Folder, zoneIndex: number)
	local zone = Config.Zones[zoneIndex]
	local center = Config.ZoneCenter(zoneIndex)

	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "Zone" .. zoneIndex
	zoneFolder.Parent = world

	local floor = part({
		Name = "Floor",
		Size = Vector3.new(Config.ZoneSize, 1, Config.ZoneSize),
		Position = center + Vector3.new(0, FLOOR_Y, 0),
		Color = zone.FloorColor,
		Material = Enum.Material.Grass,
		Parent = zoneFolder,
	})
	floor:SetAttribute("ZoneIndex", zoneIndex)

	-- a soft candy path down the middle, with dots along the edges
	decor({
		Name = "Path",
		Size = Vector3.new(16, 0.2, Config.ZoneSize),
		Position = center + Vector3.new(0, GROUND + 0.1, 0),
		Color = zone.PathColor,
		Parent = zoneFolder,
	})
	for zDot = -Config.ZoneSize / 2 + 4, Config.ZoneSize / 2 - 4, 8 do
		for _, side in { -1, 1 } do
			ball(zoneFolder, Vector3.new(1.4, 0.8, 1.4), zone.Decor[1], CFrame.new(center + Vector3.new(side * 8.6, GROUND + 0.2, zDot)))
		end
	end

	-- zone name board near the start of the zone
	local board = part({
		Name = "Sign",
		Size = Vector3.new(14, 4, 1),
		CFrame = CFrame.new(center + Vector3.new(-14, GROUND + 7, Config.ZoneSize / 2 - 12)),
		Color = WHITE,
		CanCollide = false,
		Parent = zoneFolder,
	})
	for _, side in { -1, 1 } do
		decor({
			Size = Vector3.new(0.8, 7, 0.8),
			Position = board.Position + Vector3.new(side * 5.5, -3.5, 0),
			Color = zone.Decor[1],
			Parent = zoneFolder,
		})
	end
	sign(board, { { Text = zone.Name, Color = zone.Decor[1] } }, 0, 200).Size = UDim2.fromScale(14, 3)

	decorateZone(zoneFolder, zoneIndex)
end

local function buildGate(gatesFolder: Folder, zoneIndex: number): ProximityPrompt
	local zone = Config.Zones[zoneIndex]
	local gateZ = Config.ZoneCenter(zoneIndex).Z + Config.ZoneSize / 2
	local color = zone.Decor[1]

	local gate = Instance.new("Model")
	gate.Name = "Gate" .. zoneIndex
	gate:SetAttribute("ZoneIndex", zoneIndex)

	-- the glowing jelly wall (your screen makes it disappear once unlocked)
	local wall = part({
		Name = "Wall",
		Size = Vector3.new(Config.ZoneSize, 26, 1),
		Position = Vector3.new(0, GROUND + 13, gateZ),
		Color = color,
		Material = Enum.Material.ForceField,
		Transparency = 0.1,
		Parent = gate,
	})
	sign(wall, {
		{ Text = "🔒 " .. zone.Name, Color = WHITE },
		{ Text = Format.Short(zone.Price) .. " Jelly", Color = Color3.fromRGB(255, 230, 120) },
	}, 4, 160)

	-- a big candy archway around the middle
	for _, side in { -1, 1 } do
		decor({
			Name = "Pillar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(20, 4, 4),
			CFrame = CFrame.new(side * 12, GROUND + 10, gateZ) * CFrame.Angles(0, 0, math.rad(90)),
			Color = WHITE,
			Parent = gate,
		})
		-- candy stripes on the pillars
		for stripe = 1, 4 do
			decor({
				Name = "Stripe",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.4, 4.2, 4.2),
				CFrame = CFrame.new(side * 12, GROUND + stripe * 4.5 - 1, gateZ) * CFrame.Angles(0, 0, math.rad(90)),
				Color = color,
				Parent = gate,
			})
		end
		ball(gate, Vector3.new(5.5, 5.5, 5.5), color, CFrame.new(side * 12, GROUND + 21, gateZ), Enum.Material.Glass, 0.15)
	end
	decor({
		Name = "ArchTop",
		Size = Vector3.new(24, 3, 3),
		Position = Vector3.new(0, GROUND + 21, gateZ),
		Color = WHITE,
		Parent = gate,
	})

	-- the glowing pad you stand on to unlock
	local button = part({
		Name = "Button",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 8, 8),
		CFrame = CFrame.new(0, GROUND + 0.3, gateZ + 7) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 225, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = gate,
	})

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
	local base = Config.ZoneCenter(egg.Zone) + EGG_OFFSET + Vector3.new(0, GROUND, 0)

	local model = Instance.new("Model")
	model.Name = egg.Name

	-- a white cake-stand pedestal with a glowing ring
	decor({
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.5, 10, 10),
		CFrame = CFrame.new(base + Vector3.new(0, 1.25, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = WHITE,
		Material = Enum.Material.Marble,
		Parent = model,
	}).CanCollide = true
	decor({
		Name = "Ring",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 10.6, 10.6),
		CFrame = CFrame.new(base + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = egg.Color,
		Material = Enum.Material.Neon,
		Parent = model,
	})

	-- the egg itself: a stretched ball with spots and a shine
	local eggCenter = base + Vector3.new(0, 6.2, 0)
	local eggPart = part({
		Name = "Egg",
		Size = Vector3.new(5, 6.4, 5),
		Position = eggCenter,
		Color = egg.Color,
		CanCollide = false,
		Parent = model,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = eggPart

	local random = Random.new(eggIndex)
	for _ = 1, 9 do
		-- put a spot somewhere on the egg's surface
		local angle = random:NextNumber(0, math.pi * 2)
		local height = random:NextNumber(-0.6, 0.7)
		local ring = math.sqrt(1 - height * height)
		local spot = eggCenter + Vector3.new(math.sin(angle) * ring * 2.45, height * 3.15, math.cos(angle) * ring * 2.45)
		local size = random:NextNumber(0.6, 1.1)
		ball(model, Vector3.new(size, size, size * 0.4), egg.SpotColor, CFrame.lookAt(spot, eggCenter))
	end
	ball(model, Vector3.new(0.5, 1.6, 0.3), WHITE, CFrame.new(eggCenter + Vector3.new(-1.3, 1.2, -2)) * CFrame.Angles(0, math.rad(-30), math.rad(15)), Enum.Material.Neon, 0.3)

	local glow = Instance.new("PointLight")
	glow.Color = egg.Color
	glow.Range = 14
	glow.Brightness = 1.5
	glow.Parent = eggPart

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(egg.Color)
	sparkles.Size = NumberSequence.new(0.4)
	sparkles.Rate = 6
	sparkles.Lifetime = NumberRange.new(1, 1.5)
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.LightEmission = 1
	sparkles.Parent = eggPart

	-- sign: egg name, price and the chance of every pet
	local lines = {
		{ Text = egg.Name, Color = egg.Color, Size = 1.4 },
		{ Text = Format.Short(egg.Price) .. " Jelly", Color = Color3.fromRGB(255, 230, 120), Size = 1.1 },
	}
	for _, entry in egg.Pets do
		local petName, chance = entry[1], entry[2]
		local rarity = Config.Pets[petName].Rarity
		table.insert(lines, {
			Text = string.format("%s  •  %s%%", petName, tostring(chance)),
			Color = Config.RarityColors[rarity],
			Size = 0.8,
		})
	end
	sign(eggPart, lines, 10, 80)

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
	local frontZ = half
	local backZ = -(zoneCount - 1) * Config.ZoneSize - half
	local midZ = (frontZ + backZ) / 2

	local fences = Instance.new("Folder")
	fences.Name = "Fences"
	fences.Parent = world

	-- invisible walls keep everyone inside
	for i, info in {
		{ Size = Vector3.new(2, 30, length), Position = Vector3.new(-half - 1, 15, midZ) },
		{ Size = Vector3.new(2, 30, length), Position = Vector3.new(half + 1, 15, midZ) },
		{ Size = Vector3.new(Config.ZoneSize + 4, 30, 2), Position = Vector3.new(0, 15, frontZ + 1) },
		{ Size = Vector3.new(Config.ZoneSize + 4, 30, 2), Position = Vector3.new(0, 15, backZ - 1) },
	} do
		part({ Name = "Wall" .. i, Size = info.Size, Position = info.Position, Transparency = 1, CanQuery = false, Parent = fences })
	end

	-- a cute row of gumdrops along the walls you can see
	local colors = { Color3.fromRGB(255, 150, 200), Color3.fromRGB(170, 220, 255), Color3.fromRGB(255, 230, 130), Color3.fromRGB(190, 160, 255) }
	local count = 0
	local function post(x: number, z: number)
		count += 1
		ball(fences, Vector3.new(3, 3.4, 3), colors[count % #colors + 1], CFrame.new(x, GROUND + 1.4, z), Enum.Material.Glass, 0.15)
	end
	for z = backZ, frontZ, 6 do
		post(-half, z)
		post(half, z)
	end
	for x = -half + 6, half - 6, 6 do
		post(x, frontZ)
		post(x, backZ)
	end
end

-- Builds everything and returns the prompts so Main can listen to them.
function WorldBuilder.Build()
	setupLighting()

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

	-- a round pink pad where players appear
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "JellySpawn"
	spawn.Anchored = true
	spawn.Shape = Enum.PartType.Cylinder
	spawn.Size = Vector3.new(1, 12, 12)
	spawn.CFrame = CFrame.new(Config.ZoneCenter(1) + Vector3.new(0, GROUND + 0.3, 30)) * CFrame.Angles(0, 0, math.rad(90))
	spawn.Color = Color3.fromRGB(255, 160, 210)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Duration = 0 -- no spawn forcefield
	spawn.Parent = world

	-- remove the grey spawn pad that comes with a new Baseplate place
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	-- hide the plain baseplate under our map, if the place has one
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(255, 210, 230)
		baseplate.Material = Enum.Material.SmoothPlastic
		local texture = baseplate:FindFirstChildOfClass("Texture")
		if texture then
			texture:Destroy()
		end
	end

	world.Parent = workspace
	return {
		GatePrompts = gatePrompts,
		EggPrompts = eggPrompts,
	}
end

-- A random spot on top of a zone's floor, away from the edges, gates and the egg.
function WorldBuilder.RandomSpot(zoneIndex: number, random: Random): Vector3
	local center = Config.ZoneCenter(zoneIndex)
	local half = Config.ZoneSize / 2 - 14
	for _ = 1, 10 do
		local offset = Vector3.new(random:NextNumber(-half, half), 0, random:NextNumber(-half, half))
		if (offset - EGG_OFFSET).Magnitude > 10 then
			return center + offset + Vector3.new(0, GROUND, 0)
		end
	end
	return center + Vector3.new(0, GROUND, 0)
end

return WorldBuilder
