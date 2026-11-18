-- Brainrot Buffet: client entrypoint.
-- Waits for the server's remotes, builds the HUD, and routes the server's
-- updates into it. The 3D world is the game; this script is only the
-- interface over it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))
local Sound = require(script.Parent:WaitForChild("Sound"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = remotes:WaitForChild("Notify")
local StateUpdate = remotes:WaitForChild("StateUpdate")
local WaveEvent = remotes:WaitForChild("WaveEvent")

Hud.init(remotes)

StateUpdate.OnClientEvent:Connect(function(state)
	Hud.update(state)
end)

Notify.OnClientEvent:Connect(function(msg)
	Hud.notify(msg)
	if string.find(msg, "You bought") then
		Sound.play("buy")
	elseif string.find(msg, "stole") or string.find(msg, "REBIRTH") then
		Sound.play("rebirth")
	end
end)

WaveEvent.OnClientEvent:Connect(function(event, data)
	Hud.wave(event, data)
end)
