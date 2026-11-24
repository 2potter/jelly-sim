--[[
	Ui: small helpers so the menu scripts stay short and readable.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetModels = require(ReplicatedStorage.Shared.PetModels)

local Ui = {}

Ui.Font = Enum.Font.FredokaOne
Ui.Pink = Color3.fromRGB(255, 110, 180)
Ui.Purple = Color3.fromRGB(120, 80, 220)
Ui.Dark = Color3.fromRGB(45, 30, 70)
Ui.White = Color3.new(1, 1, 1)
Ui.Green = Color3.fromRGB(90, 210, 110)
Ui.Red = Color3.fromRGB(235, 80, 90)

-- Ui.new("Frame", { Size = ..., Parent = ... }) makes an instance and sets its properties.
function Ui.new(className: string, props: { [string]: any }?): any
	local instance = Instance.new(className)
	local parent = nil
	for key, value in props or {} do
		if key == "Parent" then
			parent = value -- set Parent last, it's faster
		else
			(instance :: any)[key] = value
		end
	end
	instance.Parent = parent
	return instance
end

function Ui.round(parent: GuiObject, scale: number?, offset: number?)
	Ui.new("UICorner", { CornerRadius = UDim.new(scale or 0, offset or 12), Parent = parent })
end

-- Makes a color look glossy: lighter at the top, a bit darker at the bottom.
function Ui.gloss(parent: GuiObject)
	Ui.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(245, 245, 245)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 200)),
		}),
		Parent = parent,
	})
end

function Ui.outline(parent: GuiObject, color: Color3?, thickness: number?)
	Ui.new("UIStroke", {
		Color = color or Ui.Dark,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- A chunky cartoon text label.
function Ui.label(props: { [string]: any }): TextLabel
	local label = Ui.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Ui.Font,
		TextScaled = true,
		TextColor3 = Ui.White,
	})
	for key, value in props do
		if key ~= "Parent" then
			(label :: any)[key] = value
		end
	end
	Ui.new("UIStroke", { Color = Ui.Dark, Thickness = 2, Parent = label })
	label.Parent = props.Parent
	return label
end

-- A chunky cartoon button.
function Ui.button(text: string, color: Color3, props: { [string]: any }): TextButton
	local button = Ui.new("TextButton", {
		BackgroundColor3 = color,
		Text = text,
		Font = Ui.Font,
		TextScaled = true,
		TextColor3 = Ui.White,
		AutoButtonColor = true,
	})
	for key, value in props do
		if key ~= "Parent" then
			(button :: any)[key] = value
		end
	end
	Ui.round(button)
	Ui.outline(button)
	Ui.gloss(button)
	Ui.new("UIStroke", { Color = Ui.Dark, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = button })
	Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = button,
	})
	button.Parent = props.Parent
	return button
end

-- Shows a pet model inside a GUI box. Returns the model so you can spin it.
function Ui.petViewport(petName: string, props: { [string]: any }): (ViewportFrame, Model)
	local viewport = Ui.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.5, -1, 0.8), -- light shining onto the pet's face
	})
	for key, value in props do
		if key ~= "Parent" then
			(viewport :: any)[key] = value
		end
	end
	local model = PetModels.Build(petName)
	model:PivotTo(CFrame.Angles(0, math.rad(20), 0)) -- turn it a little so it looks 3D
	model.Parent = viewport

	local camera = Ui.new("Camera", { FieldOfView = 40, Parent = viewport })
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, -7.5), Vector3.new(0, 0.6, 0))
	viewport.CurrentCamera = camera

	viewport.Parent = props.Parent
	return viewport, model
end

return Ui
