-- Brainrot Buffet: character models and the live character registry.
-- Builds each absurd food-animal hybrid as a Model of Parts, with a
-- BillboardGui label (name, rarity, $/sec) and a ClickDetector. Tracks every
-- character in the world by uid, whether it is walking the conveyor or
-- sitting on a base slot.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))

local Characters = {}

-- uid -> record { uid, def, mutation, rate, price, model, owner (Player or nil), slot (number or nil), onConveyor (boolean), progress (0..1 along the conveyor) }
local registry = {}

-- Accessory shapes: one extra part per character that makes it absurd.
local function addAccessory(model, def, bodyColor)
	local acc = def.accessory
	local function p(name, size, pos, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = pos
		part.Color = color
		part.Shape = shape or Enum.PartType.Block
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = model
		return part
	end
	local top = Vector3.new(0, 2.4, 0)
	if acc == "noodle" then
		p("Noodle", Vector3.new(0.6, 1.6, 0.6), top, Color3.fromRGB(255, 230, 150), Enum.PartType.Block)
	elseif acc == "shell" then
		p("Shell", Vector3.new(3.4, 1.2, 3.4), Vector3.new(0, 1.4, 0), Color3.fromRGB(230, 180, 60), Enum.PartType.Ball)
	elseif acc == "pepperoni" then
		p("Pepperoni", Vector3.new(1.4, 0.4, 1.4), Vector3.new(0.8, 1.2, 0.8), Color3.fromRGB(200, 60, 40), Enum.PartType.Block)
		p("Pepperoni2", Vector3.new(1.2, 0.4, 1.2), Vector3.new(-0.9, 1.2, -0.6), Color3.fromRGB(200, 60, 40), Enum.PartType.Block)
	elseif acc == "bun" then
		p("Bun", Vector3.new(3.2, 1.4, 3.2), top, Color3.fromRGB(240, 200, 120), Enum.PartType.Ball)
	elseif acc == "seaweed" then
		p("Seaweed", Vector3.new(3.6, 2.4, 0.6), Vector3.new(0, 1, 0), Color3.fromRGB(30, 90, 40), Enum.PartType.Block)
	elseif acc == "sprinkles" then
		for i = 1, 5 do
			local c = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(90, 180, 255), Color3.fromRGB(255, 220, 80), Color3.fromRGB(140, 255, 140), Color3.fromRGB(200, 120, 255) }
			p("Sprinkle" .. tostring(i), Vector3.new(0.5, 0.5, 0.5), Vector3.new((i - 3) * 0.9, 2.2, (i % 2 == 0) and 0.8 or -0.8), c[i])
		end
	elseif acc == "noodle-horn" then
		p("HornL", Vector3.new(0.7, 2.2, 0.7), Vector3.new(-1.2, 2.6, 0), Color3.fromRGB(255, 230, 150), Enum.PartType.Block)
		p("HornR", Vector3.new(0.7, 2.2, 0.7), Vector3.new(1.2, 2.6, 0), Color3.fromRGB(255, 230, 150), Enum.PartType.Block)
	elseif acc == "flaky-tail" then
		p("Tail", Vector3.new(1.6, 0.8, 2.4), Vector3.new(0, 0.6, -2.2), Color3.fromRGB(220, 170, 90), Enum.PartType.Wedge)
	elseif acc == "pearls" then
		for i = 1, 4 do
			p("Pearl" .. tostring(i), Vector3.new(1, 1, 1), Vector3.new((i - 2.5) * 1.2, 2.3, 0.6), Color3.fromRGB(90, 60, 40), Enum.PartType.Ball)
		end
	elseif acc == "straw-trunk" then
		p("Straw", Vector3.new(0.7, 3.2, 0.7), Vector3.new(0, 1.4, 1.6), Color3.fromRGB(255, 90, 90), Enum.PartType.Block)
	elseif acc == "golden-fur" then
		p("Crown", Vector3.new(2.2, 0.8, 2.2), top, Color3.fromRGB(255, 215, 0), Enum.PartType.Block)
	elseif acc == "cherry" then
		p("Cherry", Vector3.new(1.2, 1.2, 1.2), top, Color3.fromRGB(220, 30, 60), Enum.PartType.Ball)
	end
end

