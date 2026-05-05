ImbuingWindow = ImbuingWindow or {}

local WINDOW_OPCODE = 0xEB
local CLOSE_OPCODE = 0xEC
local RESOURCE_BALANCE_OPCODE = 0xEE

local SUCCESS_RATE = 100
local PROTECTION_COST = 0

local sessions = {}
local cachedDefinitions = nil
local definitionsById = {}
local definitionsByTypeBase = {}

local function isEnabled()
	return configManager.getBoolean(configKeys.IMBUEMENT_SYSTEM_ENABLED)
end

local function protocolId(def)
	return (def.imbuementType * 100) + def.baseId
end

local function ensureDefinitions()
	if cachedDefinitions then
		return
	end

	cachedDefinitions = Game.getImbuementDefinitions() or {}
	table.sort(cachedDefinitions, function(a, b)
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.baseId < b.baseId
	end)

	for _, def in ipairs(cachedDefinitions) do
		local id = protocolId(def)
		definitionsById[id] = def
		definitionsByTypeBase[def.imbuementType .. ":" .. def.baseId] = def
	end
end

local function getDefinitionByImbuement(imbuement)
	if not imbuement then
		return nil
	end

	ensureDefinitions()
	return definitionsByTypeBase[imbuement:getType() .. ":" .. imbuement:getBaseId()]
end

local function displayName(def)
	if def.baseName and def.baseName ~= "" then
		return def.baseName .. " " .. def.name
	end
	return def.name
end

local function getItemName(itemId)
	local ok, itemType = pcall(ItemType, itemId)
	if not ok or not itemType then
		return "item"
	end

	local name = itemType:getName()
	if not name or name == "" then
		return "item"
	end
	return name
end

