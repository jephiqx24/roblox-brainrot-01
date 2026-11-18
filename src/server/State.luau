-- Brainrot Buffet: player state, kept in one place.
-- Every player's money, earnings, owned characters, rebirths and lock live
-- here. Other server modules read and change state only through this module.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local State = {}

-- player -> state table
local states = {}
-- player -> base info (assigned at join)
local playerBase = {}

-- A fresh state for a joining player.
local function freshState()
	return {
		money = Config.START_MONEY,
		totalEarned = 0,
		rebirths = 0,
		-- uid -> { charId, mutation, rate, slot }
		owned = {},
		lockedUntil = 0,
		lockReadyAt = 0,
		lastStealAt = 0,
	}
end

function State.get(player)
	local s = states[player]
	if not s then
		s = freshState()
		states[player] = s
	end
	return s
end

function State.remove(player)
	states[player] = nil
	playerBase[player] = nil
end

function State.setBase(player, base)
	playerBase[player] = base
end

function State.getBase(player)
	return playerBase[player]
end

-- The player's permanent earnings multiplier from rebirths.
function State.multiplier(player)
	local s = State.get(player)
	return (Config.REBIRTH_MULTIPLIER) ^ s.rebirths
end

-- Money per second from everything the player owns.
function State.incomePerSecond(player)
	local s = State.get(player)
	local total = 0
	for _, owned in pairs(s.owned) do
		total += owned.rate
	end
	return total
end

-- Add money (earnings). totalEarned tracks rebirth progress.
function State.earn(player, amount)
	local s = State.get(player)
	s.money += amount
	s.totalEarned += amount
end

function State.spend(player, amount)
	local s = State.get(player)
	if s.money < amount then
		return false
	end
	s.money -= amount
	return true
end

-- Register a character the player owns. slot is the base slot number.
function State.addOwned(player, uid, charId, mutation, rate, slot)
	local s = State.get(player)
	s.owned[uid] = { charId = charId, mutation = mutation, rate = rate, slot = slot }
end

function State.removeOwned(player, uid)
	local s = State.get(player)
	local owned = s.owned[uid]
	s.owned[uid] = nil
	return owned
end

function State.ownedCount(player)
	local s = State.get(player)
	local n = 0
	for _ in pairs(s.owned) do
		n += 1
	end
	return n
end

-- Rebirth: what it costs (total earned) for the player's next rebirth, or nil
-- when the player is at the last one.
function State.nextRebirthCost(player)
	local s = State.get(player)
	return Config.REBIRTH_COSTS[s.rebirths + 1]
end

function State.canRebirth(player)
	local cost = State.nextRebirthCost(player)
	if cost == nil then
		return false
	end
	return State.get(player).totalEarned >= cost
end

-- Perform the rebirth: money and owned characters reset, rebirths +1.
-- Returns the list of owned uids that must be cleared from the base.
function State.rebirth(player)
	local s = State.get(player)
	if not State.canRebirth(player) then
		return nil
	end
	local uids = {}
	for uid in pairs(s.owned) do
		table.insert(uids, uid)
	end
	s.owned = {}
	s.money = Config.START_MONEY
	s.rebirths += 1
	return uids
end

-- Base lock.
function State.isLocked(player, now)
	return State.get(player).lockedUntil > now
end

function State.lockRemaining(player, now)
	return math.max(0, State.get(player).lockedUntil - now)
end

function State.lockCooldownRemaining(player, now)
	return math.max(0, State.get(player).lockReadyAt - now)
end

-- Lock the player's base. Returns true when the lock started.
function State.lockBase(player, now)
	local s = State.get(player)
	if s.lockReadyAt > now then
		return false
	end
	s.lockedUntil = now + Config.LOCK_DURATION
	s.lockReadyAt = now + Config.LOCK_DURATION + Config.LOCK_COOLDOWN
	return true
end

-- Steal cooldown.
function State.canSteal(player, now)
	return State.get(player).lastStealAt + Config.STEAL_COOLDOWN <= now
end

function State.markSteal(player, now)
	State.get(player).lastStealAt = now
end

function State.stealCooldownRemaining(player, now)
	local s = State.get(player)
	return math.max(0, s.lastStealAt + Config.STEAL_COOLDOWN - now)
end

return State