-- Build the Model for a character definition and mutation.
-- The model is anchored and positioned by the caller.
function Characters.buildModel(def, mutation)
	local model = Instance.new("Model")
	model.Name = def.name

	local bodyColor = def.color
	if mutation.color then
		bodyColor = mutation.color
	end

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = def.shape
	body.Size = Vector3.new(3, 3, 3)
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	-- Eyes: two dark spheres on the front.
	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeL"
	eyeL.Shape = Enum.PartType.Ball
	eyeL.Size = Vector3.new(0.6, 0.6, 0.6)
	eyeL.Position = Vector3.new(-0.7, 0.6, 1.5)
	eyeL.Color = Color3.fromRGB(20, 20, 20)
	eyeL.Anchored = true
	eyeL.CanCollide = false
	eyeL.Parent = model
	local eyeR = eyeL:Clone()
	eyeR.Name = "EyeR"
	eyeR.Position = Vector3.new(0.7, 0.6, 1.5)
	eyeR.Parent = model

	addAccessory(model, def, bodyColor)

	-- A soft glow for mutated characters.
	if mutation.name ~= "None" then
		local glow = Instance.new("PointLight")
		glow.Name = "MutationGlow"
		glow.Color = mutation.color or Color3.fromRGB(255, 255, 255)
		glow.Brightness = 1
		glow.Range = 10
		glow.Parent = body
	end

	-- PrimaryPart so the model moves as one.
	model.PrimaryPart = body
	return model
end

-- The BillboardGui label: name, rarity, $/sec, mutation. Rebuilt by the
-- caller whenever the rate changes.
function Characters.attachLabel(model, def, mutation, rate)
	local old = model:FindFirstChild("Label")
	if old then
		old:Destroy()
	end
	local rarity = Config.getRarity(def.rarity)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = model.PrimaryPart
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffset = Vector3.new(0, 4.5, 0)
	gui.AlwaysOnTop = true
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.BackgroundTransparency = 1
	title.Text = def.name
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.new(0, 0, 0.5, 0)
	sub.Size = UDim2.new(1, 0, 0.5, 0)
	sub.BackgroundTransparency = 1
	local mutText = mutation.name ~= "None" and (" [" .. mutation.name .. "]") or ""
	sub.Text = def.rarity .. mutText .. "  •  " .. Util.formatMoney(rate) .. "/s"
	sub.TextColor3 = rarity.color
	sub.TextScaled = true
	sub.Font = Enum.Font.SourceSans
	sub.Parent = gui
	gui.Parent = model
	return gui
end

-- Spawn a new character on the conveyor. Returns its record.
function Characters.spawn(world)
	local rarity = Config.rollRarity()
	local def = Config.rollCharacter(rarity)
	local mutation = Config.rollMutation()
	local uid = Util.nextUid()
	local model = Characters.buildModel(def, mutation)
	-- Base rate; the owner's multiplier applies when it is bought, so the
	-- conveyor shows the raw rate.
	Characters.attachLabel(model, def, mutation, def.rate * mutation.multiplier)
	model:PivotTo(CFrame.new(world.conveyorStart))
	model.Parent = world.folder

	local click = Instance.new("ClickDetector")
	click.Name = "BuyClick"
	click.MaxActivationDistance = 32
	click.Parent = model

	local record = {
		uid = uid,
		def = def,
		mutation = mutation,
		rate = def.rate * mutation.multiplier,
		price = def.cost,
		model = model,
		owner = nil,
		slot = nil,
		onConveyor = true,
		progress = 0,
	}
	model:SetAttribute("Uid", uid)
	model:SetAttribute("CharId", def.id)
	model:SetAttribute("OwnerId", 0)
	registry[uid] = record
	return record
end

function Characters.get(uid)
	return registry[uid]
end

function Characters.all()
	return registry
end

-- Move every conveyor character one step along the belt. Returns the uids
-- that reached the end and must despawn.
function Characters.stepConveyor(world, dt)
	local finished = {}
	for uid, rec in pairs(registry) do
		if rec.onConveyor then
			rec.progress += (Config.WALK_SPEED * dt) / Config.CONVEYOR_LENGTH
			if rec.progress >= 1 then
				table.insert(finished, uid)
			else
				local pos = world.conveyorStart:Lerp(world.conveyorEnd, rec.progress)
				rec.model:PivotTo(CFrame.new(pos))
			end
		end
	end
	return finished
end

-- Move a character onto a base slot. The caller has already validated the buy.
function Characters.placeOnBase(record, base, slotIndex, owner)
	local slot = base.slots[slotIndex]
	record.onConveyor = false
	record.owner = owner
	record.slot = slotIndex
	record.model:PivotTo(CFrame.new(slot.pos))
	slot.taken = true
	slot.charUid = record.uid
	record.model:SetAttribute("OwnerId", owner.UserId)
	-- Re-label with the owner's multiplier already folded into the rate by the caller.
	Characters.attachLabel(record.model, record.def, record.mutation, record.rate)
end

-- Remove a character from the world entirely (despawn or rebirth clear).
function Characters.remove(uid)
	local rec = registry[uid]
	if not rec then
		return
	end
	if rec.model then
		rec.model:Destroy()
	end
	registry[uid] = nil
end

-- Free a base slot without destroying the character (used by stealing: the
-- character moves, the old slot opens).
function Characters.freeSlot(base, slotIndex)
	local slot = base.slots[slotIndex]
	if slot then
		slot.taken = false
		slot.charUid = nil
	end
end

return Characters