local function writeImbuementInfo(msg, def)
	msg:addU32(protocolId(def))
	msg:addString(displayName(def))
	msg:addString(def.description or "")
	msg:addString(def.name or "")
	msg:addU16(def.iconId or 0)
	msg:addU32(def.duration or 0)
	msg:addByte(def.premium and 1 or 0)

	local items = def.items or {}
	msg:addByte(#items)
	for _, req in ipairs(items) do
		msg:addU16(req.itemId)
		msg:addString(string.format("%dx %s", req.count, getItemName(req.itemId)))
		msg:addU16(req.count)
	end

	msg:addU32(def.price or 0)
	msg:addByte(SUCCESS_RATE)
	msg:addU32(PROTECTION_COST)
end

local function writeFallbackImbuementInfo(msg, imbuement)
	msg:addU32(0)
	msg:addString("Unknown Imbuement")
	msg:addString("")
	msg:addString("Unknown")
	msg:addU16(0)
	msg:addU32(imbuement and imbuement:getDuration() or 0)
	msg:addByte(0)
	msg:addByte(0)
	msg:addU32(0)
	msg:addByte(SUCCESS_RATE)
	msg:addU32(PROTECTION_COST)
end

local function getActiveImbuements(item)
	local imbuements = item:getImbuements()
	if not imbuements then
		return {}
	end
	return imbuements
end

local function getActiveImbuementCount(activeImbuements)
	local count = 0
	for _ in ipairs(activeImbuements) do
		count = count + 1
	end
	return count
end

local function getApplicableDefinitions(item)
	ensureDefinitions()

	local activeTypes = {}
	for _, imbuement in ipairs(getActiveImbuements(item)) do
		activeTypes[imbuement:getType()] = true
	end

	local list = {}
	for _, def in ipairs(cachedDefinitions) do
		if not activeTypes[def.imbuementType] and item:canApplyImbuement(def.categoryId, def.baseId) then
			table.insert(list, def)
		end
	end
	return list
end

local function writeNeededItems(msg, player, definitions)
	local itemIds = {}
	local seen = {}

	for _, def in ipairs(definitions) do
		for _, req in ipairs(def.items or {}) do
			if not seen[req.itemId] then
				seen[req.itemId] = true
				table.insert(itemIds, req.itemId)
			end
		end
	end

	table.sort(itemIds)
	msg:addU32(#itemIds)
	for _, itemId in ipairs(itemIds) do
		msg:addU16(itemId)
		msg:addU16(math.min(player:getItemCount(itemId, -1, true), 0xFFFF))
	end
end

local function sendBalances(player)
	local bankMsg = NetworkMessage(player)
	bankMsg:addByte(RESOURCE_BALANCE_OPCODE)
	bankMsg:addByte(0)
	bankMsg:addU64(player:getBankBalance())
	bankMsg:sendToPlayer(player)

	local inventoryMsg = NetworkMessage(player)
	inventoryMsg:addByte(RESOURCE_BALANCE_OPCODE)
	inventoryMsg:addByte(1)
	inventoryMsg:addU64(player:getMoney())
	inventoryMsg:sendToPlayer(player)
end

local function findEquipment(container)
	for i = 0, container:getSize() - 1 do
		local item = container:getItem(i)
		if item and item:getImbuementSlots() > 0 then
			return item
		end
	end
	return nil
end

local function clearSession(player)
	sessions[player:getId()] = nil
end

local function itemBelongsToPlayer(player, item)
	return item and item:getTopParent() == player
end

local function validateSessionItem(player, item)
	if not item or item:getImbuementSlots() <= 0 then
		clearSession(player)
		return false
	end

	local owner = item:getAttribute(ITEM_ATTRIBUTE_OWNER)
	if owner and owner ~= 0 and owner ~= player:getId() then
		clearSession(player)
		return false
	end

	return true
end

local function getSessionEquipment(player)
	local session = sessions[player:getId()]
	if not session then
		return nil
	end

	local item = Item(session.itemUid)
	if not validateSessionItem(player, item) then
		return nil
	end

	if session.containerUid then
		local container = Container(session.containerUid)
		if not container then
			clearSession(player)
			return nil
		end

		local found = false
		for i = 0, container:getSize() - 1 do
			if container:getItem(i) == item then
				found = true
				break
			end
		end
		if not found then
			clearSession(player)
			return nil
		end
	elseif not itemBelongsToPlayer(player, item) then
		clearSession(player)
		return nil
	end

	return item
end

local function sendWindow(player, item)
	local slots = item:getImbuementSlots()
	if slots <= 0 then
		return false
	end

	local definitions = getApplicableDefinitions(item)
	sendBalances(player)

	local msg = NetworkMessage(player)
	msg:addByte(WINDOW_OPCODE)
	msg:addU16(item:getId())
	msg:addByte(math.min(slots, 3))

	local activeImbuements = getActiveImbuements(item)
	for slot = 1, math.min(slots, 3) do
		local imbuement = activeImbuements[slot]
		if imbuement then
			local def = getDefinitionByImbuement(imbuement)
			msg:addByte(1)
			if def then
				writeImbuementInfo(msg, def)
				msg:addU32(imbuement:getDuration())
				msg:addU32(def.removeCost or 0)
			else
				writeFallbackImbuementInfo(msg, imbuement)
				msg:addU32(imbuement:getDuration())
				msg:addU32(0)
			end
		else
			msg:addByte(0)
		end
	end

	msg:addU16(#definitions)
	for _, def in ipairs(definitions) do
		writeImbuementInfo(msg, def)
	end

	writeNeededItems(msg, player, definitions)
	msg:sendToPlayer(player)
	return true
end

function ImbuingWindow.open(player, container, silent)
	if not isEnabled() then
		if not silent then
			player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		end
		return false
	end

	local item = findEquipment(container)
	if not item then
		if not silent then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "Place equipment with imbuement slots on the workbench.")
		end
		return false
	end

	local owner = item:getAttribute(ITEM_ATTRIBUTE_OWNER)
	if owner and owner ~= 0 and owner ~= player:getId() then
		player:sendCancelMessage("This equipment does not belong to you.")
		return true
	end

	sessions[player:getId()] = {containerUid = container.uid, itemUid = item.uid}
	return sendWindow(player, item)
end

function ImbuingWindow.openItem(player, item, silent)
	if not isEnabled() then
		if not silent then
			player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		end
		return false
	end

	if not item or item:getImbuementSlots() <= 0 then
		if not silent then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "Use an item with imbuement slots.")
		end
		return false
	end

	if not itemBelongsToPlayer(player, item) then
		if not silent then
			player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		end
		return false
	end

	local owner = item:getAttribute(ITEM_ATTRIBUTE_OWNER)
	if owner and owner ~= 0 and owner ~= player:getId() then
		player:sendCancelMessage("This equipment does not belong to you.")
		return true
	end

	sessions[player:getId()] = {itemUid = item.uid}
	return sendWindow(player, item)
end

function ImbuingWindow.close(player)
	clearSession(player)
end

function ImbuingWindow.sendClose(player)
	local msg = NetworkMessage(player)
	msg:addByte(CLOSE_OPCODE)
	msg:sendToPlayer(player)
	ImbuingWindow.close(player)
end

function ImbuingWindow.apply(player, slot, imbuementId, protection)
	if not isEnabled() then
		return
	end

	local item = getSessionEquipment(player)
	if not item then
		ImbuingWindow.sendClose(player)
		return
	end

	ensureDefinitions()
	local def = definitionsById[imbuementId]
	if not def then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		sendWindow(player, item)
		return
	end

	local slots = item:getImbuementSlots()
	local activeImbuements = getActiveImbuements(item)
	local firstFreeSlot = getActiveImbuementCount(activeImbuements)
	if slot < 0 or slot >= slots or slot ~= firstFreeSlot then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		sendWindow(player, item)
		return
	end

	if item:hasImbuementType(def.imbuementType) or not item:canApplyImbuement(def.categoryId, def.baseId) then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		sendWindow(player, item)
		return
	end

	for _, req in ipairs(def.items or {}) do
		if player:getItemCount(req.itemId, -1, true) < req.count then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "You do not have all required astral sources.")
			sendWindow(player, item)
			return
		end
	end

	local cost = def.price or 0
	if protection then
		cost = cost + PROTECTION_COST
	end
	if cost > 0 and player:getMoney() + player:getBankBalance() < cost then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You do not have enough gold.")
		sendWindow(player, item)
		return
	end

	local imbuement = Imbuement(def.imbuementType, def.value, def.duration, def.decayType, def.baseId)
	if not item:addImbuement(imbuement) then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Failed to apply imbuement. Unequip the item first.")
		sendWindow(player, item)
		return
	end

	for _, req in ipairs(def.items or {}) do
		player:removeItem(req.itemId, req.count, -1, true)
	end
	if cost > 0 then
		player:removeTotalMoney(cost)
	end

	player:sendTextMessage(MESSAGE_STATUS_SMALL, "Imbuement applied.")
	sendWindow(player, item)
end

function ImbuingWindow.clear(player, slot)
	if not isEnabled() then
		return
	end

	local item = getSessionEquipment(player)
	if not item then
		ImbuingWindow.sendClose(player)
		return
	end

	local imbuement = getActiveImbuements(item)[slot + 1]
	if not imbuement then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		sendWindow(player, item)
		return
	end

	local def = getDefinitionByImbuement(imbuement)
	local cost = def and def.removeCost or 0
	if cost > 0 and player:getMoney() + player:getBankBalance() < cost then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You do not have enough gold.")
		sendWindow(player, item)
		return
	end

	if not item:removeImbuement(imbuement) then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Failed to clear imbuement.")
		sendWindow(player, item)
		return
	end

	if cost > 0 then
		player:removeTotalMoney(cost)
	end

	player:sendTextMessage(MESSAGE_STATUS_SMALL, "Imbuement cleared.")
	sendWindow(player, item)
end
