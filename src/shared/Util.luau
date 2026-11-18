-- Brainrot Buffet: small shared helpers.

local Util = {}

-- Formats a money amount as "$1,234,567". Rounds down to whole dollars.
function Util.FormatMoney(amount)
	local n = math.floor(amount + 0.0001)
	local negative = n < 0
	if negative then
		n = -n
	end
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, #s - 3)
	end
	out = s .. out
	if negative then
		out = "-" .. out
	end
	return "$" .. out
end

-- Short form for big numbers: "$25K", "$2.5M", "$1.5B".
function Util.FormatShort(amount)
	local n = amount
	if n >= 1e9 then
		return string.format("$%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("$%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("$%.1fK", n / 1e3)
	else
		return Util.FormatMoney(n)
	end
end

function Util.Clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	else
		return value
	end
end

function Util.Round(value)
	return math.floor(value + 0.5)
end

-- Income multiplier from a rebirth count: rebirth 1 = x2, rebirth 2 = x4, ...
function Util.RebirthMultiplier(rebirths)
	return 2 ^ rebirths
end

-- Distance on the XZ plane between two Vector3s.
function Util.FlatDistance(a, b)
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

return Util
