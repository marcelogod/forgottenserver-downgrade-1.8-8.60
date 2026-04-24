local rewards = {
	[2000] = {id = 3388, count = 1},	-- demon armor
	[2001] = {id = 3288, count = 1},	-- magic sword
	[2002] = {id = 3319, count = 1},	-- stonecutter axe
	[2003] = {id = 2856, count = 1, inside = 3213},		-- present box with anihilition bear
	
	storage = 2000,
	effect = CONST_ME_TREASURE_MAP
}

local actionReward = Action()

function actionReward.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local storageStatus = player:getStorageValue(rewards.storage)
	if storageStatus ~= nil and storageStatus > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "It is empty.")
		return true
	end

	local aid = item:getActionId()
	local reward = rewards[aid]
	
	if not reward or ItemType(reward.id):getId() == 0 then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true
	end

	local totalWeight = ItemType(reward.id):getWeight(reward.count)
	if reward.inside then
		totalWeight = totalWeight + ItemType(reward.inside):getWeight(1)
	end

	local playerCap = player:getFreeCapacity()
	if playerCap < totalWeight then
		local needed = (totalWeight - playerCap) / 100
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("You do not have enough capacity. You need %.2f oz more.", needed))
		return true
	end

	local mainItem = player:addItem(reward.id, reward.count)
	if not mainItem then
		player:sendTextMessage(MESSAGE_INFO_DESCR, "You do not have enough room.")
		return true
	end

	if reward.inside then
		local success = false
		if type(mainItem) == "userdata" then
			success = pcall(function() mainItem:addItem(reward.inside, 1) end)
		end

		if not success then
			player:addItem(reward.inside, 1)
		end
	end

	player:sendTextMessage(MESSAGE_INFO_DESCR, "You have found a " .. ItemType(reward.id):getName():lower() .. ".")
	player:setStorageValue(rewards.storage, 1)
	player:getPosition():sendMagicEffect(rewards.effect)
	return true
end

for aid, _ in pairs(rewards) do
	if type(aid) == "number" then
		actionReward:aid(aid)
	end
end

actionReward:register()