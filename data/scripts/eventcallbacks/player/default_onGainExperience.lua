local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local event = Event()

function event.onGainExperience(player, source, exp, rawExp, sendText)
	if not source or source:isPlayer() then return exp end

	-- Soul regeneration
	local vocation = player:getVocation()
	if player:getSoul() < vocation:getMaxSoul() and exp >= player:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
		player:addCondition(soulCondition)
	end

	-- Apply experience stage multiplier
	local stage = Game.getExperienceStage(player:getLevel())
	exp = exp * stage

	-- Stamina modifier
	player:updateStamina()

	-- Experience Rates
	local staminaRate = player:getExperienceRate(ExperienceRateType.STAMINA)
	if staminaRate ~= 100 then exp = exp * staminaRate / 100 end

	local baseRate = player:getExperienceRate(ExperienceRateType.BASE)
	if baseRate ~= 100 then exp = exp * baseRate / 100 end

	local lowLevelRate = player:getExperienceRate(ExperienceRateType.LOW_LEVEL)
	if lowLevelRate ~= 100 then exp = exp * lowLevelRate / 100 end

	local bonusRate = player:getExperienceRate(ExperienceRateType.BONUS)
	if bonusRate ~= 100 then exp = exp * bonusRate / 100 end

	if PreySystem and source and source:isMonster() then
		local bonusType, bonusValue = PreySystem.getBonus(player, source:getName())
		if bonusType == PreySystem.BONUS_XP then
			exp = exp + math.floor(exp * bonusValue / 100)
		end
	end

	return exp
end

event:register()


local message = Event()

local expTracker = {}

local expTrackerLogout = CreatureEvent("ExpTrackerLogout")
function expTrackerLogout.onLogout(player)
	expTracker[player:getGuid()] = nil
	return true
end

expTrackerLogout:register()

function message.onGainExperience(self, source, exp, rawExp, sendText)
	if sendText and exp ~= 0 then
		local monsterName = source and source:getName() or "Unknown"
		local playerId = self:getId()
		local playerGuid = self:getGuid()

		if not expTracker[playerGuid] then expTracker[playerGuid] = {} end
		if not expTracker[playerGuid][monsterName] then expTracker[playerGuid][monsterName] = { totalExp = 0, count = 0, timer = 0 } end

		expTracker[playerGuid][monsterName].totalExp = expTracker[playerGuid][monsterName].totalExp + exp
		expTracker[playerGuid][monsterName].count = expTracker[playerGuid][monsterName].count + 1
		expTracker[playerGuid][monsterName].timer = os.time()

		addEvent(function()
			local player = Player(playerId)
			if not player then return end

			local tracker = expTracker[playerGuid] and expTracker[playerGuid][monsterName]
			if not tracker then return end

			local expValue = math.floor(tracker.totalExp)
			local count = tracker.count

			if expValue > 0 then
				local expString = expValue .. (expValue ~= 1 and " experience points" or " experience point")

				local message = "You gained " .. expString .. " for killing "
				if count > 1 then
					message = message .. count .. " " .. monsterName .. "s."
				else
					message = message .. monsterName .. "."
				end

				player:sendTextMessage(MESSAGE_STATUS_DEFAULT, message)

				local playerInstanceId = player:getInstanceId()
				local spectators = Game.getSpectators(player:getPosition(), false, true)
				local filtered = {}
				for _, spectator in ipairs(spectators) do
					if playerInstanceId == 0 or spectator:getInstanceId() == playerInstanceId then
						table.insert(filtered, spectator)
					end
				end

				Game.sendAnimatedText(tostring(expValue), player:getPosition(), 215, filtered)

				for _, spectator in ipairs(filtered) do
					if spectator ~= player then
						spectator:sendTextMessage(MESSAGE_STATUS_DEFAULT, player:getName() .. " gained " .. expString .. " for killing " .. (count > 1 and count .. " " or "") .. monsterName .. (count > 1 and "s" or "") .. ".")
					end
				end
			end

			tracker.totalExp = 0
			tracker.count = 0
		end, 50)
	end
	return exp
end

message:register(math.huge)
