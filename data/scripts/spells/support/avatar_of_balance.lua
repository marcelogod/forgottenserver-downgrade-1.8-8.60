local condition = Condition(CONDITION_OUTFIT)
condition:setOutfit({ lookType = AVATAR_LOOKTYPE_BALANCE }) -- Avatar of Balance lookType

local spell = Spell("instant")

local playerCacheEvent = {}

function spell.onCastSpell(creature, variant)
	if not creature or not creature:isPlayer() then
		return false
	end

	local grade = creature:revelationStageWOD("Avatar of Balance")
	if grade == 0 then
		creature:sendCancelMessage("You cannot cast this spell")
		creature:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local duration = 15000
	condition:setTicks(duration)
	creature:getPosition():sendMagicEffect(CONST_ME_AVATAR_APPEAR)
	creature:addCondition(condition)
	creature:avatarTimer((os.time() * 1000) + duration)
	creature:reloadData()

	addEvent(function(cid)
		local c = Creature(cid)
		if c then
			c:reloadData()
		end
	end, duration, creature:getId())
	return true
end

spell:group("support")
spell:id(283)
spell:name("Avatar of Balance")
spell:words("uteta res tio")
spell:level(300)
spell:mana(1200)
spell:isPremium(false)
spell:needLearn(false)
spell:groupCooldown(2000)
spell:cooldown(7200000)
spell:vocation("monk", "exalted monk")
spell:register()
