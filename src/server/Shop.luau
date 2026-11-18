-- Brainrot Buffet: buying conveyor characters.
-- Click a conveyor character to buy it if you can afford it; it walks to a
-- free slot on your base and starts earning $/s.

local Characters = require(script.Parent.Characters)
local Spawner = require(script.Parent.Spawner)
local State = require(script.Parent.State)
local World = require(script.Parent.World)

local Shop = {}

Shop.OnBought = nil -- optional callback(player, entry, base) set by init for click wiring

-- Attempts a purchase. Returns (success, message).
function Shop.Buy(player, charId)
	local state = State.Get(player)
	if not state then
		return false, "No player state."
	end
	if state.BaseIndex == 0 then
		return false, "You have no base yet."
	end

	local entry = Spawner.TakeById(charId)
	if not entry then
		return false, "That character is gone."
	end

	local cost = entry.Def.Cost
	if not State.CanAfford(state, cost) then
		-- Put it back on the conveyor: re-insert at its current X.
		table.insert(Spawner.Alive, entry)
		return false, "Not enough money! You need " .. cost .. "."
	end

	local slot = State.FreeSlot(state)
	if not slot then
		table.insert(Spawner.Alive, entry)
		return false, "Your base is full!"
	end

	State.Spend(state, cost)

	local base = World.Bases[state.BaseIndex]
	local owned = {
		Id = entry.Id,
		Def = entry.Def,
		Mutation = entry.Mutation,
		Rate = entry.Rate,
		Model = entry.Model,
		Slot = slot,
		Owner = player,
	}
	table.insert(state.Owned, owned)

	-- Move the model onto the base slot.
	Characters.PlaceModel(entry.Model, base.Slots[slot])
	entry.Model:SetAttribute("OwnedBy", player.Name)
	entry.Model:SetAttribute("Slot", slot)

	if Shop.OnBought then
		Shop.OnBought(player, owned, base)
	end

	return true, "You bought " .. entry.Def.Name .. "!"
end

return Shop
