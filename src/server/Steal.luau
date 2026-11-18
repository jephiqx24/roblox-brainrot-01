-- Brainrot Buffet: stealing rivals' characters and locking your base.
-- Steal has a 30s cooldown per player. A base lock lasts 60s with a 120s
-- cooldown and blocks all steals from that base while active.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Characters = require(script.Parent.Characters)
local State = require(script.Parent.State)
local World = require(script.Parent.World)

local Steal = {}

Steal.OnStolen = nil -- optional callback(thief, victim, owned, base)

-- Finds an owned character entry by model CharId across all players.
local function findOwned(charId)
	for _, state in pairs(State.Players) do
		for _, owned in ipairs(state.Owned) do
			if owned.Id == charId then
				return owned, state
			end
		end
	end
	return nil, nil
end

-- Attempts a steal. Returns (success, message).
function Steal.TrySteal(thief, charId)
	local thiefState = State.Get(thief)
	if not thiefState then
		return false, "No player state."
	end
	if thiefState.BaseIndex == 0 then
		return false, "You have no base yet."
	end

	local owned, victimState = findOwned(charId)
	if not owned then
		return false, "That character is gone."
	end
	if victimState.Player == thief then
		return false, "That one is already yours!"
	end

	if State.IsBaseLocked(victimState) then
		return false, victimState.Player.Name .. "'s base is locked!"
	end

	if not State.CanSteal(thiefState) then
		local wait = math.ceil(thiefState.StealCooldownUntil - os.clock())
		return false, "Steal cooldown: wait " .. wait .. "s."
	end

	local slot = State.FreeSlot(thiefState)
	if not slot then
		return false, "Your base is full!"
	end

	State.MarkSteal(thiefState)

	-- Remove from the victim.
	for i, o in ipairs(victimState.Owned) do
		if o == owned then
			table.remove(victimState.Owned, i)
			break
		end
	end

	-- Move to the thief's base.
	owned.Owner = thief
	owned.Slot = slot
	table.insert(thiefState.Owned, owned)
	local base = World.Bases[thiefState.BaseIndex]
	Characters.PlaceModel(owned.Model, base.Slots[slot])
	owned.Model:SetAttribute("OwnedBy", thief.Name)
	owned.Model:SetAttribute("Slot", slot)

	if Steal.OnStolen then
		Steal.OnStolen(thief, victimState.Player, owned, base)
	end

	return true, "You stole " .. owned.Def.Name .. " from " .. victimState.Player.Name .. "!"
end

-- Attempts to lock the caller's base. Returns (success, message).
function Steal.LockBase(player)
	local state = State.Get(player)
	if not state then
		return false, "No player state."
	end
	if State.IsBaseLocked(state) then
		return false, "Your base is already locked!"
	end
	if not State.CanLock(state) then
		local wait = math.ceil(state.LockCooldownUntil - os.clock())
		return false, "Lock cooldown: wait " .. wait .. "s."
	end
	State.LockBase(state)
	return true, "Base locked for " .. Config.LockDuration .. "s!"
end

return Steal
