-- Brainrot Buffet: small shared helpers. No side effects.

local Util = {}

-- Format money: $1,234, $12.3K, $4.5M, $2.1B.
function Util.formatMoney(n)
	n = math.floor(n + 0.5)
	if n < 1000 then
		return "$" .. tostring(n)
	end
	local suffixes = { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, s in ipairs(suffixes) do
		local div, suffix = s[1], s[2]
		if n >= div then
			local v = n / div
			if v >= 100 then
				return "$" .. tostring(math.floor(v + 0.5)) .. suffix
			else
				return "$" .. string.format("%.1f", v) .. suffix
			end
		end
	end
	return "$" .. tostring(n)
end

-- Format a duration in seconds as M:SS.
function Util.formatTime(sec)
	sec = math.max(0, math.floor(sec + 0.5))
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("%d:%02d", m, s)
end

-- A short unique id for spawned characters.
local uidCounter = 0
function Util.nextUid()
	uidCounter += 1
	return "c" .. tostring(os.time()) .. "-" .. tostring(uidCounter) .. "-" .. tostring(math.random(1000, 9999))
end

return Util
