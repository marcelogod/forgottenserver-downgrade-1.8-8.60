CustomBestiary = CustomBestiary or {}

CustomBestiary.monstersByRaceId = CustomBestiary.monstersByRaceId or {}
CustomBestiary.classOrder = CustomBestiary.classOrder or {}
CustomBestiary.classes = CustomBestiary.classes or {}
CustomBestiary.classRace = CustomBestiary.classRace or {}
local classesDirty = false

CustomBestiary.charmRunes = {
	{id = 0, name = "Wound", description = "Adds a chance to deal physical damage based on the creature's maximum hitpoints.", price = 600},
	{id = 1, name = "Enflame", description = "Adds a chance to deal fire damage based on the creature's maximum hitpoints.", price = 1000},
	{id = 2, name = "Poison", description = "Adds a chance to deal earth damage based on the creature's maximum hitpoints.", price = 600},
	{id = 3, name = "Freeze", description = "Adds a chance to deal ice damage based on the creature's maximum hitpoints.", price = 800},
	{id = 4, name = "Zap", description = "Adds a chance to deal energy damage based on the creature's maximum hitpoints.", price = 800},
	{id = 5, name = "Curse", description = "Adds a chance to deal death damage based on the creature's maximum hitpoints.", price = 900},
	{id = 6, name = "Cripple", description = "Adds a chance to slow the creature for a short time.", price = 500},
	{id = 7, name = "Parry", description = "Adds a chance to reflect damage back to the creature.", price = 1000},
	{id = 8, name = "Dodge", description = "Adds a chance to dodge an attack from the creature.", price = 600},
	{id = 9, name = "Adrenaline Burst", description = "Adds a chance to gain a short movement speed bonus.", price = 500},
	{id = 10, name = "Numb", description = "Adds a chance to slow the creature when it hits you.", price = 500},
	{id = 11, name = "Cleanse", description = "Adds a chance to remove harmful conditions caused by the creature.", price = 700},
	{id = 12, name = "Bless", description = "Adds a chance to reduce blessing loss pressure from this creature.", price = 2000},
	{id = 13, name = "Scavenge", description = "Adds a chance to improve creature product gathering.", price = 800},
	{id = 14, name = "Gut", description = "Adds a chance to improve creature product yield.", price = 800},
	{id = 15, name = "Low Blow", description = "Adds a chance to critically hit the creature.", price = 2000},
	{id = 16, name = "Divine Wrath", description = "Adds a chance to deal holy damage based on the creature's maximum hitpoints.", price = 1500},
	{id = 17, name = "Vampiric Embrace", description = "Adds a chance to leech hitpoints when damaging the creature.", price = 1500},
	{id = 18, name = "Void's Call", description = "Adds a chance to leech mana when damaging the creature.", price = 1500}
}

local charmById = {}
for _, charm in ipairs(CustomBestiary.charmRunes) do
	charmById[charm.id] = charm
end
CustomBestiary.charmById = charmById

local elementMap = {}
if COMBAT_PHYSICALDAMAGE then elementMap[COMBAT_PHYSICALDAMAGE] = 0 end
if COMBAT_FIREDAMAGE then elementMap[COMBAT_FIREDAMAGE] = 1 end
if COMBAT_EARTHDAMAGE then elementMap[COMBAT_EARTHDAMAGE] = 2 end
if COMBAT_ENERGYDAMAGE then elementMap[COMBAT_ENERGYDAMAGE] = 3 end
if COMBAT_ICEDAMAGE then elementMap[COMBAT_ICEDAMAGE] = 4 end
if COMBAT_HOLYDAMAGE then elementMap[COMBAT_HOLYDAMAGE] = 5 end
if COMBAT_DEATHDAMAGE then elementMap[COMBAT_DEATHDAMAGE] = 6 end
if COMBAT_HEALING then elementMap[COMBAT_HEALING] = 7 end

