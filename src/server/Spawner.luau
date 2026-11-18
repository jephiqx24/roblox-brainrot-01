-- Brainrot Buffet: the conveyor spawner.
-- Keeps characters walking the belt: one spawns every SPAWN_INTERVAL
-- seconds while fewer than MAX_ON_CONVEYOR are on it, and each one walks
-- from the start to the end and despawns if nobody buys it.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Characters = require(script.Parent:WaitForChild("Characters"))
local Interact = require(script.Parent:WaitForChild("Interact"))

local Spawner = {}

local timer = 0

-- How many characters are on the conveyor right now.
function Spawner.onConveyorCount()
	local n = 0
	for _, rec in pairs(Characters.all()) do
		if rec.onConveyor then
			n += 1
		end
	end
	return n
end

-- One tick of the spawner, called every frame with dt. world is the built world.
function Spawner.step(world, dt)
	-- Walk the ones already on the belt.
	local finished = Characters.stepConveyor(world, dt)
	for _, uid in ipairs(finished) do
		Characters.remove(uid)
	end
	-- Spawn a new one on schedule.
	timer += dt
	if timer >= Config.SPAWN_INTERVAL and Spawner.onConveyorCount() < Config.MAX_ON_CONVEYOR then
		timer = 0
		local rec = Characters.spawn(world)
		Interact.bindCharacter(rec)
	end
end

return Spawner
