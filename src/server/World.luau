-- Brainrot Buffet: builds the 3D world at runtime.
-- The place file only holds the baseplate; everything else (plaza, conveyor,
-- player bases, decorations, the Hunger Wave wall) is built here so the
-- world is code, not a binary blob. build() returns the references the
-- other server modules need.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local World = {}

local BASE_RADIUS = 100
local BASE_SIZE = 26
local SLOT_ROWS = 2
local SLOT_COLS = 3

local BASE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(120, 255, 140),
	Color3.fromRGB(255, 220, 100),
	Color3.fromRGB(220, 140, 255),
	Color3.fromRGB(255, 160, 80),
	Color3.fromRGB(100, 230, 230),
	Color3.fromRGB(255, 130, 200),
}

local function part(name, size, pos, color, parent, opts)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.CanCollide = true
	p.Material = Enum.Material.SmoothPlastic
	if opts then
		if opts.shape then
			p.Shape = opts.shape
		end
		if opts.material then
			p.Material = opts.material
		end
		if opts.transparency then
			p.Transparency = opts.transparency
		end
		if opts.canCollide ~= nil then
			p.CanCollide = opts.canCollide
		end
		if opts.rotation then
			p.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(opts.rotation), 0)
		end
	end
	p.Parent = parent
	return p
end

local function makeTree(parent, pos)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local trunk = part("Trunk", Vector3.new(2, 8, 2), pos + Vector3.new(0, 4, 0), Color3.fromRGB(120, 80, 40), tree, { material = Enum.Material.Wood })
	trunk.CanCollide = false
	local leaves = part("Leaves", Vector3.new(9, 9, 9), pos + Vector3.new(0, 11, 0), Color3.fromRGB(60, 160, 70), tree, { shape = Enum.PartType.Ball, material = Enum.Material.Grass })
	leaves.CanCollide = false
	tree.Parent = parent
	return tree
end