local function clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function resolveItemType(value)
	if value == nil then
		return nil
	end
	local itemType = ItemType(value)
	if itemType and itemType:getId() ~= 0 then
		return itemType
	end
	return nil
end

local function collectLoot(maskLoot)
	local loot = {}
	if type(maskLoot) ~= "table" then
		return loot
	end

	for _, entry in ipairs(maskLoot) do
		local itemType = resolveItemType(entry.id or entry.name)
		if itemType then
			loot[#loot + 1] = {
				itemId = itemType:getClientId(),
				name = itemType:getName(),
				chance = tonumber(entry.chance) or 0,
				maxCount = clamp(entry.maxCount or entry.count or 1, 1, 255)
			}
		end
	end

	table.sort(loot, function(a, b)
		if a.chance == b.chance then
			return a.name < b.name
		end
		return a.chance > b.chance
	end)
	return loot
end

local function collectElements(maskElements)
	local elements = {}
	if type(maskElements) ~= "table" then
		return elements
	end

	for _, element in ipairs(maskElements) do
		local elementId = elementMap[element.type]
		if elementId then
			elements[#elements + 1] = {
				id = elementId,
				percent = clamp(100 + (tonumber(element.percent) or 0), 0, 65535)
			}
		end
	end

	table.sort(elements, function(a, b) return a.id < b.id end)
	return elements
end

