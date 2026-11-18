-- Brainrot Buffet: click + remote handling.
-- Wires ClickDetectors on conveyor and owned characters, and the Buy / Steal /
-- Lock RemoteEvents the client fires. Results go back through the Notify remote.

local Shop = require(script.Parent.Shop)
local Spawner = require(script.Parent.Spawner)
local Steal = require(script.Parent.Steal)

local Interact = {}

local Remotes = nil

local function notifyPlayer(player, message, kind)
	if Remotes and Remotes.Notify then
		Remotes.Notify:FireClient(player, message, kind or "info")
	end
end

local function wireClick(model, charId, isOwned)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local old = body:FindFirstChildOfClass("ClickDetector")
	if old then
		old:Destroy()
	end
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 60
	detector.Parent = body
	if isOwned then
		detector.MouseClick:Connect(function(player)
			local ok, msg = Steal.TrySteal(player, charId)
			notifyPlayer(player, msg, ok and "success" or "error")
		end)
	else
		detector.MouseClick:Connect(function(player)
			local ok, msg = Shop.Buy(player, charId)
			notifyPlayer(player, msg, ok and "success" or "error")
		end)
	end
end

function Interact.Setup(remotes)
	Remotes = remotes

	-- Every conveyor spawn gets a buy ClickDetector.
	Spawner.OnSpawn = function(entry)
		wireClick(entry.Model, entry.Id, false)
	end
	-- Wire spawns that already exist (none at startup, but be safe).
	for _, entry in ipairs(Spawner.Alive) do
		wireClick(entry.Model, entry.Id, false)
	end

	-- A bought character becomes stealable.
	Shop.OnBought = function(_player, owned, _base)
		wireClick(owned.Model, owned.Id, true)
	end

	-- A stolen character stays stealable (by someone else next time).
	Steal.OnStolen = function(_thief, _victim, owned, _base)
		wireClick(owned.Model, owned.Id, true)
	end

	-- RemoteEvents from the client (HUD buttons / future click paths).
	if remotes.Buy then
		remotes.Buy.OnServerEvent:Connect(function(player, charId)
			if typeof(charId) ~= "number" then
				return
			end
			local ok, msg = Shop.Buy(player, charId)
			notifyPlayer(player, msg, ok and "success" or "error")
		end)
	end
	if remotes.Steal then
		remotes.Steal.OnServerEvent:Connect(function(player, charId)
			if typeof(charId) ~= "number" then
				return
			end
			local ok, msg = Steal.TrySteal(player, charId)
			notifyPlayer(player, msg, ok and "success" or "error")
		end)
	end
	if remotes.Lock then
		remotes.Lock.OnServerEvent:Connect(function(player)
			local ok, msg = Steal.LockBase(player)
			notifyPlayer(player, msg, ok and "success" or "error")
		end)
	end
end

return Interact
