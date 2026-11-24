--[[
	PetModels: builds the jelly pudding pets out of parts.

	Each pet looks like a wobbly jelly pudding: a see-through ridged dome,
	whipped cream on top, a topping (cherry, berry, lemon...), and a cute
	face with dot eyes and a little "ω" mouth.

	Every part is welded to the "Body" part, so moving the Body moves the
	whole pet. The pet faces forward along -Z (Roblox's LookVector).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PetModels = {}

local GLASS = Enum.Material.Glass
local PLASTIC = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local BLACK = Color3.fromRGB(30, 20, 35)
local WHITE = Color3.new(1, 1, 1)

export type PuddingOptions = {
	Color: Color3,
	Colors: { Color3 }?, -- stripes: each ridge takes the next color
	Cream: Color3?, -- nil = no cream
	Topping: string?, -- "Cherry", "Berry", "Lemon", "Bean", "Star", "Crown"
	Stars: boolean?, -- glitter stars inside
	Face: boolean?, -- eyes, mouth and blush made of parts (shows in menus)
	DrawnFace: boolean?, -- eyes, mouth and blush drawn with a SurfaceGui (crisper, used in the world)
	Rarity: string?, -- adds glow, sparkles and a halo for rare ones
	Scale: number?, -- 1 = pet size (about 3 studs tall)
	Transparency: number?,
}

-- Makes a part shaped like a ball or an egg (a "sphere mesh" stretched to the part's size).
local function blob(model: Model, name: string, size: Vector3, color: Color3, cframe: CFrame, material: Enum.Material?, transparency: number?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or PLASTIC
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.CFrame = cframe
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	part.Parent = model
	return part
end

local function block(model: Model, name: string, size: Vector3, color: Color3, cframe: CFrame, material: Enum.Material?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.Color = color
	part.Material = material or PLASTIC
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.CFrame = cframe
	part.Parent = model
	return part
end

local function addTopping(model: Model, kind: string, s: number, y: number)
	local function at(x: number, py: number, z: number): CFrame
		return CFrame.new(x * s, py * s, z * s)
	end
	local v = function(x: number, py: number, z: number): Vector3
		return Vector3.new(x, py, z) * s
	end

	if kind == "Cherry" then
		blob(model, "Cherry", v(0.8, 0.75, 0.8), Color3.fromRGB(235, 40, 70), at(0, y + 0.3, 0), GLASS, 0.05)
		blob(model, "CherryShine", v(0.18, 0.18, 0.1), WHITE, at(-0.18, y + 0.45, -0.33), NEON, 0.2)
		block(model, "Stem", v(0.1, 0.7, 0.1), Color3.fromRGB(255, 255, 255), at(0.08, y + 0.9, 0) * CFrame.Angles(0, 0, math.rad(-18)))
	elseif kind == "Berry" then
		for i, offset in { { -0.22, 0, 0.1 }, { 0.22, 0, 0.1 }, { 0, 0.05, -0.2 }, { 0, 0.35, 0 } } do
			blob(model, "Berry" .. i, v(0.45, 0.45, 0.45), Color3.fromRGB(70, 50, 170), at(offset[1], y + 0.2 + offset[2], offset[3]), GLASS, 0.05)
		end
	elseif kind == "Lemon" then
		-- a lemon slice standing up in the cream
		block(model, "Lemon", v(0.18, 1, 1), Color3.fromRGB(255, 220, 40), at(0, y + 0.35, 0) * CFrame.Angles(0, math.rad(90), 0), PLASTIC, Enum.PartType.Cylinder)
		block(model, "LemonInside", v(0.2, 0.8, 0.8), Color3.fromRGB(255, 250, 170), at(0, y + 0.35, 0) * CFrame.Angles(0, math.rad(90), 0), PLASTIC, Enum.PartType.Cylinder)
	elseif kind == "Bean" then
		blob(model, "Bean1", v(0.6, 0.35, 0.45), Color3.fromRGB(120, 40, 50), at(-0.15, y + 0.12, 0) * CFrame.Angles(0, math.rad(30), 0))
		blob(model, "Bean2", v(0.55, 0.35, 0.4), Color3.fromRGB(110, 35, 45), at(0.2, y + 0.18, 0.1) * CFrame.Angles(0, math.rad(-40), 0))
	elseif kind == "Star" then
		-- a glowing four-point sparkle
		local starColor = Color3.fromRGB(255, 240, 120)
		local center = at(0, y + 0.55, 0)
		block(model, "StarA", v(0.22, 1, 0.12), starColor, center, NEON)
		block(model, "StarB", v(0.22, 1, 0.12), starColor, center * CFrame.Angles(0, 0, math.rad(90)), NEON)
		block(model, "StarC", v(0.16, 0.6, 0.1), starColor, center * CFrame.Angles(0, 0, math.rad(45)), NEON)
		block(model, "StarD", v(0.16, 0.6, 0.1), starColor, center * CFrame.Angles(0, 0, math.rad(-45)), NEON)
	elseif kind == "Crown" then
		local gold = Color3.fromRGB(255, 200, 50)
		block(model, "CrownBase", v(0.35, 1.1, 1.1), gold, at(0, y + 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Foil, Enum.PartType.Cylinder)
		for i = 1, 5 do
			local angle = i / 5 * math.pi * 2
			blob(model, "CrownTip" .. i, v(0.22, 0.32, 0.22), gold, at(math.sin(angle) * 0.45, y + 0.45, -math.cos(angle) * 0.45), Enum.Material.Foil)
		end
		blob(model, "Gem", v(0.22, 0.22, 0.12), Color3.fromRGB(255, 60, 110), at(0, y + 0.15, -0.55), NEON)
	end
end

-- The face sits on a smooth egg-shaped bump on the front of the jelly.
-- These numbers describe that bump (at Scale 1).
local FACE_Y = 0.3 -- height of the bump's center
local PLATE_Z = -1.1 -- how far forward its center is
local PLATE_A, PLATE_B, PLATE_C = 1.1, 1.0, 0.45 -- half its width, height and depth

-- How far forward the bump's surface is at a spot (x, y) on the front.
local function surfaceZ(x: number, y: number): number
	local inside = 1 - (x / PLATE_A) ^ 2 - ((y - FACE_Y) / PLATE_B) ^ 2
	return PLATE_Z - PLATE_C * math.sqrt(math.max(inside, 0))
end

-- Draws the face (eyes, blush, ω mouth) on the front of a flat part.
local function drawFace(canvas: BasePart)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerUnit
	gui.PixelsPerUnit = 100
	gui.LightInfluence = 0.3
	gui.Parent = canvas

	local function shape(name: string, x: number, y: number, w: number, h: number, color: Color3, transparency: number?): Frame
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(x, y)
		frame.Size = UDim2.fromScale(w, h)
		frame.BackgroundColor3 = color
		frame.BackgroundTransparency = transparency or 0
		frame.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
		frame.Parent = gui
		return frame
	end

	for _, x in { 0.27, 0.73 } do
		local eye = shape("Eye", x, 0.3, 0.13, 0.22, BLACK)
		local shine = shape("Shine", 0.35, 0.3, 0.35, 0.3, WHITE)
		shine.Parent = eye
		shape("Blush", x + (x - 0.5) * 0.75, 0.55, 0.2, 0.1, Color3.fromRGB(255, 110, 150), 0.35)
	end

	-- the "ω" mouth: two little "u" cups side by side
	for _, x in { 0.445, 0.555 } do
		local holder = Instance.new("Frame")
		holder.Name = "MouthHalf"
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.Position = UDim2.fromScale(x, 0.52)
		holder.Size = UDim2.fromScale(0.12, 0.09)
		holder.BackgroundTransparency = 1
		holder.ClipsDescendants = true -- only the bottom half of the ring shows
		holder.Parent = gui

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0)
		ring.Size = UDim2.new(1, -4, 2, -4)
		ring.BackgroundTransparency = 1
		ring.Parent = holder
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = ring
		local stroke = Instance.new("UIStroke")
		stroke.Color = BLACK
		stroke.Thickness = 3
		stroke.Parent = ring
	end
end

-- Builds a jelly pudding. Used for pets (with a face) and for the big jelly blobs.
function PetModels.Pudding(options: PuddingOptions): Model
	local s = options.Scale or 1
	local jellyT = options.Transparency or 0.3
	local colors = options.Colors or { options.Color }

	local model = Instance.new("Model")
	model.Name = "Pudding"

	local function at(x: number, y: number, z: number): CFrame
		return CFrame.new(x * s, y * s, z * s)
	end
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z) * s
	end

	-- the jelly core
	local body = blob(model, "Body", v(2.6, 2.3, 2.6), options.Color, CFrame.new(), GLASS, jellyT + 0.05)
	model.PrimaryPart = body

	-- ridges going up the sides, leaning in at the top like a pudding mold,
	-- and a wavy "skirt" at the bottom
	local ridges = 9
	for i = 1, ridges do
		local angle = (i - 0.5) / ridges * math.pi * 2
		local dir = Vector3.new(math.sin(angle), 0, -math.cos(angle))
		local color = colors[(i - 1) % #colors + 1]

		local ridgePos = dir * 1.05 * s + Vector3.new(0, -0.05 * s, 0)
		blob(model, "Ridge", v(0.95, 2.3, 0.95), color, CFrame.lookAt(ridgePos, ridgePos + dir) * CFrame.Angles(math.rad(12), 0, 0), GLASS, jellyT)

		local skirtPos = dir * 1.38 * s + Vector3.new(0, -0.85 * s, 0)
		blob(model, "Skirt", v(1.15, 0.7, 1), color, CFrame.lookAt(skirtPos, skirtPos + dir), GLASS, jellyT)
	end

	-- the flat-ish top of the jelly
	blob(model, "Top", v(1.9, 0.7, 1.9), colors[1], at(0, 1.05, 0), GLASS, jellyT)

	-- shiny reflections make it look wet and squishy
	blob(model, "Shine", v(0.28, 0.9, 0.12), WHITE, at(-1.0, 0.65, -1.25) * CFrame.Angles(0, math.rad(-40), math.rad(12)), NEON, 0.35)
	blob(model, "Shine2", v(0.18, 0.18, 0.1), WHITE, at(0.85, 0.85, -1.22), NEON, 0.3)

	-- whipped cream swirl
	local toppingY = 1.45
	if options.Cream then
		for i = 1, 7 do
			local angle = i / 7 * math.pi * 2
			blob(model, "Cream", v(0.62, 0.55, 0.62), options.Cream, at(math.sin(angle) * 0.62, 1.42, -math.cos(angle) * 0.62))
		end
		blob(model, "Cream", v(0.95, 0.75, 0.95), options.Cream, at(0, 1.6, 0))
		blob(model, "Cream", v(0.5, 0.45, 0.5), options.Cream, at(0, 1.95, 0))
		toppingY = 1.95
	end

	if options.Topping then
		addTopping(model, options.Topping, s, toppingY)
	end

	-- glitter stars floating inside the jelly
	if options.Stars then
		local spots = { { -0.5, -0.3, -0.6 }, { 0.6, 0.1, -0.4 }, { 0.1, -0.6, 0.6 }, { -0.4, 0.5, 0.3 }, { 0.5, -0.5, 0.2 }, { -0.1, 0.2, -0.9 } }
		local starColors = { Color3.fromRGB(255, 255, 200), Color3.fromRGB(200, 230, 255), Color3.fromRGB(255, 210, 240) }
		for i, spot in spots do
			block(model, "Glitter", v(0.2, 0.2, 0.2), starColors[(i - 1) % #starColors + 1], at(spot[1], spot[2], spot[3]) * CFrame.Angles(0, 0, math.rad(45)), NEON)
		end
	end

	-- the cute face: dot eyes, blush and an "ω" mouth
	if options.Face or options.DrawnFace then
		-- a smooth jelly bump on the front, so the face sits on a smooth surface
		blob(model, "FacePlate", v(PLATE_A * 2, PLATE_B * 2, PLATE_C * 2), colors[1], at(0, FACE_Y, PLATE_Z), GLASS, jellyT)

		if options.DrawnFace then
			-- drawn on a flat see-through sheet stuck to the front (looks crisp in the game)
			local canvas = block(model, "FaceCanvas", v(1.6, 1.2, 0.05), WHITE, at(0, FACE_Y + 0.05, surfaceZ(0, FACE_Y) - 0.01))
			canvas.Transparency = 1
			drawFace(canvas)
		else
			-- built from tiny parts that sit right on the surface (works inside menus too)
			local function onSurface(name: string, size: Vector3, color: Color3, x: number, y: number, material: Enum.Material?, transparency: number?)
				local z = surfaceZ(x, y)
				local point = Vector3.new(x, y, z)
				-- the direction straight out of the bump at this spot
				local normal = Vector3.new(x / PLATE_A ^ 2, (y - FACE_Y) / PLATE_B ^ 2, (z - PLATE_Z) / PLATE_C ^ 2).Unit
				local cframe = CFrame.lookAt(point * s, point * s - normal) -- flat side lies on the jelly
				blob(model, name, size * s, color, cframe, material, transparency)
			end
			for _, side in { -1, 1 } do
				onSurface("Eye", Vector3.new(0.22, 0.28, 0.06), BLACK, side * 0.38, 0.5)
				onSurface("EyeShine", Vector3.new(0.08, 0.08, 0.07), WHITE, side * 0.38 - 0.05, 0.57, NEON)
				onSurface("Blush", Vector3.new(0.34, 0.16, 0.05), Color3.fromRGB(255, 110, 150), side * 0.72, 0.2, PLASTIC, 0.25)
				-- each half of the "ω" is a little bottom-half circle of dots
				local centerX = side * 0.15
				for k = 0, 4 do
					local t = math.pi + k / 4 * math.pi
					onSurface("Mouth", Vector3.new(0.08, 0.08, 0.05), BLACK, centerX + math.cos(t) * 0.14, 0.12 + math.sin(t) * 0.14)
				end
			end
		end
	end

	-- extra shine for rare pets
	local rank = Config.RarityRank(options.Rarity or "Common")
	if rank >= Config.RarityRank("Epic") then
		local glow = Instance.new("PointLight")
		glow.Color = options.Color
		glow.Range = 9
		glow.Brightness = 1.5
		glow.Parent = body
	end
	if rank >= Config.RarityRank("Legendary") then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(Config.RarityColors[options.Rarity :: string])
		sparkles.Size = NumberSequence.new(0.35 * s)
		sparkles.Rate = 10
		sparkles.Lifetime = NumberRange.new(0.6, 1.2)
		sparkles.Speed = NumberRange.new(1, 2.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.LightEmission = 1
		sparkles.Parent = body
	end
	if rank >= Config.RarityRank("Mythical") then
		for i = 1, 12 do
			local angle = i / 12 * math.pi * 2
			blob(model, "Halo", v(0.2, 0.2, 0.2), Color3.fromRGB(255, 250, 200), at(math.sin(angle) * 0.85, 3.05, -math.cos(angle) * 0.85), NEON)
		end
	end

	-- weld everything to the body, so moving the body moves the whole pudding
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
			part.Anchored = false
		end
	end

	return model
end

-- How far below the Body's center the bottom of the pudding is (at Scale 1).
PetModels.BottomOffset = 1.2

-- Builds the pet with this name from Config.Pets.
-- scale makes it bigger or smaller (1 = normal).
-- drawnFace = true draws the face with a SurfaceGui (sharper in the world,
-- but SurfaceGuis don't show inside menus, so menus use the part face).
function PetModels.Build(petName: string, scale: number?, drawnFace: boolean?): Model
	local info = Config.Pets[petName]
	assert(info, "Unknown pet: " .. tostring(petName))

	local model = PetModels.Pudding({
		Color = info.Color,
		Colors = info.Colors,
		Cream = info.Cream,
		Topping = info.Topping,
		Stars = info.Stars,
		Face = not drawnFace,
		DrawnFace = drawnFace,
		Rarity = info.Rarity,
		Scale = scale,
	})
	model.Name = petName
	return model
end

return PetModels
