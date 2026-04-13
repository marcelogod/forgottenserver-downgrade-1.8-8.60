FAMILIAR_ID = {
	[VOCATION.ID.SORCERER] = { id = 994, name = "Sorcerer familiar" },
	[VOCATION.ID.DRUID] = { id = 993, name = "Druid familiar" },
	[VOCATION.ID.PALADIN] = { id = 992, name = "Paladin familiar" },
	[VOCATION.ID.KNIGHT] = { id = 991, name = "Knight familiar" },
}

FAMILIAR_TIMER = {
	[1] = { storage = PlayerStorageKeys.familiarTimer10, countdown = 10, message = "10 seconds" },
	[2] = { storage = PlayerStorageKeys.familiarTimer60, countdown = 60, message = "one minute" },
}

function SendMessageFunction(playerId, message)
	local player = Player(playerId)
	if player then
		player:sendTextMessage(MESSAGE_LOOT, "Your summon will disappear in less than " .. message)
	end
end

function RemoveFamiliar(creatureId, playerId)
	local creature = Creature(creatureId)
	local player = Player(playerId)
	if not creature or not player then
		return true
	end
	creature:remove()
	for sendMessage = 1, #FAMILIAR_TIMER do
		player:setStorageValue(FAMILIAR_TIMER[sendMessage].storage, -1)
	end
end

function Player:getFamiliarName()
	local vocationId = self:getVocation() and self:getVocation():getBaseId() or 0
	local vocation = FAMILIAR_ID[vocationId]
	local familiarName
	if vocation then
		familiarName = vocation.name
	end
	return familiarName
end

function Player:dispellFamiliar()
	local summons = self:getSummons()
	for i = 1, #summons do
		if summons[i]:getName():lower() == self:getFamiliarName():lower() then
			self:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			summons[i]:getPosition():sendMagicEffect(CONST_ME_POFF)
			summons[i]:remove()
			return true
		end
	end
	return false
end

function Player:createFamiliar(familiarName, timeLeft)
	local playerPosition = self:getPosition()
	if not familiarName then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local myFamiliar = Game.createMonster(familiarName, playerPosition, true, false)
	if not myFamiliar then
		self:sendCancelMessage(RETURNVALUE_NOTENOUGHROOM)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	myFamiliar:setMaster(self)
	myFamiliar:changeSpeed(math.max(self:getSpeed() - myFamiliar:getBaseSpeed(), 0))
	playerPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	myFamiliar:getPosition():sendMagicEffect(CONST_ME_TELEPORT)

	self:setStorageValue(PlayerStorageKeys.familiarSummonTime, os.time() + timeLeft)
	addEvent(RemoveFamiliar, timeLeft * 1000, myFamiliar:getId(), self:getId())

	for sendMessage = 1, #FAMILIAR_TIMER do
		self:setStorageValue(
			FAMILIAR_TIMER[sendMessage].storage,
			addEvent(
				SendMessageFunction,
				(timeLeft - FAMILIAR_TIMER[sendMessage].countdown) * 1000,
				self:getId(),
				FAMILIAR_TIMER[sendMessage].message
			)
		)
	end
	return true
end

function Player:CreateFamiliarSpell(spellId)
	local playerPosition = self:getPosition()
	if not self:isPremium() then
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		self:sendCancelMessage("You need a premium account.")
		return false
	end

	if #self:getSummons() >= 1 and self:getAccountType() < ACCOUNT_TYPE_GOD then
		self:sendCancelMessage("You can't have other summons.")
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local familiarName = self:getFamiliarName()
	if not familiarName then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local summonDuration = 15 * 60
	local condition = Condition(CONDITION_SPELLCOOLDOWN, CONDITIONID_DEFAULT, spellId)
	local cooldown = summonDuration * 2

	local createdSuccessfully = self:createFamiliar(familiarName, summonDuration)
	if createdSuccessfully then
		condition:setTicks(1000 * cooldown)
		self:addCondition(condition)
		return true
	end

	return false
end
