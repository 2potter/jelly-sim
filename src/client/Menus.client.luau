--[[
	Menus: the buttons on the left side of the screen.
	  - Pets: see all your pets, click one to equip/unequip, X to delete
	  - Upgrades: spend Jelly to get stronger
	  - Auto: your pets find jelly blobs on their own
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Ui.new("ScreenGui", {
	Name = "Menus",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

---------------------------------------------------------------------
-- Left side buttons
---------------------------------------------------------------------
local sideBar = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(130, 200),
	BackgroundTransparency = 1,
	Parent = gui,
})
Ui.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sideBar })

local petsButton = Ui.button("🐾 Pets", Ui.Pink, { Size = UDim2.fromOffset(130, 50), LayoutOrder = 1, Parent = sideBar })
local upgradesButton = Ui.button("⬆️ Upgrades", Ui.Purple, { Size = UDim2.fromOffset(130, 50), LayoutOrder = 2, Parent = sideBar })
local autoButton = Ui.button("Auto: OFF", Color3.fromRGB(120, 120, 140), { Size = UDim2.fromOffset(130, 50), LayoutOrder = 3, Parent = sideBar })

local autoOn = false
autoButton.Activated:Connect(function()
	autoOn = not autoOn
	autoButton.Text = if autoOn then "Auto: ON" else "Auto: OFF"
	autoButton.BackgroundColor3 = if autoOn then Ui.Green else Color3.fromRGB(120, 120, 140)
	remotes.SetAuto:FireServer(autoOn)
end)

---------------------------------------------------------------------
-- A reusable window
---------------------------------------------------------------------
local function makeWindow(title: string, color: Color3): (Frame, Frame)
	local window = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0.65, 0),
		BackgroundColor3 = Color3.fromRGB(255, 240, 250),
		Visible = false,
		Parent = gui,
	})
	Ui.round(window, 0, 20)
	Ui.outline(window, Ui.Dark, 4)
	Ui.new("UISizeConstraint", { MinSize = Vector2.new(480, 260), MaxSize = Vector2.new(720, 520), Parent = window })

	local top = Ui.new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = color, Parent = window })
	Ui.round(top, 0, 20)
	Ui.gloss(top)
	Ui.label({ Name = "Title", Text = title, Position = UDim2.fromOffset(16, 8), Size = UDim2.new(0.4, 0, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, Parent = top })

	local close = Ui.button("X", Ui.Red, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(40, 40), Parent = top })
	close.Activated:Connect(function()
		window.Visible = false
	end)

	local body = Ui.new("ScrollingFrame", {
		Name = "Body",
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 1, -76),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window,
	})
	return window, body
end

local petsWindow, petsBody = makeWindow("🐾 Your Pets", Ui.Pink)
local upgradesWindow, upgradesBody = makeWindow("⬆️ Upgrades", Ui.Purple)

petsButton.Activated:Connect(function()
	upgradesWindow.Visible = false
	petsWindow.Visible = not petsWindow.Visible
end)
upgradesButton.Activated:Connect(function()
	petsWindow.Visible = false
	upgradesWindow.Visible = not upgradesWindow.Visible
end)

---------------------------------------------------------------------
-- Pets window
---------------------------------------------------------------------
local petsInfo = Ui.label({
	Text = "",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -170, 0, 12),
	Size = UDim2.fromOffset(170, 30),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = petsWindow,
})
local equipBest = Ui.button("Equip Best", Ui.Green, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -56, 0, 6),
	Size = UDim2.fromOffset(110, 40),
	Parent = petsWindow,
})
equipBest.Activated:Connect(function()
	remotes.EquipBest:FireServer()
end)

Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(110, 140),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = petsBody,
})

local spinning: { Model } = {}

