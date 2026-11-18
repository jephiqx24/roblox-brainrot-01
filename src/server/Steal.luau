-- Brainrot Buffet: stealing characters and locking your base.
-- A player can steal a character off another player's base by clicking it,
-- unless that base is locked or the thief is on cooldown. Locking your base
-- stops every steal for a minute. All checks run on the server.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Characters = require(script.Parent:WaitForChild("Characters"))
local State = require(script.Parent:WaitForChild("State"))

local Steal = {}

local world = nil
local remotes = nil

function Steal.init(worldRef, remotesRef)
	world = worldRef
	remotes = remotesRef
end

local function freeSlot(base)
	for i, slot in ipairs(base.slots) do
		if not slot.taken then
			return i
		end
	end
	return nil
end

local function notify(player, msg)
	if remotes and remotes.Notify then
		remotes.Notify:FireClient(player, msg)
	end
end

-- Attempt to steal the character with this uid for this player.
function Steal.trySteal(player, uid, now)
	local rec = Characters.get(uid)
	if not rec then
		return false, "That character is gone."
	end
	if rec.onConveyor then
		return false, "That character is on the conveyor, not a base."
	end
	local owner = rec.owner
	if not owner then
		return false, "That character has no owner."
	end
	if owner == player then
		return false, "That is your own " .. rec.def.name .. "."
	end
	if State.isLocked(owner, now) then
		return false, owner.Name .. "'s base is locked!"
	end
	if not State.canSteal(player, now) then
		return false, "Steal is on cooldown (" .. tostring(State.stealCooldownRemaining(player, now)) .. "s)."
	end
	local myBase = State.getBase(player)
	if not myBase then
		return false, "You have no base yet."
	end
	local slot = freeSlot(myBase)
	if not slot then
		return false, "Your base is full! Sell or rebirth to make room."
	end
	-- Move it: free the old slot, take it off the old owner's books, put it
	-- on the thief's base with the thief's multiplier.
	local oldBase = State.getBase(owner)
	local oldSlot = rec.slot
	if oldBase and oldSlot then
		Characters.freeSlot(oldBase, oldSlot)
	end
	State.removeOwned(owner, uid)
	State.markSteal(player, now)
	local rate = Config.rateFor(rec.def, rec.mutation.name, State.multiplier(player))
	rec.rate = rate
	Characters.placeOnBase(rec, myBase, slot, player)
	State.addOwned(player, uid, rec.def.id, rec.mutation.name, rate, slot)
	notify(player, "You stole " .. rec.def.name .. " from " .. owner.Name .. "!")
	notify(owner, player.Name .. " stole your " .. rec.def.name .. "! Lock your base!")
	return true, "Stole " .. rec.def.name .. "!"
end

-- Lock the player's base. Returns true when the lock started.
function Steal.lockBase(player, now)
	if State.lockBase(player, now) then
		notify(player, "Base locked for " .. tostring(Config.LOCK_DURATION) .. "s! No one can steal from you.")
		return true
	end
	notify(player, "Lock is on cooldown (" .. tostring(State.lockCooldownRemaining(player, now)) .. "s left).")
	return false
end

return Steal
