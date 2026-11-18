-- Brainrot Buffet: sounds.
-- Built-in rbxasset:// sounds only, no external assets.

local SoundService = game:GetService("SoundService")

local Sound = {}

-- Built-in Roblox sound assets.
local Sounds = {
	buy = "rbxasset://sounds/electronicpingshort.wav",
	error = "rbxasset://sounds/impact_water.mp3",
	wave = "rbxasset://sounds/breaking-news.mp3",
	steal = "rbxasset://sounds/electronicpingshort.wav",
	rebirth = "rbxasset://sounds/impact_water.mp3",
}

function Sound.Play(name)
	local asset = Sounds[name]
	if not asset then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = asset
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	-- Safety net: remove it even if Ended never fires.
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return Sound