local function showPets(pets: { { Name: string, Equipped: boolean } }, slots: number)
	for _, child in petsBody:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(spinning)

	local equipped = 0
	for _, pet in pets do
		if pet.Equipped then
			equipped += 1
		end
	end
	petsInfo.Text = string.format("Equipped %d/%d  •  %d/%d", equipped, slots, #pets, Config.MaxPetsInInventory)

	-- show the best pets first, equipped ones before the rest
	local order = {}
	for index in pets do
		table.insert(order, index)
	end
	table.sort(order, function(a, b)
		local petA, petB = pets[a], pets[b]
		if petA.Equipped ~= petB.Equipped then
			return petA.Equipped
		end
		return Config.Pets[petA.Name].Power > Config.Pets[petB.Name].Power
	end)

	for position, index in order do
		local pet = pets[index]
		local info = Config.Pets[pet.Name]
		local rarityColor = Config.RarityColors[info.Rarity]

		local card = Ui.new("TextButton", {
			LayoutOrder = position,
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = rarityColor:Lerp(Color3.new(1, 1, 1), if pet.Equipped then 0.45 else 0.75),
			Parent = petsBody,
		})
		Ui.round(card)
		Ui.outline(card, if pet.Equipped then Ui.Green else rarityColor, 4)
		Ui.gloss(card)

		local _, model = Ui.petViewport(pet.Name, { Size = UDim2.new(1, 0, 0, 80), Parent = card })
		table.insert(spinning, model)

		Ui.label({ Text = pet.Name, Position = UDim2.fromOffset(4, 80), Size = UDim2.new(1, -8, 0, 20), TextColor3 = rarityColor, Parent = card })
		Ui.label({ Text = info.Rarity, Position = UDim2.fromOffset(4, 100), Size = UDim2.new(1, -8, 0, 14), Parent = card })
		Ui.label({ Text = "⚔️ " .. Format.Short(info.Power), Position = UDim2.fromOffset(4, 116), Size = UDim2.new(1, -8, 0, 18), Parent = card })

		if pet.Equipped then
			Ui.label({ Text = "✅", Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(24, 24), Parent = card })
		end

		local delete = Ui.button("X", Ui.Red, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(26, 26), Parent = card })
		delete.Activated:Connect(function()
			remotes.DeletePet:FireServer(index)
		end)

		card.Activated:Connect(function()
			remotes.ToggleEquip:FireServer(index)
		end)
	end
end

remotes:WaitForChild("PetsChanged").OnClientEvent:Connect(showPets)

-- slowly spin the pets in the window
RunService.RenderStepped:Connect(function(dt)
	if not petsWindow.Visible then
		return
	end
	for _, model in spinning do
		model:PivotTo(model:GetPivot() * CFrame.Angles(0, dt, 0))
	end
end)

---------------------------------------------------------------------
-- Upgrades window
---------------------------------------------------------------------
Ui.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = upgradesBody })

for order, upgradeName in Config.UpgradeOrder do
	local info = Config.Upgrades[upgradeName]

	local row = Ui.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -12, 0, 70),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = upgradesBody,
	})
	Ui.round(row)
	Ui.outline(row, Ui.Purple, 3)
	Ui.gloss(row)

	local title = Ui.label({ Text = info.Title, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.Purple, Parent = row })
	Ui.label({ Text = info.Info, Position = UDim2.fromOffset(12, 38), Size = UDim2.new(0.6, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })

	local buy = Ui.button("", Ui.Green, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(150, 50), Parent = row })
	buy.Activated:Connect(function()
		remotes.BuyUpgrade:FireServer(upgradeName)
	end)

	local function refresh()
		local level = player:GetAttribute("Upgrade_" .. upgradeName) or 0
		title.Text = string.format("%s  (Lv %d/%d)", info.Title, level, info.MaxLevel)
		if level >= info.MaxLevel then
			buy.Text = "MAX"
			buy.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
		else
			buy.Text = Format.Short(Config.UpgradeCost(upgradeName, level)) .. " 🍮"
			buy.BackgroundColor3 = Ui.Green
		end
	end
	refresh()
	player:GetAttributeChangedSignal("Upgrade_" .. upgradeName):Connect(refresh)
end
