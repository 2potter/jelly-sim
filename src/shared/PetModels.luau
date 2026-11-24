--[[
	PetModels: builds a cute jelly pet out of simple parts.
	The server uses it for the pets that follow you, and the client
	uses it to show your new pet when an egg hatches.

	The pet faces forward along -Z (that's "LookVector" in Roblox).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PetModels = {}

local function makePart(model: Model, name: string, shape: Enum.PartType, size: Vector3, color: Color3, offset: CFrame)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = offset
	part.Parent = model
	return part
end

function PetModels.Build(petName: string): Model
	local info = Config.Pets[petName]
	assert(info, "Unknown pet: " .. tostring(petName))

	local model = Instance.new("Model")
	model.Name = petName

	-- The squishy jelly body
	local body = makePart(model, "Body", Enum.PartType.Ball, Vector3.new(2.6, 2.6, 2.6), info.Color, CFrame.new())
	body.Material = Enum.Material.Glass
	body.Transparency = 0.2
	model.PrimaryPart = body

	-- A shiny highlight on top makes it look wet and jelly-like
	makePart(model, "Shine", Enum.PartType.Ball, Vector3.new(0.6, 0.6, 0.6), Color3.new(1, 1, 1), CFrame.new(-0.55, 0.75, -0.75)).Material =
		Enum.Material.Neon

	-- Eyes
	for _, side in { -1, 1 } do
		makePart(model, "Eye", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(25, 25, 35), CFrame.new(side * 0.5, 0.25, -1.15))
	end

	-- Extra shapes so pets look different from each other
	if info.Look == "Ears" then
		for _, side in { -1, 1 } do
			makePart(model, "Ear", Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8), info.Color, CFrame.new(side * 0.8, 1.2, 0))
		end
	elseif info.Look == "Horn" then
		local horn = makePart(model, "Horn", Enum.PartType.Block, Vector3.new(0.35, 1.1, 0.35), Color3.fromRGB(255, 245, 200), CFrame.new(0, 1.55, -0.3) * CFrame.Angles(math.rad(-20), 0, 0))
		horn.Material = Enum.Material.Neon
	elseif info.Look == "Crown" then
		local crown = makePart(model, "Crown", Enum.PartType.Cylinder, Vector3.new(0.5, 1.4, 1.4), Color3.fromRGB(255, 210, 40), CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)))
		crown.Material = Enum.Material.Neon
	end

	-- The best pets sparkle!
	local rank = Config.RarityRank(info.Rarity)
	if rank >= Config.RarityRank("Legendary") then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(Config.RarityColors[info.Rarity])
		sparkles.Size = NumberSequence.new(0.4)
		sparkles.Rate = 8
		sparkles.Lifetime = NumberRange.new(0.6, 1)
		sparkles.Speed = NumberRange.new(1, 2)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = body
	end
	if rank >= Config.RarityRank("Epic") then
		local glow = Instance.new("PointLight")
		glow.Color = info.Color
		glow.Range = 8
		glow.Brightness = 1.5
		glow.Parent = body
	end

	return model
end

return PetModels
