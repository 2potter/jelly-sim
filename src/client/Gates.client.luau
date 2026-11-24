--[[
	Gates: opens the zone gates you have unlocked.
	The gate stays solid for other players who haven't unlocked it yet,
	because this only changes it on YOUR screen.
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("JellyWorld")
local gates = world:WaitForChild("Gates")

local function updateGates()
	local unlocked = player:GetAttribute("ZonesUnlocked") or 1
	for _, gate in gates:GetChildren() do
		local isOpen = (gate:GetAttribute("ZoneIndex") or 99) <= unlocked
		local wall = gate:FindFirstChild("Wall")
		if wall then
			wall.CanCollide = not isOpen
			wall.Transparency = if isOpen then 1 else 0.2
			local sign = wall:FindFirstChild("Sign")
			if sign then
				sign.Enabled = not isOpen
			end
		end
		local button = gate:FindFirstChild("Button")
		if button then
			button.Transparency = if isOpen then 1 else 0
			local prompt = button:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Enabled = not isOpen
			end
		end
	end
end

player:GetAttributeChangedSignal("ZonesUnlocked"):Connect(updateGates)
-- parts can load in a bit later (streaming), so check again when they arrive
gates.DescendantAdded:Connect(function()
	task.defer(updateGates)
end)
updateGates()
