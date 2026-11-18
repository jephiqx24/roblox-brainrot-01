-- Brainrot Buffet: per-player state.
-- Money, lifetime earnings, rebirths, owned characters, base assignment, cooldowns.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Util = require(game:GetService("ReplicatedStorage").Shared.Util)

local State = {}

State.Players = {} -- [Player] = state table

function State.New(player)
	local state = {
		Player = player,
		Money = Config.StartingMoney,
		TotalEarned = 0,
		Rebirths = 0,
		Owned = {}, -- list of owned character entries { Id, Def, Mutation, Rate, Model, Slot }
		BaseIndex = 0,
		StealCooldownUntil = 0,
		LockUntil = 0,
		LockCooldownUntil = 0,
	}
	State.Players[player] = state
	return state
end

function State.Get(player)
	return State.Players[player]
end

function State.Remove(player)
	State.Players[player] = nil
end

function State.IncomeMultiplier(state)
	return Util.RebirthMultiplier(state.Rebirths)
end

-- Adds income for dt seconds from all owned characters. Returns the amount added.
function State.AddIncome(state, dt)
	local total = 0
	for _, owned in ipairs(state.Owned) do
		total += owned.Rate * dt
	end
	total *= State.IncomeMultiplier(state)
	if total > 0 then
		state.Money += total
		state.TotalEarned += total
	end
	return total
end

-- Next rebirth threshold, or nil when maxed out.
function State.NextRebirthThreshold(state)
	return Config.RebirthThresholds[state.Rebirths + 1]
end

-- Auto-rebirth: when lifetime earnings cross the next threshold, rebirth once
-- per threshold crossed and announce it. Returns true if a rebirth happened.
function State.CheckRebirth(state)
	local nextThreshold = State.NextRebirthThreshold(state)
	if nextThreshold and state.TotalEarned >= nextThreshold then
		state.Rebirths += 1
		return true
	end
	return false
end

function State.CanAfford(state, cost)
	return state.Money >= cost
end

function State.Spend(state, cost)
	state.Money -= cost
end

-- Finds a free slot index (1-6) on the player's base, or nil if full.
function State.FreeSlot(state)
	local used = {}
	for _, owned in ipairs(state.Owned) do
		if owned.Slot then
			used[owned.Slot] = true
		end
	end
	for i = 1, Config.Bases.Slots do
		if not used[i] then
			return i
		end
	end
	return nil
end

function State.IsBaseLocked(state)
	return os.clock() < state.LockUntil
end

function State.CanLock(state)
	return os.clock() >= state.LockCooldownUntil
end

function State.LockBase(state)
	state.LockUntil = os.clock() + Config.LockDuration
	state.LockCooldownUntil = os.clock() + Config.LockCooldown
end

function State.CanSteal(state)
	return os.clock() >= state.StealCooldownUntil
end

function State.MarkSteal(state)
	state.StealCooldownUntil = os.clock() + Config.StealCooldown
end

-- Lightweight snapshot sent to the client for the HUD.
function State.Snapshot(state)
	local nextThreshold = State.NextRebirthThreshold(state)
	return {
		Money = state.Money,
		TotalEarned = state.TotalEarned,
		Rebirths = state.Rebirths,
		Multiplier = State.IncomeMultiplier(state),
		NextRebirth = nextThreshold,
		OwnedCount = #state.Owned,
		BaseIndex = state.BaseIndex,
		StealReadyIn = math.max(0, state.StealCooldownUntil - os.clock()),
		LockActiveIn = math.max(0, state.LockUntil - os.clock()),
		LockReadyIn = math.max(0, state.LockCooldownUntil - os.clock()),
	}
end

return State
