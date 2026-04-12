local combat = Combat()
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ROOTS)

local area = createCombatArea(AREA_CIRCLE3X3)
combat:setArea(area)

local condition = Condition(CONDITION_PARALYZE)
condition:setParameter(CONDITION_PARAM_TICKS, 3000)
condition:setFormula(0, -10000, 0, -10000)
combat:addCondition(condition)

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
	return combat:execute(creature, var)
end

spell:name("root area")
spell:words("####691")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needTarget(false)
spell:needLearn(false)
spell:register()