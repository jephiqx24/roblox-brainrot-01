-- Brainrot Buffet: server entry point.
-- Builds the world, creates the RemoteEvents, assigns bases, teleports players
-- to their base, and runs the Heartbeat loop (income, spawner, Hunger Wave).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Interact = require(script.Interact)
local Spawner = require(script.Spawner)
local State = require(script.State)
local Wave = require(script.Wave)
local World = require(script.World)

print("[Brainrot Buffet] Server starting...")

-- Build the world.
World.Build()
print("[Brainrot Buffet] World built with " .. #World.Bases .. " bases.")

-- RemoteEvents.
local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local remotes = {
	StateUpdate = makeRemote("StateUpdate"),
	Notify = makeRemote("Notify"),
	Buy = makeRemote("Buy"),
	Steal = makeRemote("Steal"),
	Lock = makeRemote("Lock"),
}

local function notifyAll(message, kind)
	remotes.Notify:FireAllClients(message, kind or "info")
end

local function notifyPlayer(player, message, kind)
	remotes.Notify:FireClient(player, message, kind or "info")
end

Wave.NotifyAll = notifyAll
Wave.NotifyPlayer = notifyPlayer

-- Wire clicks and remote handlers.
Interact.Setup(remotes)

-- Next free base index (round-robin over the 8 bases).
local nextBase = 1
local function assignBase(player)
	local state = State.Get(player)
	if not state then
		return
	end
	state.BaseIndex = nextBase
	local base = World.Bases[nextBase]
	base.Owner = player
	nextBase = (nextBase % Config.Bases.Count) + 1
	notifyPlayer(player, "Welcome to Brainrot Buffet! Your base is Base " .. state.BaseIndex .. ".", "info")
end

local function teleportToBase(player)
	local state = State.Get(player)
	if not state or state.BaseIndex == 0 then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		local base = World.Bases[state.BaseIndex]
		root.CFrame = CFrame.new(base.SpawnPos)
	end
end

local function onCharacterAdded(player, _character)
	task.wait(0.2)
	teleportToBase(player)
end

local function onPlayerAdded(player)
	State.New(player)
	assignBase(player)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Clean up owned character models when the player leaves.
	player.AncestryChanged:Connect(function() end)
end

local function onPlayerRemoving(player)
	local state = State.Get(player)
	if state then
		for _, owned in ipairs(state.Owned) do
			if owned.Model then
				owned.Model:Destroy()
			end
		end
		if state.BaseIndex > 0 then
			local base = World.Bases[state.BaseIndex]
			if base and base.Owner == player then
				base.Owner = nil
			end
		end
	end
	State.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Heartbeat loop: income tick, conveyor spawner, Hunger Wave, state pushes.
local lastIncome = os.clock()
local lastPush = os.clock()
Wave.Start(os.clock())

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()

	-- Income every second (accumulated by dt so it is frame-rate independent).
	if now - lastIncome >= 1 then
		local tickDt = now - lastIncome
		lastIncome = now
		for _, player in ipairs(Players:GetPlayers()) do
			local state = State.Get(player)
			if state then
				State.AddIncome(state, tickDt)
				if State.CheckRebirth(state) then
					notifyPlayer(player, "REBIRTH! Your income multiplier is now x" .. State.IncomeMultiplier(state) .. "!", "success")
				end
			end
		end
	end

	Spawner.Step(dt, now)
	Wave.Step(now)

	-- Push HUD state twice a second.
	if now - lastPush >= 0.5 then
		lastPush = now
		for _, player in ipairs(Players:GetPlayers()) do
			local state = State.Get(player)
			if state then
				local snapshot = State.Snapshot(state)
				snapshot.WaveIn = Wave.TimeUntilNext(now)
				remotes.StateUpdate:FireClient(player, snapshot)
			end
		end
	end
end)

print("[Brainrot Buffet] Server ready.")
