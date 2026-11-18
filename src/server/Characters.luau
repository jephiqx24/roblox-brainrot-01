-- Brainrot Buffet: character model building, spawn/despawn, mutation rolls.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Util = require(game:GetService("ReplicatedStorage").Shared.Util)

local Characters = {}

Characters.NextId = 1

-- Weighted random pick of a character definition.
function Characters.PickDefinition()
	local total = 0
	for _, def in ipairs(Config.Characters) do
		total += Config.RarityWeights[def.Rarity] or 1
	end
	local roll = math.random() * total
	for _, def in ipairs(Config.Characters) do
		roll -= Config.RarityWeights[def.Rarity] or 1
		if roll <= 0 then
			return def
		end
	end
	return Config.Characters[1]
end

-- Roll a mutation. Returns { Name, Multiplier } or nil for a normal character.
function Characters.RollMutation()
	local roll = math.random()
	local cumulative = 0
	for _, mut in ipairs(Config.Mutations) do
		cumulative += mut.Chance
		if roll < cumulative then
			return { Name = mut.Name, Multiplier = mut.Multiplier }
		end
	end
	return nil
end

function Characters.RateFor(def, mutation)
	local rate = def.Rate
	if mutation then
		rate *= mutation.Multiplier
	end
	return rate
end

-- Builds the visible model for a character: a chunky body in the rarity color,
-- a head ball, little feet, and a billboard with name / rarity / $/s.
function Characters.BuildModel(def, mutation, rate)
	local id = Characters.NextId
	Characters.NextId += 1

	local rarityColor = Config.RarityColors[def.Rarity] or Color3.fromRGB(200, 200, 200)

	local model = Instance.new("Model")
	model.Name = def.Name:gsub(" ", "")

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 3)
	body.Color = rarityColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.TopSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	-- Head ball on top, slightly lighter.
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.2, 2.2, 2.2)
	head.Position = Vector3.new(0, 2.4, 0)
	head.Color = rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Eyes.
	for _, x in ipairs({ -0.6, 0.6 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.5, 0.5, 0.5)
		eye.Position = Vector3.new(x, 2.6, 1.1)
		eye.Color = Color3.fromRGB(20, 20, 20)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
	end

	-- Feet.
	for _, x in ipairs({ -0.8, 0.8 }) do
		local foot = Instance.new("Part")
		foot.Name = "Foot"
		foot.Size = Vector3.new(1, 0.6, 1.4)
		foot.Position = Vector3.new(x, -1.7, 0.3)
		foot.Color = Color3.fromRGB(255, 160, 40)
		foot.Material = Enum.Material.SmoothPlastic
		foot.Anchored = true
		foot.CanCollide = false
		foot.Parent = model
	end

	-- Mutation tint: Golden glows yellow, Rainbow cycles bright, Diamond is icy.
	if mutation then
		if mutation.Name == "Golden" then
			body.Color = Color3.fromRGB(255, 210, 0)
			body.Material = Enum.Material.Neon
		elseif mutation.Name == "Rainbow" then
			body.Color = Color3.fromRGB(255, 80, 200)
			body.Material = Enum.Material.Neon
		elseif mutation.Name == "Diamond" then
			body.Color = Color3.fromRGB(180, 240, 255)
			body.Material = Enum.Material.Glass
		end
	end

	-- Billboard label.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(160, 60)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.5)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	local displayName = def.Name
	if mutation then
		displayName = mutation.Name .. " " .. def.Name
	end
	title.Text = displayName
	title.Parent = billboard

	local sub = Instance.new("TextLabel")
	sub.Position = UDim2.fromScale(0, 0.5)
	sub.Size = UDim2.fromScale(1, 0.5)
	sub.BackgroundTransparency = 1
	sub.TextColor3 = Color3.fromRGB(255, 230, 120)
	sub.TextStrokeTransparency = 0
	sub.TextScaled = true
	sub.Font = Enum.Font.SourceSans
	sub.Text = def.Rarity .. "  |  " .. Util.FormatMoney(rate) .. "/s"
	sub.Parent = billboard

	model:SetAttribute("CharId", id)
	model:SetAttribute("CharName", def.Name)
	model:SetAttribute("CharRarity", def.Rarity)
	model:SetAttribute("CharRate", rate)
	if mutation then
		model:SetAttribute("CharMutation", mutation.Name)
	end

	model.PrimaryPart = body
	return model, id
end

-- Moves a model so its body sits at the given position.
function Characters.PlaceModel(model, position)
	local body = model.PrimaryPart
	if body then
		model:PivotTo(CFrame.new(position))
	end
end

function Characters.Despawn(model)
	if model then
		model:Destroy()
	end
end

return Characters
