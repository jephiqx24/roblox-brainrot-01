-- Brainrot Buffet: client entry point.
-- Wires RemoteEvents to the HUD and sounds, and the base-lock button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Hud = require(script.Parent.Hud)
local Sound = require(script.Parent.Sound)

local StateUpdate = ReplicatedStorage:WaitForChild("StateUpdate")
local Notify = ReplicatedStorage:WaitForChild("Notify")
local LockRemote = ReplicatedStorage:WaitForChild("Lock")

-- Build the HUD first so toasts have somewhere to go.
Hud.Build(player)

StateUpdate.OnClientEvent:Connect(function(snapshot)
	Hud.Update(snapshot)
end)

Notify.OnClientEvent:Connect(function(message, kind)
	Hud.Toast(message, kind or "info")
	if kind == "success" then
		Sound.Play("buy")
	elseif kind == "error" then
		Sound.Play("error")
	elseif kind == "warning" then
		Sound.Play("wave")
	end
end)

-- Lock button in the HUD fires the Lock remote.
Hud.OnLockPressed = function()
	LockRemote:FireServer()
end

print("[Brainrot Buffet] Client ready.")
