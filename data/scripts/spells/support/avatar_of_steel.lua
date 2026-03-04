local condition = Condition(CONDITION_OUTFIT)
condition:setOutfit({ lookType = AVATAR_LOOKTYPE_STEEL }) -- Avatar of Steel lookType

local spell = Spell("instant")

function spell.onCastSpell(creature, variant)
	if not creature or not creature:isPlayer() then
		return false
	end

	local grade = creature:revelationStageWOD("Avatar of Steel")
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
spell:id(264)
spell:name("Avatar of Steel")
spell:words("uteta res eq")
spell:level(300)
spell:mana(800)
spell:isPremium(true)
spell:cooldown(2 * 60 * 60 * 1000) -- Default cooldown = 2 hours
spell:groupCooldown(2 * 1000)
spell:vocation("knight", "elite knight")
spell:hasParams(true)
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
