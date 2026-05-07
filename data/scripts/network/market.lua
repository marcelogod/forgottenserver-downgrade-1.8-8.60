-- Custom Market PacketHandler
-- OTC sends 0xF4..0xF7 and 0xE0..0xE1. Server responds with 0xDB.
-- Item ids are traded directly, no wareId/ThingAttrMarket dependency.

if not configManager.getBoolean(configKeys.MARKET_SYSTEM_ENABLED) then
	CustomMarket = nil
	return
end

local MARKET_ITEM_ID = ITEM_MARKET or 12903

local OPCODE_MARKET_OPEN = 0xF4
local OPCODE_MARKET_LEAVE = 0xF5
local OPCODE_MARKET_BROWSE = 0xF6
local OPCODE_MARKET_CREATE = 0xF7
local OPCODE_MARKET_CANCEL = 0xE0
local OPCODE_MARKET_ACCEPT = 0xE1
local OPCODE_MARKET_SEND = 0xDB

local RESP_MESSAGE = 0x00
local RESP_ENTER = 0x01
local RESP_LEAVE = 0x02
local RESP_BROWSE = 0x03
local RESP_DETAIL = 0x04

local MARKET_ACTION_BUY = 0
local MARKET_ACTION_SELL = 1

local MARKET_REQUEST_MY_OFFERS = 0xFFFE
local MARKET_REQUEST_MY_HISTORY = 0xFFFF

local MARKET_STATE_ACTIVE = 0
local MARKET_STATE_CANCELLED = 1
local MARKET_STATE_EXPIRED = 2
local MARKET_STATE_ACCEPTED = 3

local MARKET_MAX_OFFERS = 100
local MARKET_MAX_AMOUNT = 2000
local MARKET_MAX_AMOUNT_STACKABLE = 64000
local MARKET_MAX_PRICE = 999999999
local MARKET_MAX_PACKET_OFFERS = 250
local MARKET_CATALOG_CHUNK_SIZE = 350
local MARKET_ACTION_DELAY = 1
local MARKET_EXPIRE_CHECK_INTERVAL = 60
local MARKET_DEFAULT_DURATION = 30 * 24 * 60 * 60
local MARKET_DEPOT_BOX_FIRST = 1
local MARKET_DEPOT_BOX_LAST = 15

local CATEGORY_ARMORS = 1
local CATEGORY_AMULETS = 2
local CATEGORY_BOOTS = 3
local CATEGORY_CONTAINERS = 4
local CATEGORY_FOOD = 6
local CATEGORY_HELMETS = 7
local CATEGORY_LEGS = 8
local CATEGORY_OTHERS = 9
local CATEGORY_POTIONS = 10
local CATEGORY_RINGS = 11
local CATEGORY_RUNES = 12
local CATEGORY_SHIELDS = 13
local CATEGORY_TOOLS = 14
local CATEGORY_VALUABLES = 15
local CATEGORY_AMMUNITION = 16
local CATEGORY_AXES = 17
local CATEGORY_CLUBS = 18
local CATEGORY_DISTANCE = 19
local CATEGORY_SWORDS = 20
local CATEGORY_WANDS = 21
local CATEGORY_GOLD = 30

local marketItems = {}
local marketItemsById = {}
local lastAction = {}
local marketDepotSessions = {}
local lastExpireCheck = 0

local blockedItems = {}
for _, itemId in ipairs({
	_G.ITEM_GOLD_COIN,
	_G.ITEM_PLATINUM_COIN,
	_G.ITEM_CRYSTAL_COIN,
	_G.ITEM_GOLD_NUGGET,
	MARKET_ITEM_ID
}) do
	if itemId then
		blockedItems[itemId] = true
	end
end

local function logInfo(message)
	if logger and logger.info then
		logger.info(message)
	else
		print(message)
	end
end

local function logError(message)
	if logger and logger.error then
		logger.error(message)
	else
		print(message)
	end
end

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

local tableExistsCache = {}

local function tableExists(name)
	if tableExistsCache[name] ~= nil then
		return tableExistsCache[name]
	end

	local exists = true
	if db.tableExists then
		exists = db.tableExists(name)
	end
	tableExistsCache[name] = exists
	return exists
end

