-- Brainrot Buffet: server entrypoint.
-- Creates the remotes, builds the world, assigns a base to each joining
-- player, and runs the loops: money ticking, the conveyor, the Hunger Wave.
-- Every rule lives in the modules; this file only wires them together.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local World = require(script:WaitForChild("World"))
local State = require(script:WaitForChild("State"))
local Characters = require(script:WaitForChild("Characters"))
local Spawner = require(script:WaitForChild("Spawner"))
local Shop = require(script:WaitForChild("Shop"))
local Steal = require(script:WaitForChild("Steal"))
local Interact = require(script:WaitForChild("Interact"))
local Wave = require(script:WaitForChild("Wave"))

-- Remotes, created once in ReplicatedStorage.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local remotes = {
	Notify = makeRemote("Notify"),
	StateUpdate = makeRemote("StateUpdate"),
	WaveEvent = makeRemote("WaveEvent"),
	LockBase = makeRemote("LockBase"),
	Rebirth = makeRemote("Rebirth"),
}

-- Build the world first: everything else needs its references.
local world = World.build()
Shop.init(world, remotes)
Steal.init(world, remotes)
Interact.init(remotes)
Wave.init(world, remotes)

-- Assign the next free base to a player, or nil when all are taken.
local function assignBase(player)
	for _, base in ipairs(world.bases) do
		if base.owner == nil then
			base.owner = player
			base.signText.Text = player.Name .. "'s Base"
			State.setBase(player, base)
			return base
		end
	end
	return nil
end

-- Free a base and remove its owner's characters from the world.
local function releaseBase(player)
	local base = State.getBase(player)
	if not base then
		return
	end
	base.owner = nil
	base.signText.Text = "Empty Base"
	for _, slot in ipairs(base.slots) do
		if slot.taken and slot.charUid then
			Characters.remove(slot.charUid)
		end
		slot.taken = false
		slot.charUid = nil
	end
end

-- Send one player's state to their client.
local function pushState(player)
	local s = State.get(player)
	local now = os.time()
	remotes.StateUpdate:FireClient(player, {
		money = s.money,
		income = State.incomePerSecond(player),
		totalEarned = s.totalEarned,
		rebirths = s.rebirths,
		multiplier = State.multiplier(player),
		owned = State.ownedCount(player),
		slots = Config.BASE_SLOTS,
		nextRebirth = State.nextRebirthCost(player),
		canRebirth = State.canRebirth(player),
		lockRemaining = State.lockRemaining(player, now),
		lockCooldown = State.lockCooldownRemaining(player, now),
	})
end

local function onPlayerAdded(player)
	State.get(player)
	local base = assignBase(player)
	if base then
		remotes.Notify:FireClient(player, "Welcome to " .. Config.GAME_NAME .. "! This is your base. Click a character on the conveyor to buy it.")
	else
		remotes.Notify:FireClient(player, "Welcome to " .. Config.GAME_NAME .. "! All bases are taken right now, but you can still watch the buffet.")
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		local b = State.getBase(player)
		if b then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(b.spawnPos)
			end
		end
	end)
end

local function onPlayerRemoving(player)
	releaseBase(player)
	State.remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Lock button.
remotes.LockBase.OnServerEvent:Connect(function(player)
	local now = os.time()
	Steal.lockBase(player, now)
	pushState(player)
end)

-- Rebirth button.
remotes.Rebirth.OnServerEvent:Connect(function(player)
	if not State.canRebirth(player) then
		remotes.Notify:FireClient(player, "Not enough total earnings to rebirth yet!")
		return
	end
	-- Clear the player's characters off their base first.
	local base = State.getBase(player)
	local uids = State.rebirth(player)
	if uids == nil then
		return
	end
	if base then
		for _, uid in ipairs(uids) do
			local rec = Characters.get(uid)
			if rec and rec.slot then
				Characters.freeSlot(base, rec.slot)
			end
			Characters.remove(uid)
		end
	end
	remotes.Notify:FireClient(player, "REBIRTH! Your earnings are now x" .. tostring(State.multiplier(player)) .. " forever.")
	pushState(player)
end)

-- Main loop: money tick every second, conveyor and wave every frame.
local moneyTimer = 0
RunService.Heartbeat:Connect(function(dt)
	-- Money tick.
	moneyTimer += dt
	if moneyTimer >= 1 then
		moneyTimer = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local income = State.incomePerSecond(player)
			if income > 0 then
				State.earn(player, income)
			end
			pushState(player)
		end
	end
	-- Conveyor and wave.
	Spawner.step(world, dt)
	Wave.step(dt)
end)

print(Config.GAME_NAME .. " server ready: " .. tostring(#world.bases) .. " bases, conveyor " .. tostring(Config.CONVEYOR_LENGTH) .. " studs.")
