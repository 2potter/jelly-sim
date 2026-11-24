--[[
	Hud: the always-on-screen stuff.
	  - Jelly counter in the top-left
	  - messages at the top of the screen
	  - "+15" popups and flying jelly bits when you pop a blob
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Format = require(ReplicatedStorage.Shared.Format)
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Ui.new("ScreenGui", {
	Name = "Hud",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

---------------------------------------------------------------------
-- Jelly counter
---------------------------------------------------------------------
local counter = Ui.new("Frame", {
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.fromOffset(220, 56),
	BackgroundColor3 = Ui.Pink,
	Parent = gui,
})
Ui.round(counter, 0.5, 0)
Ui.outline(counter)
Ui.gloss(counter)
local counterScale = Ui.new("UIScale", { Parent = counter })

Ui.label({
	Text = "🍮",
	Position = UDim2.fromOffset(8, 6),
	Size = UDim2.fromOffset(44, 44),
	Parent = counter,
})
local jellyText = Ui.label({
	Text = "0",
	Position = UDim2.fromOffset(56, 8),
	Size = UDim2.new(1, -70, 1, -16),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = counter,
})

local BOUNCE = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local lastJelly = 0

local function showJelly(value: number)
	jellyText.Text = Format.Short(value)
	if value > lastJelly then
		counterScale.Scale = 1.12
		TweenService:Create(counterScale, BOUNCE, { Scale = 1 }):Play()
	end
	lastJelly = value
end

task.spawn(function()
	local jelly = player:WaitForChild("leaderstats"):WaitForChild("Jelly")
	lastJelly = jelly.Value
	showJelly(jelly.Value)
	jelly.Changed:Connect(showJelly)
end)

---------------------------------------------------------------------
-- Messages at the top of the screen
---------------------------------------------------------------------
local message = Ui.label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 20),
	Size = UDim2.new(0.6, 0, 0, 36),
	Text = "",
	Visible = false,
	Parent = gui,
})
local messageId = 0

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text: string, color: Color3)
	messageId += 1
	local myId = messageId
	message.Text = text
	message.TextColor3 = color
	message.TextTransparency = 0
	message.Visible = true
	task.delay(3, function()
		if messageId == myId then
			message.Visible = false
		end
	end)
end)

---------------------------------------------------------------------
-- Rewards: "+15" text and little jelly bits that fly to you
---------------------------------------------------------------------
local RISE = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLY = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- a little splash of jelly where the blob popped
local function splash(position: Vector3, color: Color3)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = position
	holder.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.3
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new(0.2)
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Enabled = false
	emitter.Parent = holder
	emitter:Emit(24)
	Debris:AddItem(holder, 1)
end

local function flyingBits(fromPosition: Vector3, color: Color3)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _ = 1, 6 do
		local bit = Instance.new("Part")
		bit.Shape = Enum.PartType.Ball
		bit.Size = Vector3.new(0.8, 0.8, 0.8)
		bit.Color = color
		bit.Material = Enum.Material.Neon
		bit.Anchored = true
		bit.CanCollide = false
		bit.CanQuery = false
		bit.CanTouch = false
		bit.Position = fromPosition + Vector3.new(math.random(-20, 20) / 10, math.random(0, 20) / 10, math.random(-20, 20) / 10)
		bit.Parent = workspace
		task.delay(math.random() * 0.25, function()
			TweenService:Create(bit, FLY, { Position = root.Position, Size = Vector3.new(0.2, 0.2, 0.2) }):Play()
		end)
		Debris:AddItem(bit, 0.8)
	end
end

remotes:WaitForChild("Reward").OnClientEvent:Connect(function(amount: number, position: Vector3, color: Color3)
	splash(position, color)
	flyingBits(position, color)

	local popup = Ui.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.2, 0, 0.72, 0),
		Size = UDim2.fromOffset(160, 40),
		Text = "+" .. Format.Short(amount) .. " 🍮",
		TextColor3 = Color3.fromRGB(255, 235, 120),
		Parent = gui,
	})
	TweenService:Create(popup, RISE, {
		Position = popup.Position - UDim2.fromScale(0, 0.12),
		TextTransparency = 1,
	}):Play()
	Debris:AddItem(popup, 1.1)
end)
