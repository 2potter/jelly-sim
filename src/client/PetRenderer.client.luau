--[[
	PetRenderer: draws and animates EVERY player's pets on your screen.

	The server only says which pets each player has (the "EquippedPets"
	attribute) and which blob they attack (player.PetTarget). Doing the
	animation here, on your own computer, makes it smooth with no lag.

	How a pet moves:
	  - it always stands on the ground (a ray finds the floor under it)
	  - it glides smoothly after you with a soft little waddle
	  - standing still, it gently breathes up and down
	  - when its owner jumps, all the pets jump too and jiggle when they land
	  - when attacking a blob, it hops on the spot next to it
	  - its name floats above it in its rarity color

	Tweak the numbers below to change how pets feel!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local PetModels = require(ReplicatedStorage.Shared.PetModels)

local PET_SCALE = 0.85 -- how big pets are (about knee-to-waist high on your avatar)
local SPACING = 3.4 -- space between pets walking behind you
local FOLLOW_DISTANCE = 5 -- how far behind you they walk
local RUN_SPEED = 36 -- fastest a pet can move (studs per second)
local SMOOTHING = 7 -- how quickly pets speed up and slow down (lower = smoother)
local WADDLE_HEIGHT = 0.25 -- how much pets bob while walking
local WADDLE_SQUISH = 0.03 -- how much pets squish while walking
local GRAVITY = 95
local ATTACK_HOP_SPEED = 14 -- upward speed of an attack hop
local JUMP_SPEED = 30 -- upward speed when the owner jumps
local LAND_PAUSE = 0.1 -- tiny pause between attack hops
local SPRING = 220 -- how stiff the jelly is (higher = faster wobble)
local DAMPING = 14 -- how quickly the wobble calms down (lower = wobblier)
local TELEPORT_DISTANCE = 90 -- pets further away than this just appear next to you

local BOTTOM = PetModels.BottomOffset * PET_SCALE

local folder = Instance.new("Folder")
folder.Name = "PetsOnMyScreen"
folder.Parent = workspace

type PartInfo = { Offset: CFrame, Mesh: SpecialMesh? }
type Pet = {
	Model: Model,
	Shadow: BasePart,
	PartList: { BasePart },
	Infos: { PartInfo },
	CFrames: { CFrame },
	Position: Vector3, -- the spot on the ground under the pet
	Velocity: Vector3, -- how fast it's sliding along the ground
	WalkPhase: number, -- where it is in its waddle
	GroundY: number,
	Height: number, -- how high it is in the air
	VelocityY: number,
	Grounded: boolean,
	LandedAt: number,
	JumpAt: number?,
	Squash: number, -- + = stretched tall, - = squished flat
	SquashVelocity: number,
	LastScale: number,
	Yaw: number,
	Pitch: number,
	Seed: number,
	Warned: boolean?,
}
type Owner = { Pets: { Pet }, Names: string, LastVelocityY: number }

local owners: { [Player]: Owner } = {}

---------------------------------------------------------------------
-- Building pets
---------------------------------------------------------------------
local function setPose(pet: Pet, base: CFrame, stretch: number, squeeze: number)
	local scale = Vector3.new(squeeze, stretch, squeeze)
	for i, info in pet.Infos do
		local offset = info.Offset
		-- keep each part's rotation, but move it as if the pet were squished
		pet.CFrames[i] = base * ((offset - offset.Position) + offset.Position * scale)
	end
	workspace:BulkMoveTo(pet.PartList, pet.CFrames, Enum.BulkMoveMode.FireCFrameChanged)

	-- squish the round parts themselves (only when it changed, to save work)
	if math.abs(stretch - pet.LastScale) > 0.004 then
		pet.LastScale = stretch
		for _, info in pet.Infos do
			if info.Mesh then
				info.Mesh.Scale = scale
			end
		end
	end
end

local function buildPet(petName: string, position: Vector3): Pet?
	local ok, model = pcall(PetModels.Build, petName, PET_SCALE)
	if not ok then
		warn("[JellySim] Couldn't build pet " .. tostring(petName) .. ": " .. tostring(model))
		return nil
	end

	local body = model.PrimaryPart :: BasePart
	local bottom = body.CFrame * CFrame.new(0, -BOTTOM, 0)
	local pet: Pet = {
		Model = model,
		Shadow = nil :: any,
		PartList = {},
		Infos = {},
		CFrames = {},
		Position = position,
		Velocity = Vector3.zero,
		WalkPhase = 0,
		GroundY = position.Y,
		Height = 0,
		VelocityY = 0,
		Grounded = true,
		LandedAt = 0,
		JumpAt = nil,
		Squash = 0,
		SquashVelocity = 0,
		LastScale = 1,
		Yaw = 0,
		Pitch = 0,
		Seed = math.random() * 10,
	}

	for _, thing in model:GetDescendants() do
		if thing:IsA("WeldConstraint") then
			thing:Destroy() -- we move every part ourselves
		elseif thing:IsA("BasePart") then
			thing.Anchored = true
			table.insert(pet.PartList, thing)
			table.insert(pet.Infos, {
				Offset = bottom:ToObjectSpace(thing.CFrame),
				Mesh = thing:FindFirstChildOfClass("SpecialMesh"),
			})
		end
	end

	-- a soft round shadow on the ground under the pet (moved separately, so it stays on the floor)
	local shadow = Instance.new("Part")
	shadow.Name = "Shadow"
	shadow.Shape = Enum.PartType.Cylinder
	shadow.Size = Vector3.new(0.05, 2.6 * PET_SCALE, 2.6 * PET_SCALE)
	shadow.Color = Color3.new(0, 0, 0)
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Transparency = 0.65
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanQuery = false
	shadow.CanTouch = false
	shadow.CastShadow = false
	shadow.Parent = model
	pet.Shadow = shadow

	-- name tag floating above the pet
	local info = Config.Pets[petName]
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(140, 34)
	tag.StudsOffset = Vector3.new(0, 2.6 * PET_SCALE, 0)
	tag.MaxDistance = 45
	tag.LightInfluence = 0
	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.6)
	name.BackgroundTransparency = 1
	name.Text = petName
	name.TextScaled = true
	name.Font = Enum.Font.FredokaOne
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Parent = tag
	local rarity = Instance.new("TextLabel")
	rarity.Position = UDim2.fromScale(0, 0.6)
	rarity.Size = UDim2.fromScale(1, 0.4)
	rarity.BackgroundTransparency = 1
	rarity.Text = if info then info.Rarity else ""
	rarity.TextScaled = true
	rarity.Font = Enum.Font.FredokaOne
	rarity.TextColor3 = if info then Config.RarityColors[info.Rarity] else Color3.new(1, 1, 1)
	rarity.Parent = tag
	for _, label in { name, rarity } do
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(50, 25, 70)
		stroke.Thickness = 2
		stroke.Parent = label
	end
	tag.Parent = model.PrimaryPart

	setPose(pet, CFrame.new(position), 1, 1)
	model.Parent = folder
	return pet
end

local function clearPets(owner: Owner)
	for _, pet in owner.Pets do
		pet.Model:Destroy()
	end
	table.clear(owner.Pets)
end

local function rebuildPets(player: Player, owner: Owner)
	local names = player:GetAttribute("EquippedPets") or ""
	if names == owner.Names then
		return
	end
	owner.Names = names

	-- new pets pop out where the old ones were (or next to the player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local fallback = if root then root.Position - Vector3.new(0, 3, 0) else Vector3.zero
	local oldSpots = {}
	for i, pet in owner.Pets do
		oldSpots[i] = Vector3.new(pet.Position.X, pet.GroundY, pet.Position.Z)
	end
	clearPets(owner)

	local i = 0
	for petName in string.gmatch(names, "[^,]+") do
		i += 1
		local pet = buildPet(petName, oldSpots[i] or fallback)
		if pet then
			pet.VelocityY = JUMP_SPEED * 0.6 -- pop in with a little hop
			pet.Grounded = false
			table.insert(owner.Pets, pet)
		end
	end
end

local function watchPlayer(player: Player)
	local owner: Owner = { Pets = {}, Names = "", LastVelocityY = 0 }
	owners[player] = owner
	rebuildPets(player, owner)
	player:GetAttributeChangedSignal("EquippedPets"):Connect(function()
		rebuildPets(player, owner)
	end)
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in Players:GetPlayers() do
	watchPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	local owner = owners[player]
	if owner then
		clearPets(owner)
		owners[player] = nil
	end
end)

---------------------------------------------------------------------
-- Finding the ground
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function refreshRayFilter()
	local ignore: { Instance } = { folder }
	local blobs = workspace:FindFirstChild("Blobs")
	if blobs then
		table.insert(ignore, blobs)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	rayParams.FilterDescendantsInstances = ignore
end

local function groundHeight(x: number, z: number, fromY: number, fallback: number): number
	local hit = workspace:Raycast(Vector3.new(x, fromY + 6, z), Vector3.new(0, -80, 0), rayParams)
	return if hit then hit.Position.Y else fallback
end

---------------------------------------------------------------------
-- Animation
---------------------------------------------------------------------
local function yawToward(direction: Vector3): number
	-- the pet's face points along -Z, so this turns -Z toward the direction
	return math.atan2(-direction.X, -direction.Z)
end

local function turnToward(current: number, goal: number, alpha: number): number
	local difference = (goal - current + math.pi) % (math.pi * 2) - math.pi
	return current + difference * alpha
end

local function updatePet(pet: Pet, index: number, count: number, root: BasePart, target: BasePart?, ownerYaw: number, dt: number, now: number)
	-- where should this pet be?
	local goal: Vector3
	if target then
		local angle = index / count * math.pi * 2
		local radius = target.Size.X / 2 + 1.1 * PET_SCALE + 0.4
		goal = target.Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	else
		local spread = (index - (count + 1) / 2) * SPACING
		local behind = CFrame.new(root.Position) * CFrame.Angles(0, ownerYaw, 0)
		goal = (behind * CFrame.new(spread, 0, FOLLOW_DISTANCE + math.abs(spread) * 0.35)).Position
	end

	-- glide there smoothly: speed up and slow down gently
	local offset = Vector3.new(goal.X - pet.Position.X, 0, goal.Z - pet.Position.Z)
	local distance = offset.Magnitude
	if distance > TELEPORT_DISTANCE then
		pet.Position = Vector3.new(goal.X, root.Position.Y - 3, goal.Z)
		pet.GroundY = root.Position.Y - 3
		pet.Velocity = Vector3.zero
		offset = Vector3.zero
		distance = 0
	end
	local wantedVelocity = Vector3.zero
	if distance > 0.3 then
		local speed = math.min(distance * 3, RUN_SPEED) -- hurry when far behind, ease in when close
		wantedVelocity = offset.Unit * speed
	end
	pet.Velocity = pet.Velocity:Lerp(wantedVelocity, math.min(1, dt * SMOOTHING))
	pet.Position += pet.Velocity * dt

	local speed = pet.Velocity.Magnitude
	local moving = speed > 1.5
	local desiredYaw = ownerYaw
	if moving then
		desiredYaw = yawToward(pet.Velocity)
	elseif target then
		desiredYaw = yawToward(target.Position - pet.Position)
	end
	pet.Yaw = turnToward(pet.Yaw, desiredYaw, math.min(1, dt * 8))

	-- stick to the ground (smoothly, so steps don't snap)
	local ground = groundHeight(pet.Position.X, pet.Position.Z, math.max(root.Position.Y, pet.GroundY), root.Position.Y - 3)
	pet.GroundY += (ground - pet.GroundY) * math.min(1, dt * 18)

	-- jumping with the owner, and little hops while attacking
	local attacking = target ~= nil and distance < 1.5
	if pet.Grounded and now - pet.LandedAt > LAND_PAUSE then
		if pet.JumpAt and now >= pet.JumpAt then
			pet.VelocityY = JUMP_SPEED
			pet.Grounded = false
			pet.JumpAt = nil
		elseif attacking then
			pet.VelocityY = ATTACK_HOP_SPEED
			pet.Grounded = false
		end
	end
	if not pet.Grounded then
		pet.VelocityY -= GRAVITY * dt
		pet.Height += pet.VelocityY * dt
		if pet.Height <= 0 then
			-- land with a soft jelly wobble
			pet.SquashVelocity -= math.min(math.abs(pet.VelocityY) * 0.15, 4)
			pet.Height = 0
			pet.VelocityY = 0
			pet.Grounded = true
			pet.LandedAt = now
		end
	end

	-- a soft waddle while walking: tiny bob and squish, faster when running
	local walkAmount = math.clamp(speed / 12, 0, 1)
	pet.WalkPhase += dt * (6 + speed * 0.25)
	local waddle = math.abs(math.sin(pet.WalkPhase)) * WADDLE_HEIGHT * walkAmount

	-- jelly spring: squash and stretch
	local squashGoal
	if not pet.Grounded then
		squashGoal = math.clamp(math.abs(pet.VelocityY) / JUMP_SPEED * 0.15, 0, 0.12) -- stretch while flying
	elseif moving then
		squashGoal = math.sin(pet.WalkPhase * 2) * WADDLE_SQUISH * walkAmount
	else
		squashGoal = math.sin(now * 3 + pet.Seed) * 0.03 -- gentle breathing
	end
	local accel = -SPRING * (pet.Squash - squashGoal) - DAMPING * pet.SquashVelocity
	pet.SquashVelocity += accel * dt
	pet.Squash = math.clamp(pet.Squash + pet.SquashVelocity * dt, -0.25, 0.25)

	-- lean a little into the walk, sway gently side to side
	local pitchGoal = -0.08 * walkAmount
	pet.Pitch += (pitchGoal - pet.Pitch) * math.min(1, dt * 6)
	local roll = if moving then math.sin(pet.WalkPhase) * 0.05 * walkAmount else math.sin(now * 2 + pet.Seed) * 0.025

	local stretch = 1 + pet.Squash
	local squeeze = 1 - pet.Squash * 0.55 -- jelly gets wider when it squishes
	local base = CFrame.new(pet.Position.X, pet.GroundY + pet.Height + waddle, pet.Position.Z)
		* CFrame.Angles(0, pet.Yaw, 0)
		* CFrame.Angles(pet.Pitch, 0, roll)
	setPose(pet, base, stretch, squeeze)

	-- the shadow stays on the floor and fades a bit when the pet is up in the air
	local airHeight = pet.Height + waddle
	pet.Shadow.CFrame = CFrame.new(pet.Position.X, pet.GroundY + 0.04, pet.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
	pet.Shadow.Transparency = 0.65 + math.min(airHeight / 6, 0.25)
end

RunService.RenderStepped:Connect(function(frameTime)
	local dt = math.min(frameTime, 1 / 30) -- stay steady if the game hiccups
	local now = os.clock()
	refreshRayFilter()

	for player, owner in owners do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and #owner.Pets > 0 then
			local targetValue = player:FindFirstChild("PetTarget")
			local target = if targetValue and targetValue:IsA("ObjectValue") then targetValue.Value :: BasePart? else nil
			if target and not target.Parent then
				target = nil
			end

			-- when the owner jumps, the pets jump one after another
			local velocityY = root.AssemblyLinearVelocity.Y
			if velocityY > 15 and owner.LastVelocityY <= 15 and not target then
				for i, pet in owner.Pets do
					pet.JumpAt = now + (i - 1) * 0.05
				end
			end
			owner.LastVelocityY = velocityY

			local ownerYaw = select(2, root.CFrame:ToEulerAnglesYXZ())
			local count = #owner.Pets
			for i, pet in owner.Pets do
				local ok, err = pcall(updatePet, pet, i, count, root, target, ownerYaw, dt, now)
				-- if anything went wrong (or the pet got lost), put it back next to its owner
				local spot = pet.Position
				if not ok or spot.X ~= spot.X or spot.Y ~= spot.Y or spot.Z ~= spot.Z then
					if not ok and not pet.Warned then
						pet.Warned = true
						warn("[JellySim] Pet animation error: " .. tostring(err))
					end
					pet.Position = root.Position - Vector3.new(0, 3, 0)
					pet.GroundY = root.Position.Y - 3
					pet.Velocity = Vector3.zero
					pet.Height = 0
					pet.VelocityY = 0
					pet.Grounded = true
					pet.Squash = 0
					pet.SquashVelocity = 0
					pcall(setPose, pet, CFrame.new(pet.Position.X, pet.GroundY, pet.Position.Z), 1, 1)
				end
			end
		end
	end
end)
