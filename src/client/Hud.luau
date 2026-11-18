-- Brainrot Buffet: the HUD.
-- A ScreenGui over the 3D world. Top-center is the money bar (kept clear
-- of the top-left corner where Roblox's own menu buttons sit), top-right
-- holds the action buttons, the wave banner appears centre-top, and
-- notifications stack at the bottom. init(remotes) builds it; update(state)
-- refreshes it from the server's StateUpdate.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))
local Sound = require(script.Parent:WaitForChild("Sound"))

local Hud = {}

local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local rebirthBar = nil
local lockButton = nil
local rebirthButton = nil
local muteButton = nil
local waveBanner = nil
local waveText = nil
local notifyFrame = nil
local remotes = nil

local function makeButton(name, text, parent, pos)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Position = pos
	b.Size = UDim2.fromOffset(150, 40)
	b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	b.BorderColor3 = Color3.fromRGB(255, 200, 60)
	b.BorderSizePixel = 2
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = 18
	b.Font = Enum.Font.SourceSansBold
	b.Parent = parent
	return b
end

local function makeLabel(name, parent, pos, size, textSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.TextSize = textSize
	l.Font = Enum.Font.SourceSansBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

function Hud.init(remotesRef)
	remotes = remotesRef
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "BuffetGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Money bar, top-center.
	local bar = Instance.new("Frame")
	bar.Name = "MoneyBar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 12)
	bar.Size = UDim2.fromOffset(420, 86)
	bar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	bar.BorderColor3 = Color3.fromRGB(255, 200, 60)
	bar.BorderSizePixel = 2
	bar.Parent = gui

	moneyLabel = makeLabel("Money", bar, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 34), 30)
	moneyLabel.Text = "$100"
	incomeLabel = makeLabel("Income", bar, UDim2.fromOffset(14, 42), UDim2.new(0.55, 0, 0, 20), 18)
	incomeLabel.Text = "$0/s"
	incomeLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	rebirthLabel = makeLabel("Rebirths", bar, UDim2.new(0.55, 0, 0, 42), UDim2.new(0.45, -14, 0, 20), 18)
	rebirthLabel.Text = "x1"
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 200, 60)

	-- Rebirth progress bar, under the money bar.
	local progBg = Instance.new("Frame")
	progBg.Name = "RebirthProgressBg"
	progBg.AnchorPoint = Vector2.new(0.5, 0)
	progBg.Position = UDim2.new(0.5, 0, 0, 104)
	progBg.Size = UDim2.fromOffset(420, 10)
	progBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	progBg.BorderSizePixel = 0
	progBg.Parent = gui
	rebirthBar = Instance.new("Frame")
	rebirthBar.Name = "RebirthProgress"
	rebirthBar.Size = UDim2.fromScale(0, 1)
	rebirthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	rebirthBar.BorderSizePixel = 0
	rebirthBar.Parent = progBg

	-- Action buttons, top-right.
	lockButton = makeButton("LockBase", "Lock Base (60s)", gui, UDim2.new(1, -164, 0, 12))
	rebirthButton = makeButton("Rebirth", "Rebirth", gui, UDim2.new(1, -164, 0, 60))
	muteButton = makeButton("Mute", "Sound: On", gui, UDim2.new(1, -164, 0, 108))
	muteButton.Size = UDim2.fromOffset(150, 32)

	-- Wave banner, centre-top, hidden until the wave.
	waveBanner = Instance.new("Frame")
	waveBanner.Name = "WaveBanner"
	waveBanner.AnchorPoint = Vector2.new(0.5, 0)
	waveBanner.Position = UDim2.new(0.5, 0, 0, 130)
	waveBanner.Size = UDim2.fromOffset(480, 52)
	waveBanner.BackgroundColor3 = Color3.fromRGB(120, 30, 20)
	waveBanner.BorderColor3 = Color3.fromRGB(255, 90, 40)
	waveBanner.BorderSizePixel = 2
	waveBanner.Visible = false
	waveBanner.Parent = gui
	waveText = makeLabel("WaveText", waveBanner, UDim2.fromOffset(10, 6), UDim2.new(1, -20, 1, -12), 20)
	waveText.Text = ""
	waveText.TextXAlignment = Enum.TextXAlignment.Center

	-- Hint, bottom-centre.
	local hint = makeLabel("Hint", gui, UDim2.new(0.5, -300, 1, -96), UDim2.fromOffset(600, 24), 18)
	hint.Text = "Click a character on the conveyor to buy it. Click a rival's character to steal it!"
	hint.TextColor3 = Color3.fromRGB(220, 220, 220)
	hint.TextXAlignment = Enum.TextXAlignment.Center

	-- Notifications, bottom-left, stacked.
	notifyFrame = Instance.new("Frame")
	notifyFrame.Name = "Notifications"
	notifyFrame.AnchorPoint = Vector2.new(0, 1)
	notifyFrame.Position = UDim2.new(0, 12, 1, -12)
	notifyFrame.Size = UDim2.fromOffset(420, 120)
	notifyFrame.BackgroundTransparency = 1
	notifyFrame.Parent = gui

	-- Title, bottom-right.
	local title = makeLabel("Title", gui, UDim2.new(1, -260, 1, -36), UDim2.fromOffset(250, 24), 18)
	title.Text = Config.GAME_NAME .. " - " .. Config.WORLD_NAME
	title.TextColor3 = Color3.fromRGB(255, 200, 60)
	title.TextXAlignment = Enum.TextXAlignment.Right

	-- Wire the buttons.
	lockButton.MouseButton1Click:Connect(function()
		Sound.play("click")
		if remotes and remotes.LockBase then
			remotes.LockBase:FireServer()
		end
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		Sound.play("click")
		if remotes and remotes.Rebirth then
			remotes.Rebirth:FireServer()
		end
	end)
	muteButton.MouseButton1Click:Connect(function()
		local m = Sound.toggleMute()
		muteButton.Text = m and "Sound: Off" or "Sound: On"
	end)
