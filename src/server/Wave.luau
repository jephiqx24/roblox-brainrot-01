-- Brainrot Buffet: the Hunger Wave.
-- Every 180s a wave rolls in: 30s warning, then a 10s sweep. Any player caught
-- outside their base is teleported home and loses 10% of their money, and the
-- conveyor is cleared.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Players = game:GetService("Players")
local Spawner = require(script.Parent.Spawner)
local State = require(script.Parent.State)
local Util = require(game:GetService("ReplicatedStorage").Shared.Util)
local World = require(script.Parent.World)

local Wave = {}

Wave.NotifyAll = nil -- set by init: function(message, kind)
Wave.NotifyPlayer = nil -- set by init: function(player, message, kind)
Wave.NextWaveAt = 0
Wave.WarningSent = false
Wave.Sweeping = false
Wave.SweepEndsAt = 0
Wave.Started = false

function Wave.Start(now)
	Wave.NextWaveAt = now + Config.Wave.Cycle
	Wave.WarningSent = false
	Wave.Sweeping = false
	Wave.Started = true
end

function Wave.TimeUntilNext(now)
	if not Wave.Started then
		return Config.Wave.Cycle
	end
	return math.max(0, Wave.NextWaveAt - now)
end

local function notifyAll(message, kind)
	if Wave.NotifyAll then
		Wave.NotifyAll(message, kind)
	end
end

local function isOutsideBase(player, state)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local base = World.Bases[state.BaseIndex]
	if not base then
		return true
	end
	local dist = Util.FlatDistance(root.Position, base.Center)
	return dist > (Config.Bases.Size / 2)
end

local function runSweep()
	-- Show the wave wall, clear the conveyor.
	if World.WaveWall then
		World.WaveWall.Transparency = 0.3
	end
	Spawner.ClearAll()

	for _, player in ipairs(Players:GetPlayers()) do
		local state = State.Get(player)
		if state and state.BaseIndex > 0 then
			if isOutsideBase(player, state) then
				local loss = math.floor(state.Money * Config.Wave.LossPercent)
				state.Money -= loss
				local base = World.Bases[state.BaseIndex]
				local character = player.Character
				if character then
					local root = character:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = CFrame.new(base.SpawnPos)
					end
				end
				if Wave.NotifyPlayer then
					Wave.NotifyPlayer(player, "Hunger Wave caught you! You lost " .. Util.FormatMoney(loss) .. ".", "warning")
				end
			end
		end
	end

	notifyAll("The Hunger Wave swept the picnic! Get back to your base next time.", "warning")
end

-- Called every Heartbeat with the current clock time.
function Wave.Step(now)
	if not Wave.Started then
		return
	end

	if Wave.Sweeping then
		if now >= Wave.SweepEndsAt then
			Wave.Sweeping = false
			if World.WaveWall then
				World.WaveWall.Transparency = 1
			end
			Wave.NextWaveAt = now + Config.Wave.Cycle
			Wave.WarningSent = false
			notifyAll("The wave has passed. The conveyor is running again!", "info")
		end
		return
	end

	local remaining = Wave.NextWaveAt - now
	if remaining <= Config.Wave.Warning and not Wave.WarningSent then
		Wave.WarningSent = true
		notifyAll("HUNGER WAVE in " .. Config.Wave.Warning .. "s! Get back to your base!", "warning")
	end

	if remaining <= 0 then
		Wave.Sweeping = true
		Wave.SweepEndsAt = now + Config.Wave.Sweep
		runSweep()
	end
end

return Wave
