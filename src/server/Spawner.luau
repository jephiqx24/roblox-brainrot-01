-- Brainrot Buffet: conveyor spawner.
-- Spawns a character every few seconds (max 8 alive), walks them along the
-- conveyor at 4 studs/s, despawns any that reach the end un-bought.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Characters = require(script.Parent.Characters)

local Spawner = {}

Spawner.Alive = {} -- list of { Id, Def, Mutation, Rate, Model, X }
Spawner.LastSpawn = 0
Spawner.OnSpawn = nil -- optional callback(entry) set by init for click wiring

local function removeEntry(entry)
	for i, e in ipairs(Spawner.Alive) do
		if e == entry then
			table.remove(Spawner.Alive, i)
			break
		end
	end
end

function Spawner.FindById(id)
	for _, entry in ipairs(Spawner.Alive) do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end

function Spawner.RemoveById(id)
	local entry = Spawner.FindById(id)
	if entry then
		removeEntry(entry)
		Characters.Despawn(entry.Model)
		return true
	end
	return false
end

-- Takes an entry off the conveyor without despawning its model (a buyer takes it).
function Spawner.TakeById(id)
	local entry = Spawner.FindById(id)
	if entry then
		removeEntry(entry)
		return entry
	end
	return nil
end

function Spawner.SpawnOne()
	local def = Characters.PickDefinition()
	local mutation = Characters.RollMutation()
	local rate = Characters.RateFor(def, mutation)
	local model, id = Characters.BuildModel(def, mutation, rate)
	model.Parent = workspace.BuffetWorld
	Characters.PlaceModel(model, Vector3.new(Config.Conveyor.StartX, Config.Conveyor.Y, Config.Conveyor.Z))

	local entry = {
		Id = id,
		Def = def,
		Mutation = mutation,
		Rate = rate,
		Model = model,
		X = Config.Conveyor.StartX,
	}
	table.insert(Spawner.Alive, entry)
	if Spawner.OnSpawn then
		Spawner.OnSpawn(entry)
	end
	return entry
end

-- Clears every character currently on the conveyor (Hunger Wave).
function Spawner.ClearAll()
	for _, entry in ipairs(Spawner.Alive) do
		Characters.Despawn(entry.Model)
	end
	table.clear(Spawner.Alive)
end

-- Called every Heartbeat with dt: spawn on schedule, walk everyone, despawn at the end.
function Spawner.Step(dt, now)
	if now - Spawner.LastSpawn >= Config.Conveyor.SpawnInterval and #Spawner.Alive < Config.Conveyor.MaxAlive then
		Spawner.LastSpawn = now
		Spawner.SpawnOne()
	end

	local i = 1
	while i <= #Spawner.Alive do
		local entry = Spawner.Alive[i]
		if not entry.Model.Parent then
			table.remove(Spawner.Alive, i)
		else
			entry.X += Config.Conveyor.Speed * dt
			if entry.X >= Config.Conveyor.EndX then
				Characters.Despawn(entry.Model)
				table.remove(Spawner.Alive, i)
			else
				Characters.PlaceModel(entry.Model, Vector3.new(entry.X, Config.Conveyor.Y, Config.Conveyor.Z))
				i += 1
			end
		end
	end
end

return Spawner