end

-- Refresh the HUD from a StateUpdate payload.
function Hud.update(state)
	if not moneyLabel then
		return
	end
	moneyLabel.Text = Util.formatMoney(state.money)
	incomeLabel.Text = Util.formatMoney(state.income) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.rebirths) .. " (x" .. tostring(state.multiplier) .. ")"
	if state.nextRebirth then
		local frac = math.clamp(state.totalEarned / state.nextRebirth, 0, 1)
		rebirthBar.Size = UDim2.fromScale(frac, 1)
		if state.canRebirth then
			rebirthButton.Text = "Rebirth! (READY)"
			rebirthButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
		else
			rebirthButton.Text = "Rebirth (" .. Util.formatMoney(state.totalEarned) .. " / " .. Util.formatMoney(state.nextRebirth) .. ")"
			rebirthButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		end
	else
		rebirthBar.Size = UDim2.fromScale(1, 1)
		rebirthButton.Text = "Rebirth (MAX)"
	end
	if state.lockRemaining and state.lockRemaining > 0 then
		lockButton.Text = "Locked (" .. tostring(math.ceil(state.lockRemaining)) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
	elseif state.lockCooldown and state.lockCooldown > 0 then
		lockButton.Text = "Lock (" .. tostring(math.ceil(state.lockCooldown)) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	else
		lockButton.Text = "Lock Base (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	end
end

-- Show a notification line for a few seconds.
function Hud.notify(msg)
	if not notifyFrame then
		return
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Text = msg
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 16
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = notifyFrame
	-- Stack newest at the bottom: shift older ones up.
	local children = notifyFrame:GetChildren()
	for i, child in ipairs(children) do
		if child:IsA("TextLabel") then
			child.Position = UDim2.new(0, 0, 1, -22 * (#children - i + 1))
		end
	end
	task.delay(6, function()
		label:Destroy()
	end)
end

-- Wave events from the server: "warning", "start", "end".
function Hud.wave(event, data)
	if not waveBanner then
		return
	end
	if event == "warning" then
		waveBanner.Visible = true
		waveText.Text = "HUNGER WAVE INCOMING! Get to your base!"
		Sound.play("wave")
		task.spawn(function()
			local left = data or 30
			while left > 0 and waveBanner.Visible do
				waveText.Text = "HUNGER WAVE INCOMING! Get to your base! (" .. tostring(left) .. "s)"
				task.wait(1)
				left -= 1
			end
		end)
	elseif event == "start" then
		waveBanner.Visible = true
		waveText.Text = "THE HUNGER WAVE IS HERE! RUN HOME!"
	elseif event == "end" then
		waveText.Text = "The wave has passed. The buffet is safe... for now."
		task.delay(4, function()
			waveBanner.Visible = false
		end)
	end
end

return Hud
