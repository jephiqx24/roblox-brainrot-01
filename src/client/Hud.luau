-- Brainrot Buffet: HUD.
-- Money, rebirths + multiplier, rebirth progress bar, wave timer, lock button,
-- and notification toasts.

local Util = require(game:GetService("ReplicatedStorage").Shared.Util)

local Hud = {}

Hud.OnLockPressed = nil -- set by Game.client.luau

local gui = nil
local moneyLabel = nil
local rebirthLabel = nil
local progressFill = nil
local progressLabel = nil
local waveLabel = nil
local lockButton = nil
local toastHolder = nil

local function makeLabel(parent, name, pos, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = pos
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.SourceSansBold
	label.Parent = parent
	return label
end

function Hud.Build(player)
	local playerGui = player:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "BuffetHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Top bar.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 10)
	topBar.Size = UDim2.new(0, 520, 0, 110)
	topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	topBar.BackgroundTransparency = 0.25
	topBar.BorderSizePixel = 0
	topBar.Parent = gui

	local title = makeLabel(topBar, "Title", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 28), "BRAINROT BUFFET", 24, Color3.fromRGB(255, 220, 90))
	title.TextXAlignment = Enum.TextXAlignment.Left

	moneyLabel = makeLabel(topBar, "Money", UDim2.new(0, 10, 0, 32), UDim2.new(1, -20, 0, 30), "$100", 26, Color3.fromRGB(120, 255, 120))
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left

	rebirthLabel = makeLabel(topBar, "Rebirths", UDim2.new(0, 10, 0, 62), UDim2.new(0.6, -10, 0, 20), "Rebirths: 0  (x1)", 16)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left

	waveLabel = makeLabel(topBar, "Wave", UDim2.new(0.6, 0, 0, 62), UDim2.new(0.4, -10, 0, 20), "Wave in 180s", 16, Color3.fromRGB(255, 150, 150))
	waveLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Rebirth progress bar.
	local barBack = Instance.new("Frame")
	barBack.Name = "ProgressBack"
	barBack.Position = UDim2.new(0, 10, 0, 86)
	barBack.Size = UDim2.new(1, -20, 0, 14)
	barBack.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
	barBack.BorderSizePixel = 0
	barBack.Parent = topBar

	progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = barBack

	progressLabel = makeLabel(topBar, "Progress", UDim2.new(0, 10, 0, 86), UDim2.new(1, -20, 0, 14), "", 12)
	progressLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Lock base button (bottom right).
	lockButton = Instance.new("TextButton")
	lockButton.Name = "LockButton"
	lockButton.AnchorPoint = Vector2.new(1, 1)
	lockButton.Position = UDim2.new(1, -16, 1, -16)
	lockButton.Size = UDim2.fromOffset(170, 48)
	lockButton.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
	lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockButton.TextSize = 18
	lockButton.Font = Enum.Font.SourceSansBold
	lockButton.Text = "LOCK BASE (60s)"
	lockButton.Parent = gui
	lockButton.MouseButton1Click:Connect(function()
		if Hud.OnLockPressed then
			Hud.OnLockPressed()
		end
	end)

	-- Hint label (bottom left).
	local hint = makeLabel(gui, "Hint", UDim2.new(0, 16, 1, -40), UDim2.new(0, 420, 0, 24), "Click a character on the conveyor to buy it!", 16, Color3.fromRGB(230, 230, 230))
	hint.TextXAlignment = Enum.TextXAlignment.Left

	-- Toast holder (top center, below the top bar).
	toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.new(0.5, 0, 0, 130)
	toastHolder.Size = UDim2.new(0, 480, 0, 200)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = gui
end

function Hud.Update(snapshot)
	if not gui then
		return
	end
	moneyLabel.Text = Util.FormatMoney(snapshot.Money)
	rebirthLabel.Text = "Rebirths: " .. snapshot.Rebirths .. "  (x" .. snapshot.Multiplier .. ")"

	if snapshot.NextRebirth then
		local frac = Util.Clamp(snapshot.TotalEarned / snapshot.NextRebirth, 0, 1)
		progressFill.Size = UDim2.fromScale(frac, 1)
		progressLabel.Text = Util.FormatShort(snapshot.TotalEarned) .. " / " .. Util.FormatShort(snapshot.NextRebirth) .. " to next rebirth"
	else
		progressFill.Size = UDim2.fromScale(1, 1)
		progressLabel.Text = "MAX REBIRTHS!"
	end

	if snapshot.WaveIn then
		local secs = math.ceil(snapshot.WaveIn)
		if secs <= 30 then
			waveLabel.Text = "WAVE IN " .. secs .. "s!"
			waveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		else
			waveLabel.Text = "Wave in " .. secs .. "s"
			waveLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
		end
	end

	if snapshot.LockActiveIn and snapshot.LockActiveIn > 0 then
		lockButton.Text = "LOCKED (" .. math.ceil(snapshot.LockActiveIn) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
	elseif snapshot.LockReadyIn and snapshot.LockReadyIn > 0 then
		lockButton.Text = "LOCK (" .. math.ceil(snapshot.LockReadyIn) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
	else
		lockButton.Text = "LOCK BASE (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
	end
end

function Hud.Toast(message, kind)
	if not toastHolder then
		return
	end
	local colors = {
		info = Color3.fromRGB(50, 50, 65),
		success = Color3.fromRGB(40, 140, 70),
		error = Color3.fromRGB(160, 50, 50),
		warning = Color3.fromRGB(180, 120, 20),
	}
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 36)
	toast.BackgroundColor3 = colors[kind] or colors.info
	toast.BackgroundTransparency = 0.15
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.TextSize = 16
	toast.Font = Enum.Font.SourceSansBold
	toast.Text = message
	toast.TextWrapped = true
	toast.Parent = toastHolder

	-- Stack toasts from the top.
	local count = 0
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("TextLabel") then
			count += 1
			child.Position = UDim2.new(0, 0, 0, (count - 1) * 40)
		end
	end

	task.delay(4, function()
		if toast.Parent then
			toast:Destroy()
		end
		-- Re-stack what is left.
		local i = 0
		for _, child in ipairs(toastHolder:GetChildren()) do
			if child:IsA("TextLabel") then
				i += 1
				child.Position = UDim2.new(0, 0, 0, (i - 1) * 40)
			end
		end
	end)
end

return Hud