local function ensureTables()
	db.query([[
		CREATE TABLE IF NOT EXISTS `market_offers` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`player_id` INT NOT NULL,
			`sale` TINYINT(1) NOT NULL DEFAULT 0,
			`itemtype` SMALLINT UNSIGNED NOT NULL,
			`amount` SMALLINT UNSIGNED NOT NULL,
			`created` INT UNSIGNED NOT NULL,
			`anonymous` TINYINT(1) NOT NULL DEFAULT 0,
			`price` INT UNSIGNED NOT NULL DEFAULT 0,
			PRIMARY KEY (`id`),
			KEY `idx_market_offers_itemtype_sale` (`itemtype`, `sale`),
			KEY `idx_market_offers_player` (`player_id`)
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])

	db.query([[
		CREATE TABLE IF NOT EXISTS `market_history` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`player_id` INT NOT NULL,
			`sale` TINYINT(1) NOT NULL DEFAULT 0,
			`itemtype` SMALLINT UNSIGNED NOT NULL,
			`amount` SMALLINT UNSIGNED NOT NULL,
			`price` INT UNSIGNED NOT NULL DEFAULT 0,
			`expires_at` INT UNSIGNED NOT NULL,
			`inserted` INT UNSIGNED NOT NULL,
			`state` TINYINT UNSIGNED NOT NULL,
			PRIMARY KEY (`id`),
			KEY `idx_market_history_player` (`player_id`)
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])
end

local function getOfferDuration()
	if configManager and configKeys and configKeys.MARKET_OFFER_DURATION then
		local ok, duration = pcall(function()
			return configManager.getNumber(configKeys.MARKET_OFFER_DURATION)
		end)
		duration = tonumber(ok and duration or nil)
		if duration and duration > 0 then
			return duration
		end
	end
	return MARKET_DEFAULT_DURATION
end

local function isOnCooldown(player)
	local pid = player:getId()
	local now = os.time()
	if lastAction[pid] and now - lastAction[pid] < MARKET_ACTION_DELAY then
		return true
	end
	lastAction[pid] = now
	return false
end

local function sendMarketMessage(player, message)
	local out = NetworkMessage(player)
	out:addByte(OPCODE_MARKET_SEND)
	out:addByte(RESP_MESSAGE)
	out:addString(message)
	out:sendToPlayer(player)
end

local function getItemCategory(itemType)
	if itemType:isRune() then
		return CATEGORY_RUNES
	end
	if itemType:isContainer() then
		return CATEGORY_CONTAINERS
	end
	local weaponType = itemType:getWeaponType()
	if weaponType == WEAPON_SWORD then
		return CATEGORY_SWORDS
	elseif weaponType == WEAPON_CLUB then
		return CATEGORY_CLUBS
	elseif weaponType == WEAPON_AXE then
		return CATEGORY_AXES
	elseif weaponType == WEAPON_DISTANCE then
		return CATEGORY_DISTANCE
	elseif weaponType == WEAPON_WAND then
		return CATEGORY_WANDS
	elseif weaponType == WEAPON_SHIELD then
		return CATEGORY_SHIELDS
	elseif weaponType == WEAPON_AMMO then
		return CATEGORY_AMMUNITION
	end
	if itemType:isHelmet() then
		return CATEGORY_HELMETS
	elseif itemType:isArmor() then
		return CATEGORY_ARMORS
	elseif itemType:isLegs() then
		return CATEGORY_LEGS
	elseif itemType:isBoots() then
		return CATEGORY_BOOTS
	elseif itemType:isNecklace() then
		return CATEGORY_AMULETS
	elseif itemType:isRing() then
		return CATEGORY_RINGS
	end
	if itemType:getWorth() > 0 then
		return CATEGORY_GOLD
	end

	local name = itemType:getName():lower()
	if name:find("potion", 1, true) then
		return CATEGORY_POTIONS
	elseif name:find("fish", 1, true) or name:find("meat", 1, true) or name:find("bread", 1, true) or name:find("ham", 1, true) then
		return CATEGORY_FOOD
	elseif name:find("rope", 1, true) or name:find("shovel", 1, true) or name:find("pick", 1, true) or name:find("machete", 1, true) then
		return CATEGORY_TOOLS
	elseif name:find("gem", 1, true) or name:find("crystal", 1, true) or name:find("pearl", 1, true) then
		return CATEGORY_VALUABLES
	end
	return CATEGORY_OTHERS
end

local function isMarketableItem(itemId)
	itemId = tonumber(itemId) or 0
	if itemId <= 0 or itemId > 0xFFFF or blockedItems[itemId] then
		return false
	end

	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 then
		return false
	end

	local name = itemType:getName()
	if not name or name == "" then
		return false
	end

	if itemType:isCorpse() or itemType:isDoor() or itemType:isFluidContainer() or itemType:isMagicField() or itemType:isGroundTile() then
		return false
	end

	return itemType:isMovable() and itemType:isPickupable()
end

local function addMarketItem(itemId, xmlName)
	itemId = tonumber(itemId)
	if not itemId or marketItemsById[itemId] or not isMarketableItem(itemId) then
		return
	end

	local itemType = ItemType(itemId)
	local name = xmlName or itemType:getName()
	if not name or name == "" then
		return
	end

	local entry = {
		id = itemId,
		name = name,
		category = getItemCategory(itemType)
	}

	marketItemsById[itemId] = entry
	marketItems[#marketItems + 1] = entry
end

local function loadMarketCatalog()
	marketItems = {}
	marketItemsById = {}

	local xmlDoc = XMLDocument("data/items/items.xml")
	if not xmlDoc then
		logError("[CustomMarket] Could not load data/items/items.xml")
		return
	end

	local root = xmlDoc:child("items")
	if not root then
		logError("[CustomMarket] items.xml has no root items node")
		return
	end

	for itemNode in root:children() do
		if itemNode:name() == "item" then
			local id = tonumber(itemNode:attribute("id"))
			local fromId = tonumber(itemNode:attribute("fromid"))
			local toId = tonumber(itemNode:attribute("toid"))
			local name = itemNode:attribute("name")

			if id then
				addMarketItem(id, name)
			elseif fromId and toId and toId >= fromId then
				for itemId = fromId, toId do
					addMarketItem(itemId, name)
				end
			end
		end
	end

	table.sort(marketItems, function(a, b)
		local nameA = a.name:lower()
		local nameB = b.name:lower()
		if nameA == nameB then
			return a.id < b.id
		end
		return nameA < nameB
	end)

	logInfo(string.format(">> Loading Custom Market System (%d tradeable items)", #marketItems))
end

local function getPlayerTotalMoney(player)
	local inventoryMoney = math.max(0, tonumber(player:getMoney()) or 0)
	local bankBalance = math.max(0, tonumber(player:getBankBalance()) or 0)
	return inventoryMoney + bankBalance
end

local function removePlayerMarketMoney(player, amount)
	amount = tonumber(amount) or 0
	if amount <= 0 then
		return { inventory = 0, bank = 0 }
	end

	local inventoryMoney = math.max(0, tonumber(player:getMoney()) or 0)
	local bankBalance = math.max(0, tonumber(player:getBankBalance()) or 0)
	if inventoryMoney + bankBalance < amount then
		return nil
	end

	local fromInventory = math.min(inventoryMoney, amount)
	if fromInventory > 0 and not player:removeMoney(fromInventory) then
		return nil
	end

	local fromBank = amount - fromInventory
	if fromBank > 0 then
		player:setBankBalance(bankBalance - fromBank)
	end

	return { inventory = fromInventory, bank = fromBank }
end

local function refundPlayerMarketMoney(player, payment)
	if not payment then
		return
	end
	if payment.inventory and payment.inventory > 0 then
		player:addMoney(payment.inventory)
	end
	if payment.bank and payment.bank > 0 then
		player:setBankBalance(player:getBankBalance() + payment.bank)
	end
end

local function normalizeDepotId(depotId)
	depotId = tonumber(depotId) or 0
	if depotId < 0 then
		return 0
	end
	if depotId > 0xFFFF then
		return 0xFFFF
	end
	return depotId
end

local function getPlayerLastDepotId(player)
	if player.getLastDepotId then
		local ok, depotId = pcall(function()
			return player:getLastDepotId()
		end)
		if ok then
			return normalizeDepotId(depotId)
		end
	end
	return 0
end

local function setMarketDepotId(player, depotId)
	marketDepotSessions[player:getId()] = normalizeDepotId(depotId)
end

local function getMarketDepotId(player)
	local depotId = marketDepotSessions[player:getId()]
	if depotId ~= nil then
		return depotId
	end
	return getPlayerLastDepotId(player)
end

local function getItemTradeCount(item, itemType)
	if itemType:isStackable() then
		return math.max(0, item:getCount() or 0)
	end
	return 1
end

local function getDepotBoxes(player)
	local boxes = {}
	local depotId = getMarketDepotId(player)
	for boxIndex = MARKET_DEPOT_BOX_FIRST, MARKET_DEPOT_BOX_LAST do
		local box = player:getDepotBox(depotId, boxIndex)
		if box then
			boxes[#boxes + 1] = box
		end
	end
	return boxes
end

local function getDepotItemAmount(player, itemId)
	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 then
		return 0
	end

	local amount = 0
	for _, box in ipairs(getDepotBoxes(player)) do
		for _, item in ipairs(box:getItems(true)) do
			if item:getId() == itemId then
				amount = amount + getItemTradeCount(item, itemType)
				if amount >= 0xFFFF then
					return 0xFFFF
				end
			end
		end
	end
	return clamp(amount, 0, 0xFFFF)
end

local itemTypeStackableCache = {}

local function buildDepotItemMap(player)
	local depotMap = {}
	for _, box in ipairs(getDepotBoxes(player)) do
		for _, item in ipairs(box:getItems(true)) do
			local itemId = item:getId()
			local itemTypeInfo = itemTypeStackableCache[itemId]
			if itemTypeInfo == nil then
				local itemType = ItemType(itemId)
				itemTypeInfo = {
					isStackable = itemType and itemType:isStackable() or false,
					getId = itemType and itemType:getId() or 0
				}
				itemTypeStackableCache[itemId] = itemTypeInfo
			end
			if itemTypeInfo.getId ~= 0 then
				local count = itemTypeInfo.isStackable and math.max(0, item:getCount() or 0) or 1
				local amount = (depotMap[itemId] or 0) + count
				depotMap[itemId] = math.min(amount, 0xFFFF)
			end
		end
	end
	return depotMap
end

local function addDepotItems(player, itemId, amount)
	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 or amount <= 0 then
		return false
	end

	local stackSize = math.max(1, itemType:getStackSize())
	local remaining = amount
	for _, box in ipairs(getDepotBoxes(player)) do
		while remaining > 0 do
			local count = itemType:isStackable() and math.min(remaining, stackSize) or 1
			local added = box:addItem(itemId, count)
			if not added then
				break
			end
			remaining = remaining - count
		end
		if remaining <= 0 then
			return true
		end
	end
	return false
end

local function collectDepotRemovals(player, itemId, amount)
	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 or amount <= 0 then
		return nil
	end

	local removals = {}
	local found = 0
	for _, box in ipairs(getDepotBoxes(player)) do
		for _, item in ipairs(box:getItems(true)) do
			if item:getId() == itemId then
				local count = math.min(amount - found, getItemTradeCount(item, itemType))
				if count > 0 then
					removals[#removals + 1] = { item = item, count = count }
					found = found + count
					if found >= amount then
						return removals
					end
				end
			end
		end
	end
	return nil
end

local function removeDepotItems(player, itemId, amount)
	local removals = collectDepotRemovals(player, itemId, amount)
	if not removals then
		return false
	end

	local removed = 0
	for _, entry in ipairs(removals) do
		if not entry.item:remove(entry.count) then
			if removed > 0 then
				addDepotItems(player, itemId, removed)
			end
			return false
		end
		removed = removed + entry.count
	end
	return true
end

local function getMarketOfferCount(playerId)
	if not tableExists("market_offers") then
		return 0
	end

	local resultId = db.storeQuery("SELECT COUNT(*) AS `total` FROM `market_offers` WHERE `player_id` = " .. playerId)
	if resultId == false then
		return 0
	end

	local total = result.getDataInt(resultId, "total")
	result.free(resultId)
	return total
end

local function calculateFee(price, amount)
	local fee = math.ceil((price * amount) / 100)
	if fee < 20 then
		return 20
	elseif fee > 1000 then
		return 1000
	end
	return fee
end

local function getNextInboxSid(playerId)
	local sid = 100
	local resultId = db.storeQuery("SELECT COALESCE(MAX(`sid`), 100) AS `sid` FROM `player_inboxitems` WHERE `player_id` = " .. playerId)
	if resultId ~= false then
		sid = result.getDataInt(resultId, "sid")
		result.free(resultId)
	end
	return sid + 1
end

local function insertInboxItem(playerId, itemId, amount)
	if not tableExists("player_inboxitems") then
		return false
	end

	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 then
		return false
	end

	local remaining = amount
	local sid = getNextInboxSid(playerId)
	while remaining > 0 do
		local count = 1
		if itemType:isStackable() then
			count = math.min(remaining, math.max(1, itemType:getStackSize()))
		end

		local attributes = db.escapeBlob and db.escapeBlob("", 0) or "''"
		local query = "INSERT INTO `player_inboxitems` (`player_id`, `sid`, `pid`, `itemtype`, `count`, `attributes`) VALUES (" ..
			playerId .. ", " .. sid .. ", 0, " .. itemId .. ", " .. count .. ", " .. attributes .. ")"
		if not db.query(query) then
			return false
		end

		remaining = remaining - count
		sid = sid + 1
	end
	return true
end

local function addItemToInbox(inbox, itemId, amount)
	local itemType = ItemType(itemId)
	if not inbox or not itemType or itemType:getId() == 0 or amount <= 0 then
		return false
	end

	local stackSize = math.max(1, itemType:getStackSize())
	local remaining = amount
	while remaining > 0 do
		local count = itemType:isStackable() and math.min(remaining, stackSize) or 1
		if not inbox:addItem(itemId, count, INDEX_WHEREEVER, FLAG_NOLIMIT) then
			return false
		end
		remaining = remaining - count
	end
	return true
end

local function removeInboxItems(player, itemId, amount)
	local inbox = player:getInbox()
	local itemType = ItemType(itemId)
	if not inbox or not itemType or itemType:getId() == 0 or amount <= 0 then
		return false
	end

	local removals = {}
	local found = 0
	for _, item in ipairs(inbox:getItems(true)) do
		if item:getId() == itemId then
			local count = math.min(amount - found, getItemTradeCount(item, itemType))
			if count > 0 then
				removals[#removals + 1] = { item = item, count = count }
				found = found + count
				if found >= amount then
					break
				end
			end
		end
	end

	if found < amount then
		return false
	end

	for _, entry in ipairs(removals) do
		if not entry.item:remove(entry.count) then
			return false
		end
	end
	return true
end

local function deliverItemToPlayer(playerId, playerName, itemId, amount)
	local target = playerName and Player(playerName) or nil
	if target then
		local inbox = target:getInbox()
		if addItemToInbox(inbox, itemId, amount) then
			return true
		end
	end
	return insertInboxItem(playerId, itemId, amount)
end

local function creditPlayerBank(playerId, playerName, amount)
	if amount <= 0 then
		return true
	end

	local target = playerName and Player(playerName) or nil
	if target then
		target:setBankBalance(target:getBankBalance() + amount)
		return true
	end

	return db.query("UPDATE `players` SET `balance` = `balance` + " .. amount .. " WHERE `id` = " .. playerId)
end

local function addHistory(playerId, sale, itemId, amount, price, state, created)
	if not tableExists("market_history") then
		return
	end

	local now = os.time()
	local expiresAt = (created or now) + getOfferDuration()
	db.query("INSERT INTO `market_history` (`player_id`, `sale`, `itemtype`, `amount`, `price`, `expires_at`, `inserted`, `state`) VALUES (" ..
		playerId .. ", " .. sale .. ", " .. itemId .. ", " .. amount .. ", " .. price .. ", " .. expiresAt .. ", " .. now .. ", " .. state .. ")")
end

local function fetchOfferById(offerId)
	local resultId = db.storeQuery("SELECT mo.`id`, mo.`player_id`, mo.`sale`, mo.`itemtype`, mo.`amount`, mo.`created`, mo.`anonymous`, mo.`price`, p.`name` AS `player_name` FROM `market_offers` mo INNER JOIN `players` p ON p.`id` = mo.`player_id` WHERE mo.`id` = " .. offerId .. " LIMIT 1")
	if resultId == false then
		return nil
	end

	local offer = {
		id = result.getDataInt(resultId, "id"),
		playerId = result.getDataInt(resultId, "player_id"),
		sale = result.getDataInt(resultId, "sale"),
		itemId = result.getDataInt(resultId, "itemtype"),
		amount = result.getDataInt(resultId, "amount"),
		created = result.getDataInt(resultId, "created"),
		anonymous = result.getDataInt(resultId, "anonymous") ~= 0,
		price = result.getDataInt(resultId, "price"),
		playerName = result.getDataString(resultId, "player_name")
	}
	result.free(resultId)
	return offer
end

local function fetchOffers(query)
	local offers = {}
	local resultId = db.storeQuery(query)
	if resultId == false then
		return offers
	end

	repeat
		offers[#offers + 1] = {
			id = result.getDataInt(resultId, "id"),
			playerId = result.getDataInt(resultId, "player_id"),
			sale = result.getDataInt(resultId, "sale"),
			itemId = result.getDataInt(resultId, "itemtype"),
			amount = result.getDataInt(resultId, "amount"),
			created = result.getDataInt(resultId, "created"),
			anonymous = result.getDataInt(resultId, "anonymous") ~= 0,
			price = result.getDataInt(resultId, "price"),
			playerName = result.getDataString(resultId, "player_name"),
			state = MARKET_STATE_ACTIVE
		}
	until not result.next(resultId)

	result.free(resultId)
	return offers
end

local function fetchHistory(playerId)
	local offers = {}
	if not tableExists("market_history") then
		return offers
	end

	local resultId = db.storeQuery("SELECT `id`, `player_id`, `sale`, `itemtype`, `amount`, `price`, `inserted`, `state` FROM `market_history` WHERE `player_id` = " .. playerId .. " ORDER BY `inserted` DESC LIMIT " .. MARKET_MAX_PACKET_OFFERS)
	if resultId == false then
		return offers
	end

	repeat
		offers[#offers + 1] = {
			id = result.getDataInt(resultId, "id"),
			playerId = result.getDataInt(resultId, "player_id"),
			sale = result.getDataInt(resultId, "sale"),
			itemId = result.getDataInt(resultId, "itemtype"),
			amount = result.getDataInt(resultId, "amount"),
			created = result.getDataInt(resultId, "inserted"),
			anonymous = false,
			price = result.getDataInt(resultId, "price"),
			playerName = "",
			state = result.getDataInt(resultId, "state")
		}
	until not result.next(resultId)

	result.free(resultId)
	return offers
end

local function writeOffer(out, offer)
	out:addU32(offer.id)
	out:addU32(offer.created)
	out:addU16(offer.itemId)
	out:addU16(clamp(offer.amount, 0, 0xFFFF))
	out:addU32(clamp(offer.price, 0, MARKET_MAX_PRICE))
	out:addString(offer.anonymous and "Anonymous" or (offer.playerName or ""))
	out:addByte(offer.state or MARKET_STATE_ACTIVE)
end

local function sendMarketBrowse(player, browseId)
	browseId = tonumber(browseId) or 0

	local buyOffers = {}
	local sellOffers = {}
	local playerId = player:getGuid()

	if browseId == MARKET_REQUEST_MY_OFFERS then
		local query = "SELECT mo.`id`, mo.`player_id`, mo.`sale`, mo.`itemtype`, mo.`amount`, mo.`created`, mo.`anonymous`, mo.`price`, p.`name` AS `player_name` FROM `market_offers` mo INNER JOIN `players` p ON p.`id` = mo.`player_id` WHERE mo.`player_id` = " .. playerId .. " ORDER BY mo.`created` DESC LIMIT " .. MARKET_MAX_PACKET_OFFERS
		for _, offer in ipairs(fetchOffers(query)) do
			if offer.sale == MARKET_ACTION_BUY then
				buyOffers[#buyOffers + 1] = offer
			else
				sellOffers[#sellOffers + 1] = offer
			end
		end
	elseif browseId == MARKET_REQUEST_MY_HISTORY then
		for _, offer in ipairs(fetchHistory(playerId)) do
			if offer.sale == MARKET_ACTION_BUY then
				buyOffers[#buyOffers + 1] = offer
			else
				sellOffers[#sellOffers + 1] = offer
			end
		end
	elseif marketItemsById[browseId] then
		buyOffers = fetchOffers("SELECT mo.`id`, mo.`player_id`, mo.`sale`, mo.`itemtype`, mo.`amount`, mo.`created`, mo.`anonymous`, mo.`price`, p.`name` AS `player_name` FROM `market_offers` mo INNER JOIN `players` p ON p.`id` = mo.`player_id` WHERE mo.`itemtype` = " .. browseId .. " AND mo.`sale` = " .. MARKET_ACTION_BUY .. " ORDER BY mo.`price` DESC, mo.`created` ASC LIMIT " .. MARKET_MAX_PACKET_OFFERS)
		sellOffers = fetchOffers("SELECT mo.`id`, mo.`player_id`, mo.`sale`, mo.`itemtype`, mo.`amount`, mo.`created`, mo.`anonymous`, mo.`price`, p.`name` AS `player_name` FROM `market_offers` mo INNER JOIN `players` p ON p.`id` = mo.`player_id` WHERE mo.`itemtype` = " .. browseId .. " AND mo.`sale` = " .. MARKET_ACTION_SELL .. " ORDER BY mo.`price` ASC, mo.`created` ASC LIMIT " .. MARKET_MAX_PACKET_OFFERS)
	else
		sendMarketMessage(player, "This item cannot be traded on the market.")
		return
	end

	local out = NetworkMessage(player)
	out:addByte(OPCODE_MARKET_SEND)
	out:addByte(RESP_BROWSE)
	out:addU16(browseId)
	out:addU16(#buyOffers)
	for _, offer in ipairs(buyOffers) do
		writeOffer(out, offer)
	end
	out:addU16(#sellOffers)
	for _, offer in ipairs(sellOffers) do
		writeOffer(out, offer)
	end
	out:sendToPlayer(player)
end

local offerCountCache = {}

local function sendMarketEnter(player, depotMap)
	local balance = getPlayerTotalMoney(player)
	local playerGuid = player:getGuid()
	local offers = offerCountCache[playerGuid]
	if offers == nil then
		offers = clamp(getMarketOfferCount(playerGuid), 0, MARKET_MAX_OFFERS)
		offerCountCache[playerGuid] = offers
	end
	local totalItems = #marketItems
	local chunkIndex = 0
	depotMap = depotMap or buildDepotItemMap(player)

	for offset = 1, math.max(totalItems, 1), MARKET_CATALOG_CHUNK_SIZE do
		local chunkEnd = math.min(offset + MARKET_CATALOG_CHUNK_SIZE - 1, totalItems)
		local chunkCount = totalItems == 0 and 0 or (chunkEnd - offset + 1)
		local out = NetworkMessage(player)
		out:addByte(OPCODE_MARKET_SEND)
		out:addByte(RESP_ENTER)
		out:addU64(balance)
		out:addU16(offers)
		out:addU16(chunkIndex)
		out:addByte(chunkEnd >= totalItems and 1 or 0)
		out:addU16(chunkCount)

		for i = offset, chunkEnd do
			local entry = marketItems[i]
			out:addU16(entry.id)
			out:addByte(entry.category)
			out:addString(entry.name)
			out:addU16(math.min(depotMap[entry.id] or 0, 0xFFFF))
		end

		out:sendToPlayer(player)
		chunkIndex = chunkIndex + 1
	end
end

local function sendMarketDetail(player, itemId)
	local out = NetworkMessage(player)
	out:addByte(OPCODE_MARKET_SEND)
	out:addByte(RESP_DETAIL)
	out:addU16(itemId)
	out:addByte(0)
	out:addByte(0)
	out:sendToPlayer(player)
end

local function refreshMarket(player, browseId, depotMap)
	sendMarketEnter(player, depotMap)
	if browseId then
		sendMarketBrowse(player, browseId)
	end
end

local function expireOffers()
	local now = os.time()
	if now - lastExpireCheck < MARKET_EXPIRE_CHECK_INTERVAL or not tableExists("market_offers") then
		return
	end
	lastExpireCheck = now

	local expiredBefore = now - getOfferDuration()
	local offers = fetchOffers("SELECT mo.`id`, mo.`player_id`, mo.`sale`, mo.`itemtype`, mo.`amount`, mo.`created`, mo.`anonymous`, mo.`price`, p.`name` AS `player_name` FROM `market_offers` mo INNER JOIN `players` p ON p.`id` = mo.`player_id` WHERE mo.`created` <= " .. expiredBefore .. " ORDER BY mo.`created` ASC LIMIT 100")
	for _, offer in ipairs(offers) do
		local returned = true
		if offer.sale == MARKET_ACTION_BUY then
			returned = creditPlayerBank(offer.playerId, offer.playerName, offer.price * offer.amount)
		else
			returned = deliverItemToPlayer(offer.playerId, offer.playerName, offer.itemId, offer.amount)
		end

		if returned then
			db.query("DELETE FROM `market_offers` WHERE `id` = " .. offer.id)
			offerCountCache[offer.playerId] = nil
			addHistory(offer.playerId, offer.sale, offer.itemId, offer.amount, offer.price, MARKET_STATE_EXPIRED, offer.created)
		else
			logError("[CustomMarket] Failed to return expired offer " .. offer.id)
		end
	end
end

local function validateOfferPayload(player, actionType, itemId, amount, price)
	if actionType ~= MARKET_ACTION_BUY and actionType ~= MARKET_ACTION_SELL then
		return false, "Invalid offer type."
	end

	if not marketItemsById[itemId] then
		return false, "This item cannot be traded on the market."
	end

	local itemType = ItemType(itemId)
	local maxAmount = itemType:isStackable() and MARKET_MAX_AMOUNT_STACKABLE or MARKET_MAX_AMOUNT
	if amount <= 0 or amount > maxAmount then
		return false, "Invalid amount."
	end

	if price <= 0 or price > MARKET_MAX_PRICE or price * amount > MARKET_MAX_PRICE then
		return false, "Invalid price."
	end

	if getMarketOfferCount(player:getGuid()) >= MARKET_MAX_OFFERS then
		return false, "You have too many active market offers."
	end

	return true
end

local openHandler = PacketHandler(OPCODE_MARKET_OPEN)
function openHandler.onReceive(player, msg)
	setMarketDepotId(player, getPlayerLastDepotId(player))
	expireOffers()
	sendMarketEnter(player)
end
openHandler:register()

local leaveHandler = PacketHandler(OPCODE_MARKET_LEAVE)
function leaveHandler.onReceive(player, msg)
	local out = NetworkMessage(player)
	out:addByte(OPCODE_MARKET_SEND)
	out:addByte(RESP_LEAVE)
	out:sendToPlayer(player)
end
leaveHandler:register()

local browseHandler = PacketHandler(OPCODE_MARKET_BROWSE)
function browseHandler.onReceive(player, msg)
	if msg:len() - msg:tell() < 2 then
		return
	end

	expireOffers()
	sendMarketBrowse(player, msg:getU16())
end
browseHandler:register()

local createHandler = PacketHandler(OPCODE_MARKET_CREATE)
function createHandler.onReceive(player, msg)
	if msg:len() - msg:tell() < 10 then
		return
	end
	if isOnCooldown(player) then
		sendMarketMessage(player, "Please wait before creating another offer.")
		return
	end

	expireOffers()

	local actionType = msg:getByte()
	local itemId = msg:getU16()
	local amount = msg:getU16()
	local price = msg:getU32()
	local anonymous = msg:getByte() ~= 0 and 1 or 0

	local valid, errorMessage = validateOfferPayload(player, actionType, itemId, amount, price)
	if not valid then
		sendMarketMessage(player, errorMessage)
		return
	end

	local totalPrice = price * amount
	local fee = calculateFee(price, amount)
	local payment = nil
	local depotMap = nil

	if actionType == MARKET_ACTION_BUY then
		if getPlayerTotalMoney(player) < totalPrice + fee then
			sendMarketMessage(player, "You do not have enough money for this buy offer.")
			return
		end
		payment = removePlayerMarketMoney(player, totalPrice + fee)
		if not payment then
			sendMarketMessage(player, "You do not have enough money for this buy offer.")
			return
		end
	else
		depotMap = buildDepotItemMap(player)
		if (depotMap[itemId] or 0) < amount then
			sendMarketMessage(player, "You do not have enough items for this sell offer.")
			return
		end
		if getPlayerTotalMoney(player) < fee then
			sendMarketMessage(player, "You do not have enough money to pay the market fee.")
			return
		end
		if not removeDepotItems(player, itemId, amount) then
			sendMarketMessage(player, "Could not reserve the items for this sell offer.")
			return
		end
		depotMap[itemId] = math.max(0, (depotMap[itemId] or 0) - amount)
		payment = removePlayerMarketMoney(player, fee)
		if not payment then
			addDepotItems(player, itemId, amount)
			sendMarketMessage(player, "Could not pay the market fee.")
			return
		end
	end

	local now = os.time()
	local ok = db.query("INSERT INTO `market_offers` (`player_id`, `sale`, `itemtype`, `amount`, `created`, `anonymous`, `price`) VALUES (" ..
		player:getGuid() .. ", " .. actionType .. ", " .. itemId .. ", " .. amount .. ", " .. now .. ", " .. anonymous .. ", " .. price .. ")")
	if not ok then
		if actionType == MARKET_ACTION_BUY then
			refundPlayerMarketMoney(player, payment)
		else
			addDepotItems(player, itemId, amount)
			refundPlayerMarketMoney(player, payment)
		end
		sendMarketMessage(player, "Could not create the market offer.")
		return
	end

	offerCountCache[player:getGuid()] = nil
	sendMarketMessage(player, "Market offer created.")
	refreshMarket(player, itemId, depotMap)
end
createHandler:register()

local cancelHandler = PacketHandler(OPCODE_MARKET_CANCEL)
function cancelHandler.onReceive(player, msg)
	if msg:len() - msg:tell() < 4 then
		return
	end
	if isOnCooldown(player) then
		sendMarketMessage(player, "Please wait before cancelling another offer.")
		return
	end

	expireOffers()

	local offerId = msg:getU32()
	local offer = fetchOfferById(offerId)
	if not offer or offer.playerId ~= player:getGuid() then
		sendMarketMessage(player, "Market offer not found.")
		return
	end

	if not db.query("DELETE FROM `market_offers` WHERE `id` = " .. offer.id .. " AND `player_id` = " .. player:getGuid()) then
		sendMarketMessage(player, "Could not cancel the market offer.")
		return
	end
	offerCountCache[player:getGuid()] = nil

	if offer.sale == MARKET_ACTION_BUY then
		player:setBankBalance(player:getBankBalance() + offer.price * offer.amount)
	else
		player:addItem(offer.itemId, offer.amount, true)
	end

	addHistory(player:getGuid(), offer.sale, offer.itemId, offer.amount, offer.price, MARKET_STATE_CANCELLED, offer.created)
	sendMarketMessage(player, "Market offer cancelled.")
	refreshMarket(player, MARKET_REQUEST_MY_OFFERS)
end
cancelHandler:register()

local acceptHandler = PacketHandler(OPCODE_MARKET_ACCEPT)
function acceptHandler.onReceive(player, msg)
	if msg:len() - msg:tell() < 6 then
		return
	end
	if isOnCooldown(player) then
		sendMarketMessage(player, "Please wait before accepting another offer.")
		return
	end

	expireOffers()

	local offerId = msg:getU32()
	local amount = msg:getU16()
	local offer = fetchOfferById(offerId)
	if not offer then
		sendMarketMessage(player, "Market offer not found.")
		return
	end

	amount = clamp(amount, 1, offer.amount)
	if offer.playerId == player:getGuid() then
		sendMarketMessage(player, "You cannot accept your own market offer.")
		return
	end

	local totalPrice = amount * offer.price
	local depotMap = nil
	if offer.sale == MARKET_ACTION_SELL then
		if getPlayerTotalMoney(player) < totalPrice then
			sendMarketMessage(player, "You do not have enough money.")
			return
		end
		local payment = removePlayerMarketMoney(player, totalPrice)
		if not payment then
			sendMarketMessage(player, "You do not have enough money.")
			return
		end
		if not deliverItemToPlayer(player:getGuid(), player:getName(), offer.itemId, amount) then
			refundPlayerMarketMoney(player, payment)
			sendMarketMessage(player, "Could not deliver the item.")
			return
		end
		if not creditPlayerBank(offer.playerId, offer.playerName, totalPrice) then
			if not removeInboxItems(player, offer.itemId, amount) then
				logError("[CustomMarket] Failed to rollback inbox delivery for offer " .. offer.id .. " and player " .. player:getName())
			end
			refundPlayerMarketMoney(player, payment)
			sendMarketMessage(player, "Could not credit the seller.")
			return
		end
	else
		depotMap = buildDepotItemMap(player)
		if (depotMap[offer.itemId] or 0) < amount then
			sendMarketMessage(player, "You do not have enough items.")
			return
		end
		if not removeDepotItems(player, offer.itemId, amount) then
			sendMarketMessage(player, "Could not remove the items.")
			return
		end
		depotMap[offer.itemId] = math.max(0, (depotMap[offer.itemId] or 0) - amount)
		if not deliverItemToPlayer(offer.playerId, offer.playerName, offer.itemId, amount) then
			addDepotItems(player, offer.itemId, amount)
			sendMarketMessage(player, "Could not deliver the item to the buyer.")
			return
		end
		player:setBankBalance(player:getBankBalance() + totalPrice)
	end

	if amount == offer.amount then
		db.query("DELETE FROM `market_offers` WHERE `id` = " .. offer.id)
		offerCountCache[offer.playerId] = nil
	else
		db.query("UPDATE `market_offers` SET `amount` = `amount` - " .. amount .. " WHERE `id` = " .. offer.id)
	end

	addHistory(offer.playerId, offer.sale, offer.itemId, amount, offer.price, MARKET_STATE_ACCEPTED, offer.created)
	sendMarketMessage(player, "Market offer accepted.")
	refreshMarket(player, offer.itemId, depotMap)

	local owner = Player(offer.playerName)
	if owner then
		sendMarketMessage(owner, "One of your market offers was accepted.")
		refreshMarket(owner, MARKET_REQUEST_MY_OFFERS)
	end
end
acceptHandler:register()

local marketSessionCleanup = CreatureEvent("CustomMarketSessionCleanup")
function marketSessionCleanup.onLogout(player)
	lastAction[player:getId()] = nil
	marketDepotSessions[player:getId()] = nil
	return true
end
marketSessionCleanup:register()

local marketSessionInit = CreatureEvent("CustomMarketSessionInit")
function marketSessionInit.onLogin(player)
	player:registerEvent("CustomMarketSessionCleanup")
	return true
end
marketSessionInit:register()

ensureTables()
loadMarketCatalog()

CustomMarket = {
	open = function(player, depotId)
		setMarketDepotId(player, depotId or getPlayerLastDepotId(player))
		expireOffers()
		sendMarketEnter(player)
	end,
	browse = sendMarketBrowse
}
