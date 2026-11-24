--[[
	Format: turns big numbers into short text, like 15300 -> "15.3K".
]]

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.Short(n: number): string
	n = math.floor(n)
	local index = 1
	local value = n
	while math.abs(value) >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	if index == 1 then
		return tostring(value)
	end
	return string.format("%.1f%s", value, SUFFIXES[index])
end

return Format