local function makeLamp(parent, pos)
	local lamp = Instance.new("Model")
	lamp.Name = "Lamp"
	part("Pole", Vector3.new(1, 10, 1), pos + Vector3.new(0, 5, 0), Color3.fromRGB(60, 60, 60), lamp).CanCollide = false
	local bulb = part("Bulb", Vector3.new(3, 3, 3), pos + Vector3.new(0, 11, 0), Color3.fromRGB(255, 240, 170), lamp, { shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	bulb.CanCollide = false
	lamp.Parent = parent
	return lamp
end

-- Build one player base: a platform, a sign, and BASE_SLOTS pads.
local function makeBase(parent, index, center)
	local color = BASE_COLORS[((index - 1) % #BASE_COLORS) + 1]
	local base = Instance.new("Model")
	base.Name = "Base" .. tostring(index)

	local platform = part("Platform", Vector3.new(BASE_SIZE, 2, BASE_SIZE), center + Vector3.new(0, 1, 0), color, base, { material = Enum.Material.Concrete })
	platform.TopSurface = Enum.SurfaceType.Smooth

	-- A rim so the base reads as a plot.
	part("Rim", Vector3.new(BASE_SIZE + 2, 1, 2), center + Vector3.new(0, 1, BASE_SIZE / 2 + 1), Color3.fromRGB(255, 255, 255), base).CanCollide = false
	part("Rim", Vector3.new(BASE_SIZE + 2, 1, 2), center + Vector3.new(0, 1, -BASE_SIZE / 2 - 1), Color3.fromRGB(255, 255, 255), base).CanCollide = false
	part("Rim", Vector3.new(2, 1, BASE_SIZE + 2), center + Vector3.new(BASE_SIZE / 2 + 1, 1, 0), Color3.fromRGB(255, 255, 255), base).CanCollide = false
	part("Rim", Vector3.new(2, 1, BASE_SIZE + 2), center + Vector3.new(-BASE_SIZE / 2 - 1, 1, 0), Color3.fromRGB(255, 255, 255), base).CanCollide = false

	-- Sign post at the back of the base, facing the plaza.
	local dirToCenter = (Vector3.new(0, 0, 0) - center)
	local yaw = math.deg(math.atan2(-dirToCenter.X, -dirToCenter.Z))
	local signPos = center + Vector3.new(0, 6, 0) + (dirToCenter.Unit * (BASE_SIZE / 2 - 2))
	local sign = part("Sign", Vector3.new(10, 5, 1), signPos, Color3.fromRGB(40, 40, 40), base, { rotation = yaw })
	sign.CanCollide = false
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Name = "OwnerLabel"
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "Empty Base"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextScaled = true
	signText.Font = Enum.Font.SourceSansBold
	signText.Parent = signGui

	-- Slot pads: 2 rows x 3 columns.
	local slots = {}
	local startX = -7
	local startZ = -4
	local stepX = 7
	local stepZ = 8
	local n = 0
	for row = 1, SLOT_ROWS do
		for col = 1, SLOT_COLS do
			n += 1
			local padPos = center + Vector3.new(startX + (col - 1) * stepX, 2.6, startZ + (row - 1) * stepZ)
			local pad = part("Slot" .. tostring(n), Vector3.new(5, 1, 5), padPos, Color3.fromRGB(255, 255, 255), base, { transparency = 0.4 })
			pad.CanCollide = false
			slots[n] = { pad = pad, pos = padPos + Vector3.new(0, 3, 0), taken = false, charUid = nil }
		end
	end

	base.Parent = parent
	return {
		index = index,
		model = base,
		center = center,
		color = color,
		slots = slots,
		owner = nil,
		signText = signText,
		spawnPos = center + Vector3.new(0, 4, 0),
	}
end

function World.build()
	local ws = game:GetService("Workspace")
	local folder = Instance.new("Folder")
	folder.Name = "BuffetWorld"
	folder.Parent = ws

	-- Central plaza: a flat carpet where the conveyor runs.
	local plaza = part("Plaza", Vector3.new(150, 1, 90), Vector3.new(0, 0.5, 0), Color3.fromRGB(210, 180, 140), folder, { material = Enum.Material.Concrete })
	plaza.CanCollide = false

	-- The conveyor: a long belt down the middle of the plaza.
	local belt = part("Conveyor", Vector3.new(Config.CONVEYOR_LENGTH, 1, 10), Vector3.new(0, 1, 0), Color3.fromRGB(70, 70, 80), folder, { material = Enum.Material.Metal })
	belt.TopSurface = Enum.SurfaceType.Smooth
	-- Belt stripes so the motion reads.
	for i = 0, 11 do
		local stripe = part("Stripe", Vector3.new(1, 0.2, 10), Vector3.new(-55 + i * 10, 1.6, 0), Color3.fromRGB(255, 200, 60), folder)
		stripe.CanCollide = false
	end

	-- The Buffet Table: a giant table at the plaza's north end, the world's landmark.
	local tableTop = part("BuffetTable", Vector3.new(40, 3, 16), Vector3.new(0, 4, -38), Color3.fromRGB(255, 255, 255), folder, { material = Enum.Material.Concrete })
	tableTop.CanCollide = false
	part("TableLeg", Vector3.new(3, 4, 3), Vector3.new(-16, 1, -38), Color3.fromRGB(120, 80, 40), folder).CanCollide = false
	part("TableLeg", Vector3.new(3, 4, 3), Vector3.new(16, 1, -38), Color3.fromRGB(120, 80, 40), folder).CanCollide = false
	-- Food on the table: a few giant, colourful blobs.
	part("Feast1", Vector3.new(6, 5, 6), Vector3.new(-10, 8, -38), Color3.fromRGB(255, 120, 120), folder, { shape = Enum.PartType.Ball }).CanCollide = false
	part("Feast2", Vector3.new(5, 6, 5), Vector3.new(0, 8.5, -38), Color3.fromRGB(255, 210, 60), folder, { shape = Enum.PartType.Ball }).CanCollide = false
	part("Feast3", Vector3.new(7, 4, 7), Vector3.new(11, 7.5, -38), Color3.fromRGB(140, 220, 120), folder, { shape = Enum.PartType.Ball }).CanCollide = false

	-- Bases in a circle, offset 22.5 degrees so none sits on the conveyor line.
	local bases = {}
	for i = 1, Config.BASE_COUNT do
		local angle = math.rad(22.5 + (i - 1) * 45)
		local center = Vector3.new(math.cos(angle) * BASE_RADIUS, 0, math.sin(angle) * BASE_RADIUS)
		bases[i] = makeBase(folder, i, center)
	end

	-- Trees and lamps around the edge.
	for i = 1, 16 do
		local angle = math.rad(i * 22.5)
		local r = 150 + (i % 3) * 12
		local pos = Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		makeTree(folder, pos)
		if i % 2 == 0 then
			makeLamp(folder, Vector3.new(math.cos(angle) * 125, 0, math.sin(angle) * 125))
		end
	end

	-- A fence ring so the map reads as bounded.
	for i = 1, 24 do
		local angle = math.rad(i * 15)
		local pos = Vector3.new(math.cos(angle) * 175, 2, math.sin(angle) * 175)
		part("Fence", Vector3.new(46, 4, 1), pos, Color3.fromRGB(200, 200, 200), folder, { rotation = math.deg(angle) + 90 }).CanCollide = false
	end

	-- The Hunger Wave wall: hidden until the wave (fully transparent, parked far away).
	local waveWall = part("WaveWall", Vector3.new(2, 40, 360), Vector3.new(-400, 20, 0), Color3.fromRGB(255, 90, 40), folder, { material = Enum.Material.Neon, transparency = 1 })
	waveWall.CanCollide = false

	return {
		folder = folder,
		bases = bases,
		conveyorStart = Vector3.new(-Config.CONVEYOR_LENGTH / 2, 3, 0),
		conveyorEnd = Vector3.new(Config.CONVEYOR_LENGTH / 2, 3, 0),
		waveWall = waveWall,
		plazaCenter = Vector3.new(0, 0, 0),
	}
end

return World
