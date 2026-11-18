-- Brainrot Buffet: buying characters off the conveyor.
-- tryBuy is the only way a character changes hands from the belt to a base:
-- it checks the money, the free slot and that the character is still there,
-- then moves it and charges the player. All checks run on the server.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Characters = require(script.Parent:WaitForChild("Characters"))
local State = require(script.Parent:WaitForChild("State"))

local Shop = {}

local world = nil
local remotes = nil

function Shop.init(worldRef, remotesRef)
	world = worldRef
	remotes = remotesRef
end

-- Find a free slot number on a base, or nil.
local function freeSlot(base)
	for i, slot in ipairs(base.slots) do
		if not slot.taken then
			return i
		end
	end
	return nil
end

-- Attempt to buy the character with this uid for this player.
-- Returns true and a message on success, false and a reason on failure.
function Shop.tryBuy(player, uid)
	local rec = Characters.get(uid)
	if not rec then
		return false, "That character is gone."
	end
	if not rec.onConveyor then
		return false, "That character is already owned."
	end
	local base = State.getBase(player)
	if not base then
		return false, "You have no base yet."
	end
	local slot = freeSlot(base)
	if not slot then
		return false, "Your base is full! Sell or rebirth to make room."
	end
	if not State.spend(player, rec.price) then
		return false, "Not enough money! It costs " .. tostring(rec.price) .. "."
	end
	-- The rate on the base folds in the owner's rebirth multiplier.
	local rate = Config.rateFor(rec.def, rec.mutation.name, State.multiplier(player))
	rec.rate = rate
	Characters.placeOnBase(rec, base, slot, player)
	State.addOwned(player, uid, rec.def.id, rec.mutation.name, rate, slot)
	if remotes and remotes.Notify then
		remotes.Notify:FireClient(player, "You bought " .. rec.def.name .. " for $" .. tostring(rec.price) .. "!")
	end
	return true, "Bought " .. rec.def.name .. "!"
end

return Shop
