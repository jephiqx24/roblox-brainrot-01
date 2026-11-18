-- Brainrot Buffet: clicking a character in the 3D world.
-- One ClickDetector per character. A click on a conveyor character is a buy;
-- a click on someone else's base character is a steal; a click on your own
-- shows its info. The server decides everything.

local Characters = require(script.Parent:WaitForChild("Characters"))
local Shop = require(script.Parent:WaitForChild("Shop"))
local Steal = require(script.Parent:WaitForChild("Steal"))

local Interact = {}

local remotes = nil

function Interact.init(remotesRef)
	remotes = remotesRef
end

local function notify(player, msg)
	if remotes and remotes.Notify then
		remotes.Notify:FireClient(player, msg)
	end
end

-- Wire a character's ClickDetector to the buy/steal dispatch.
function Interact.bindCharacter(record)
	local model = record.model
	local click = model:FindFirstChild("BuyClick")
	if not click then
		return
	end
	click.MouseClick:Connect(function(player)
		local now = os.time()
		if record.onConveyor then
			local ok, msg = Shop.tryBuy(player, record.uid)
			if not ok then
				notify(player, msg)
			end
		elseif record.owner == player then
			notify(player, record.def.name .. " (" .. record.def.rarity .. ") earns $" .. tostring(record.rate) .. "/s. " .. record.def.desc)
		else
			local ok, msg = Steal.trySteal(player, record.uid, now)
			if not ok then
				notify(player, msg)
			end
		end
	end)
end

return Interact
