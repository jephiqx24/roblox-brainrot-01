-- Brainrot Buffet: client sounds.
-- Only Roblox's built-in sounds (rbxasset://), so nothing needs an asset
-- upload and nothing can be restricted. Mute gates every play.

local Sound = {}

local muted = false
local sounds = {}

local function getSound(name, asset)
	local s = sounds[name]
	if s then
		return s
	end
	s = Instance.new("Sound")
	s.Name = name
	s.SoundId = asset
	s.Volume = 0.5
	s.Parent = game:GetService("SoundService")
	sounds[name] = s
	return s
end

function Sound.play(name)
	if muted then
		return
	end
	local asset = nil
	if name == "buy" then
		asset = "rbxasset://sounds/electronicpingshort.wav"
	elseif name == "click" then
		asset = "rbxasset://sounds/button.wav"
	elseif name == "wave" then
		asset = "rbxasset://sounds/impact_water.mp3"
	elseif name == "rebirth" then
		asset = "rbxasset://sounds/electronicpingshort.wav"
	end
	if asset == nil then
		return
	end
	local s = getSound(name, asset)
	s:Play()
end

function Sound.toggleMute()
	muted = not muted
	return muted
end

function Sound.isMuted()
	return muted
end

return Sound
