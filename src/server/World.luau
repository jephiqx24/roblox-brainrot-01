-- Brainrot Buffet: builds the world at runtime into a Folder named BuffetWorld.
-- Plaza, conveyor, buffet table, 8 bases, trees, lamps, fence and a hidden wave wall.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local World = {}

World.Bases = {} -- list of { Index, Center, SpawnPos, Slots = { Vector3, ... }, Platform, Owner }
World.Conveyor = nil

local function makePart(parent, name, size, pos, color, material, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = canCollide
	part.Parent = parent
	return part
end

local function buildBase(folder, index, angle)
	local radius = Config.Bases.Radius
	local cx = math.cos(angle) * radius
	local cz = math.sin(angle) * radius
	local center = Vector3.new(cx, 1, cz)

	local colors = {
		Color3.fromRGB(255, 120, 120),
		Color3.fromRGB(255, 190, 80),
		Color3.fromRGB(255, 240, 100),
		Color3.fromRGB(120, 220, 120),
		Color3.fromRGB(100, 200, 255),
		Color3.fromRGB(170, 120, 255),
		Color3.fromRGB(255, 120, 220),
		Color3.fromRGB(180, 180, 190),
	}
	local color = colors[((index - 1) % #colors) + 1]
	local size = Config.Bases.Size

	local baseFolder = Instance.new("Folder")
	baseFolder.Name = "Base" .. index
	baseFolder.Parent = folder

	-- Platform.
	local platform = makePart(baseFolder, "Platform", Vector3.new(size, 1, size), Vector3.new(cx, 1, cz), color, Enum.Material.SmoothPlastic, true)
	platform.TopSurface = Enum.SurfaceType.Smooth

	-- Rim walls on the two far sides so characters read as "on" the base.
	makePart(baseFolder, "RimA", Vector3.new(size, 2, 1), Vector3.new(cx, 2, cz - size / 2 + 0.5), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic, true)
	makePart(baseFolder, "RimB", Vector3.new(size, 2, 1), Vector3.new(cx, 2, cz + size / 2 - 0.5), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic, true)

	-- Sign post + billboard with the base number.
	local post = makePart(baseFolder, "SignPost", Vector3.new(1, 8, 1), Vector3.new(cx, 5, cz - size / 2 + 1), Color3.fromRGB(90, 60, 30), Enum.Material.Wood, true)
	local board = Instance.new("BillboardGui")
	board.Name = "BaseSign"
	board.Size = UDim2.fromOffset(140, 50)
	board.StudsOffset = Vector3.new(0, 5, 0)
	board.AlwaysOnTop = true
	board.Parent = post
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "BASE " .. index
	label.Parent = board

	-- Six slot pads in a 3x2 grid.
	local slots = {}
	local colOffsets = { -8, 0, 8 }
	local rowOffsets = { -5, 5 }
	for _, rz in ipairs(rowOffsets) do
		for _, rx in ipairs(colOffsets) do
			local slotPos = Vector3.new(cx + rx, 1.6, cz + rz)
			makePart(baseFolder, "SlotPad", Vector3.new(5, 0.2, 5), slotPos, Color3.fromRGB(255, 255, 255), Enum.Material.Neon, false)
			table.insert(slots, Vector3.new(cx + rx, 2.5, cz + rz))
		end
	end

	-- Spawn position: the edge of the base facing the center plaza.
	local dirToCenter = Vector3.new(-math.cos(angle), 0, -math.sin(angle))
	local spawnPos = Vector3.new(cx, 3, cz) + dirToCenter * (size / 2 - 2)

	local base = {
		Index = index,
		Center = center,
		SpawnPos = spawnPos,
		Slots = slots,
		Platform = platform,
		Owner = nil,
	}
	table.insert(World.Bases, base)
	return base
end

function World.Build()
	local folder = Instance.new("Folder")
	folder.Name = "BuffetWorld"
	folder.Parent = workspace

	-- Central plaza: a big tan slab.
	makePart(folder, "Plaza", Vector3.new(150, 1, 90), Vector3.new(0, 0.5, 0), Color3.fromRGB(210, 180, 140), Enum.Material.Sand, true)

	-- SpawnLocation on the plaza so players always spawn on top, not under it.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 1.5, 20)
	spawn.Color = Color3.fromRGB(80, 220, 100)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 0
	spawn.Parent = folder

	-- Conveyor belt along X at z = 0.
	local belt = makePart(folder, "Conveyor", Vector3.new(Config.Conveyor.Length, 1, 10), Vector3.new(0, 1, Config.Conveyor.Z), Color3.fromRGB(45, 45, 55), Enum.Material.SmoothPlastic, true)
	World.Conveyor = belt
	-- Yellow stripes on the belt.
	for x = -55, 55, 10 do
		makePart(folder, "Stripe", Vector3.new(4, 0.2, 10), Vector3.new(x, 1.6, 0), Color3.fromRGB(255, 220, 0), Enum.Material.Neon, false)
	end
	-- Belt side rails.
	makePart(folder, "RailA", Vector3.new(120, 1, 1), Vector3.new(0, 2, -5.5), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, true)
	makePart(folder, "RailB", Vector3.new(120, 1, 1), Vector3.new(0, 2, 5.5), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, true)

	-- Buffet table at the far end of the plaza.
	local tableTop = makePart(folder, "BuffetTable", Vector3.new(30, 1, 8), Vector3.new(0, 4, -38), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, true)
	tableTop.TopSurface = Enum.SurfaceType.Smooth
	makePart(folder, "TableLegA", Vector3.new(1, 4, 1), Vector3.new(-13, 2, -38), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, true)
	makePart(folder, "TableLegB", Vector3.new(1, 4, 1), Vector3.new(13, 2, -38), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, true)
	-- Dishes on the table: little colored bowls.
	local dishColors = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 200, 80), Color3.fromRGB(120, 220, 120), Color3.fromRGB(120, 180, 255) }
	for i, dc in ipairs(dishColors) do
		makePart(folder, "Dish" .. i, Vector3.new(4, 1, 4), Vector3.new(-12 + (i - 1) * 8, 5, -38), dc, Enum.Material.SmoothPlastic, false)
	end

	-- The 8 bases in a circle.
	for i = 1, Config.Bases.Count do
		local angle = (i - 1) * (math.pi * 2 / Config.Bases.Count)
		buildBase(folder, i, angle)
	end

	-- Trees in a ring outside the bases.
	for i = 1, 16 do
		local angle = (i - 1) * (math.pi * 2 / 16) + 0.2
		local r = 150 + (i % 3) * 12
		local tx = math.cos(angle) * r
		local tz = math.sin(angle) * r
		makePart(folder, "Trunk" .. i, Vector3.new(2, 8, 2), Vector3.new(tx, 4, tz), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, true)
		local leaves = makePart(folder, "Leaves" .. i, Vector3.new(9, 9, 9), Vector3.new(tx, 12, tz), Color3.fromRGB(60, 160, 60), Enum.Material.SmoothPlastic, false)
		leaves.Shape = Enum.PartType.Ball
	end

	-- Lamps between plaza and bases.
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8) + (math.pi / 8)
		local lx = math.cos(angle) * 125
		local lz = math.sin(angle) * 125
		makePart(folder, "LampPost" .. i, Vector3.new(1, 7, 1), Vector3.new(lx, 3.5, lz), Color3.fromRGB(50, 50, 60), Enum.Material.Metal, true)
		makePart(folder, "LampLight" .. i, Vector3.new(2, 2, 2), Vector3.new(lx, 7.5, lz), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, false)
	end

	-- Fence ring at radius 175.
	for i = 1, 48 do
		local angle = (i - 1) * (math.pi * 2 / 48)
		local fx = math.cos(angle) * 175
		local fz = math.sin(angle) * 175
		makePart(folder, "Fence" .. i, Vector3.new(2, 3, 22), Vector3.new(fx, 1.5, fz), Color3.fromRGB(200, 170, 120), Enum.Material.Wood, true)
	end

	-- Hidden wave wall: invisible, used by the Hunger Wave sweep visual.
	local wall = makePart(folder, "WaveWall", Vector3.new(360, 30, 1), Vector3.new(0, 15, -180), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, false)
	wall.Transparency = 1
	wall.CanCollide = false
	World.WaveWall = wall

	return folder
end

return World
