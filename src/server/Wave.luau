-- Brainrot Buffet: the Hunger Wave.
-- Every WAVE_INTERVAL seconds the wave comes. It warns for WAVE_WARNING
-- seconds so players can dash home, then a wall of hunger sweeps the map.
-- Anyone caught outside their base is swept home and loses a share of
-- their money; characters left on the conveyor are swept away. The base
-- is always safe.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Characters = require(script.Parent:WaitForChild("Characters"))
local State = require(script.Parent:WaitForChild("State"))

local Wave = {}

local world = nil
local remotes = nil
local timer = 0
local phase = "idle" -- idle, warning, sweeping
local phaseTimer = 0
local warned = false

function Wave.init(worldRef, remotesRef)
	world = worldRef
	remotes = remotesRef
end

local function broadcast(event, data)
	if remotes and remotes.WaveEvent then
		remotes.WaveEvent:FireAllClients(event, data)
	end
end

local function notify(player, msg)
	if remotes and remotes.Notify then
		remotes.Notify:FireClient(player, msg)
	end
end

-- Is this player's character inside their own base?
local function isHome(player)
	local base = State.getBase(player)
	local char = player.Character
	if not base or not char then
		return false
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local d = (root.Position - base.center)
	d = Vector3.new(d.X, 0, d.Z)
	return d.Magnitude <= 18
end

-- Sweep one player home: teleport to their base and take the penalty.
local function sweepPlayer(player)
	local base = State.getBase(player)
	local char = player.Character
	local s = State.get(player)
	local lost = math.floor(s.money * Config.WAVE_PENALTY)
	if lost > 0 then
		s.money -= lost
	end
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and base then
			root.CFrame = CFrame.new(base.spawnPos)
		end
	end
	if lost > 0 then
		notify(player, "The Hunger Wave swept you home! You lost $" .. tostring(lost) .. ".")
	else
		notify(player, "The Hunger Wave swept you home!")
	end
end

-- One tick of the wave clock, called every frame with dt.
function Wave.step(dt)
	if phase == "idle" then
		timer += dt
		if timer >= Config.WAVE_INTERVAL - Config.WAVE_WARNING and not warned then
			warned = true
			phase = "warning"
			phaseTimer = 0
			broadcast("warning", Config.WAVE_WARNING)
		end
	elseif phase == "warning" then
		phaseTimer += dt
		if phaseTimer >= Config.WAVE_WARNING then
			phase = "sweeping"
			phaseTimer = 0
			broadcast("start", Config.WAVE_SWEEP)
			-- The wall appears at the west edge, visible.
			if world and world.waveWall then
				world.waveWall.Transparency = 0.4
				world.waveWall.Position = Vector3.new(-200, 20, 0)
			end
		end
	elseif phase == "sweeping" then
		phaseTimer += dt
		local t = math.clamp(phaseTimer / Config.WAVE_SWEEP, 0, 1)
		if world and world.waveWall then
			world.waveWall.Position = Vector3.new(-200 + 400 * t, 20, 0)
		end
		if phaseTimer >= Config.WAVE_SWEEP then
			-- The wave has crossed: sweep everyone caught outside, clear the belt.
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				if not isHome(player) then
					sweepPlayer(player)
				end
			end
			local swept = {}
			for uid, rec in pairs(Characters.all()) do
				if rec.onConveyor then
					table.insert(swept, uid)
				end
			end
			for _, uid in ipairs(swept) do
				Characters.remove(uid)
			end
			if world and world.waveWall then
				world.waveWall.Transparency = 1
				world.waveWall.Position = Vector3.new(-400, 20, 0)
			end
			broadcast("end", 0)
			phase = "idle"
			timer = 0
			warned = false
		end
	end
end

return Wave
