local annihilator = Action()

local config = {
	duration = 1, -- Reset timer in minutes (kick/reset delay)
	level_req = 100, -- Minimum level required to join
	min_players = 1, -- Minimum players needed on the tiles
	lever_id = 2772, -- Item ID of the lever in idle state
	pulled_id = 2773, -- Item ID of the lever after being used

	-- MONSTER SETTINGS
	monster_skull = SKULL_RED, -- Skull type assigned to spawned monsters
	monster_emblem = GUILDEMBLEM_ENEMY, -- Guild emblem assigned to spawned monsters
	
	-- ROOM AREA & EXIT
	quest_range = {
		fromPos = Position(934, 980, 9), -- North-West (top-left) corner of the room
		toPos = Position(954, 989, 9), -- South-East (bottom-right) corner of the room
		exit = Position(953, 982, 9) -- Destination when players are kicked or finish
	}
}

local player_positions = {
	[1] = {fromPos = Position(942, 998, 9), toPos = Position(939, 986, 9)},
	[2] = {fromPos = Position(941, 998, 9), toPos = Position(938, 986, 9)},
	[3] = {fromPos = Position(940, 998, 9), toPos = Position(937, 986, 9)},
	[4] = {fromPos = Position(939, 998, 9), toPos = Position(936, 986, 9)},
}

local monsters = {
	{pos = Position(936, 984, 9), name = "Demon"},
	{pos = Position(938, 984, 9), name = "Demon"},
	{pos = Position(937, 988, 9), name = "Demon"},
	{pos = Position(939, 988, 9), name = "Demon"},
	{pos = Position(940, 986, 9), name = "Orshabaal"},
	{pos = Position(941, 986, 9), name = "Orshabaal"},
}

local function doResetAnnihilator(leverPos)
	local tile = Tile(leverPos)
	if tile then
		local lever = tile:getItemById(config.pulled_id)
		if lever then
			lever:transform(config.lever_id)
		end
	end

	-- Room cleanup logic (Monsters and remaining Players)
	for x = config.quest_range.fromPos.x, config.quest_range.toPos.x do
		for y = config.quest_range.fromPos.y, config.quest_range.toPos.y do
			local checkTile = Tile(Position(x, y, config.quest_range.fromPos.z))
			if checkTile then
				local creatures = checkTile:getCreatures()
				for _, creature in pairs(creatures) do
					if creature:isPlayer() then
						creature:teleportTo(config.quest_range.exit)
						config.quest_range.exit:sendMagicEffect(CONST_ME_TELEPORT)
						creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your time has run out!")
					elseif creature:isMonster() then
						creature:remove()
					end
				end
			end
		end
	end
end

function annihilator.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- Verify if the quest is already in progress
	if item.itemid ~= config.lever_id then
		player:sendCancelMessage("The quest is currently in use. Please wait for the reset.")
		return true
	end

	-- Security radar (check if there are players inside the defined area)
	local spectators = Game.getSpectators(config.quest_range.fromPos, false, false, 20, 20, 10, 10)
	for _, spec in pairs(spectators) do
		if spec:isPlayer() and spec:getPosition():isInRange(config.quest_range.fromPos, config.quest_range.toPos) then
			player:sendCancelMessage("A team is already inside the quest room.")
			return true
		end
	end

	local participants = {}
	local puller_found = false

	-- Check players standing on the starting tiles
	for i = 1, #player_positions do
		local tile = Tile(player_positions[i].fromPos)
		if tile then
			local creature = tile:getBottomCreature()
			if creature and creature:isPlayer() then
				if creature:getLevel() < config.level_req then
					player:sendCancelMessage(creature:getName() .. " does not have the required level.")
					return true
				end
				if creature:getGuid() == player:getGuid() then
					puller_found = true
				end
				table.insert(participants, {ptr = creature, toPos = player_positions[i].toPos})
			end
		end
	end

	-- Verify if the player pulling the lever is in a valid position
	if not puller_found then
		player:sendCancelMessage("You are not in the correct position.")
		return true
	end

	-- Validate group size
	if #participants < config.min_players then
		player:sendCancelMessage("You do not have enough players to start the quest.")
		return true
	end

	-- Spawn monsters with defined skull and emblem
	for _, mData in pairs(monsters) do
		local m = Game.createMonster(mData.name, mData.pos, false, true)
		if m then
			m:setSkull(config.monster_skull)
			m:setEmblem(config.monster_emblem)
		end
	end

	-- Teleport participants to the quest room
	for _, info in pairs(participants) do
		info.ptr:teleportTo(info.toPos)
		info.toPos:sendMagicEffect(CONST_ME_TELEPORT)
	end

	-- Transform lever and schedule the cleanup event
	item:transform(config.pulled_id)
	addEvent(doResetAnnihilator, config.duration * 60 * 1000, toPosition)
	return true
end

-- Register the action using the Action ID (default: 1940)
annihilator:aid(1940) 
annihilator:register()