local function splitLocations(locations)
	local result = {}
	if type(locations) ~= "string" or locations == "" then
		return result
	end

	for part in locations:gmatch("[^,]+") do
		local trimmedPart = part:gsub("^%s*(.-)%s*$", "%1")
		if trimmedPart ~= "" then
			result[#result + 1] = trimmedPart
		end
	end

	if #result == 0 then
		result[1] = locations
	end
	return result
end

local function callMonsterMethod(monsterType, methodName, defaultValue)
	local method = monsterType and monsterType[methodName]
	if type(method) ~= "function" then
		return defaultValue
	end

	local ok, value = pcall(method, monsterType)
	if ok and value ~= nil then
		return value
	end
	return defaultValue
end

local function normalizeOutfit(outfit)
	if type(outfit) ~= "table" then
		return {type = 0, head = 0, body = 0, legs = 0, feet = 0, addons = 0}
	end

	return {
		type = clamp(outfit.lookType or outfit.type or outfit.typeEx or 0, 0, 0xFFFF),
		head = clamp(outfit.lookHead or outfit.head or 0, 0, 0xFF),
		body = clamp(outfit.lookBody or outfit.body or 0, 0, 0xFF),
		legs = clamp(outfit.lookLegs or outfit.legs or 0, 0, 0xFF),
		feet = clamp(outfit.lookFeet or outfit.feet or 0, 0, 0xFF),
		addons = clamp(outfit.lookAddons or outfit.addons or 0, 0, 0xFF)
	}
end

local function addToClass(entry)
	local className = entry.class
	if not CustomBestiary.classes[className] then
		CustomBestiary.classes[className] = {}
		CustomBestiary.classOrder[#CustomBestiary.classOrder + 1] = className
	end
	local raceOrder = tonumber(entry.race) or 0
	if not CustomBestiary.classRace[className] or raceOrder < CustomBestiary.classRace[className] then
		CustomBestiary.classRace[className] = raceOrder
	end
	CustomBestiary.classes[className][#CustomBestiary.classes[className] + 1] = entry
	classesDirty = true
end

function CustomBestiary.registerMonster(monsterType, mask)
	if type(mask) ~= "table" or type(mask.Bestiary) ~= "table" then
		return false
	end

	local raceId = tonumber(mask.raceId) or callMonsterMethod(monsterType, "raceId", 0) or 0
	if raceId <= 0 then
		return false
	end

	local oldEntry = CustomBestiary.monstersByRaceId[raceId]
	if oldEntry and CustomBestiary.classes[oldEntry.class] then
		for index, entry in ipairs(CustomBestiary.classes[oldEntry.class]) do
			if entry.raceId == raceId then
				table.remove(CustomBestiary.classes[oldEntry.class], index)
				break
			end
		end
		if #CustomBestiary.classes[oldEntry.class] == 0 then
			CustomBestiary.classes[oldEntry.class] = nil
			CustomBestiary.classRace[oldEntry.class] = nil
			for index, className in ipairs(CustomBestiary.classOrder) do
				if className == oldEntry.class then
					table.remove(CustomBestiary.classOrder, index)
					break
				end
			end
		end
	end

	local bestiary = mask.Bestiary
	local className = tostring(bestiary.class or "Unknown")
	local toKill = clamp(bestiary.toKill, 1, 0xFFFF)
	local firstUnlock = clamp(bestiary.FirstUnlock, 1, toKill)
	local secondUnlock = clamp(bestiary.SecondUnlock, firstUnlock, toKill)
	if (tonumber(bestiary.SecondUnlock) or 0) < (tonumber(bestiary.FirstUnlock) or 0) then
		print("[CustomBestiary] Warning: SecondUnlock < FirstUnlock for raceId " .. raceId)
	end
	local entry = {
		raceId = raceId,
		name = tostring(mask.name or callMonsterMethod(monsterType, "name", "unknown") or "unknown"),
		class = className,
		race = tonumber(bestiary.race) or 0,
		toKill = toKill,
		firstUnlock = firstUnlock,
		secondUnlock = secondUnlock,
		charmPoints = clamp(bestiary.CharmsPoints, 0, 0xFFFF),
		stars = clamp(bestiary.Stars, 1, 5),
		occurrence = clamp((tonumber(bestiary.Occurrence) or 0) + 1, 1, 4),
		locations = splitLocations(bestiary.Locations),
		outfit = normalizeOutfit(mask.outfit),
		loot = collectLoot(mask.loot),
		elements = collectElements(mask.elements),
		health = clamp(mask.maxHealth or mask.health or callMonsterMethod(monsterType, "maxHealth", 0) or 0, 0, 0xFFFFFFFF),
		experience = clamp(mask.experience or callMonsterMethod(monsterType, "experience", 0) or 0, 0, 0xFFFFFFFF),
		baseSpeed = clamp(mask.speed or callMonsterMethod(monsterType, "baseSpeed", 0) or 0, 0, 0xFFFF),
		armor = clamp(type(mask.defenses) == "table" and mask.defenses.armor or callMonsterMethod(monsterType, "armor", 0) or 0, 0, 0xFFFF)
	}

	CustomBestiary.monstersByRaceId[raceId] = entry
	addToClass(entry)
	return true
end

function CustomBestiary.getMonster(raceId)
	return CustomBestiary.monstersByRaceId[tonumber(raceId) or 0]
end

function CustomBestiary.getClasses()
	if classesDirty then
		table.sort(CustomBestiary.classOrder, function(a, b)
			local orderA = CustomBestiary.classRace[a] or 0
			local orderB = CustomBestiary.classRace[b] or 0
			if orderA == orderB then
				return a < b
			end
			return orderA < orderB
		end)
		for _, className in ipairs(CustomBestiary.classOrder) do
			table.sort(CustomBestiary.classes[className], function(a, b)
				return a.name < b.name
			end)
		end
		classesDirty = false
	end
	return CustomBestiary.classOrder, CustomBestiary.classes
end

function CustomBestiary.getProgress(entry, kills)
	kills = tonumber(kills) or 0
	if not entry or kills <= 0 then
		return 0
	end
	if kills >= entry.toKill then
		return 4
	end
	if kills >= entry.secondUnlock then
		return 3
	end
	if kills >= entry.firstUnlock then
		return 2
	end
	return 1
end

function CustomBestiary.getLootTier(chance)
	chance = tonumber(chance) or 0
	if chance < 1000 then
		return 4
	elseif chance < 10000 then
		return 3
	elseif chance < 50000 then
		return 2
	elseif chance < 100000 then
		return 1
	end
	return 0
end
