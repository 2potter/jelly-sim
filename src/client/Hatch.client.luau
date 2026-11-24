--[[
	Hatch: the egg hatching animation!
	The egg pops up, wobbles faster and faster, flashes, and your new pet appears.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Ui.new("ScreenGui", {
	Name = "Hatch",
	ResetOnSpawn = false,
	DisplayOrder = 10, -- on top of the other menus
	IgnoreGuiInset = true,
	Parent = player:WaitForChild("PlayerGui"),
})

local function tween(instance: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	local t = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

local queue: { { string | number } } = {}
local playing = false

local function playHatch(petName: string, eggIndex: number)
	local egg = Config.Eggs[eggIndex]
	local info = Config.Pets[petName]
	local rarityColor = Config.RarityColors[info.Rarity]

	-- dark background
	local dim = Ui.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	tween(dim, 0.2, { BackgroundTransparency = 0.45 })

	-- the egg (a tall rounded box looks just like an egg!)
	local eggFrame = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = egg and egg.Color or Ui.Pink,
		Parent = dim,
	})
	Ui.round(eggFrame, 0.5, 0)
	Ui.outline(eggFrame, Ui.Dark, 5)
	-- white spots on the egg
	for _, spot in { { 0.3, 0.3, 30 }, { 0.65, 0.55, 22 }, { 0.4, 0.75, 16 } } do
		local dot = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(spot[1], spot[2]),
			Size = UDim2.fromOffset(spot[3], spot[3]),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.3,
			Parent = eggFrame,
		})
		Ui.round(dot, 0.5, 0)
	end

	tween(eggFrame, 0.35, { Size = UDim2.fromOffset(170, 215) }, Enum.EasingStyle.Back).Completed:Wait()

	-- wobble, faster and faster
	for _, speed in { 0.14, 0.1, 0.07, 0.05 } do
		for _, angle in { -18, 18 } do
			tween(eggFrame, speed, { Rotation = angle }).Completed:Wait()
		end
	end
	eggFrame.Rotation = 0

	-- flash!
	local flash = Ui.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		Parent = dim,
	})
	eggFrame:Destroy()
	tween(flash, 0.4, { BackgroundTransparency = 1 })

	-- the new pet, spinning
	local viewport, model = Ui.petViewport(petName, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(260, 260),
		Parent = dim,
	})
	local spin = RunService.RenderStepped:Connect(function(dt)
		model:PivotTo(model:GetPivot() * CFrame.Angles(0, dt * 2, 0))
	end)

	local text = Ui.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.45, 140),
		Size = UDim2.fromOffset(500, 44),
		Text = petName,
		TextColor3 = rarityColor,
		Parent = dim,
	})
	Ui.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.45, 186),
		Size = UDim2.fromOffset(300, 30),
		Text = info.Rarity .. "!",
		TextColor3 = rarityColor,
		Parent = dim,
	})

	task.wait(1.6)
	spin:Disconnect()
	viewport.Visible = false
	text.Visible = false
	dim:Destroy()
end

remotes:WaitForChild("Hatched").OnClientEvent:Connect(function(petName: string, eggIndex: number)
	table.insert(queue, { petName, eggIndex })
	if playing then
		return
	end
	playing = true
	while #queue > 0 do
		local nextHatch = table.remove(queue, 1) :: { any }
		playHatch(nextHatch[1], nextHatch[2])
	end
	playing = false
end)
