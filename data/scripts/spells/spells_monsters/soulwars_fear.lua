local combat = Combat()
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_BLUE_GHOST)

-- Substituído CONDITION_FEARED por CONDITION_DRUNK para compatibilidade 8.60
local condition = Condition(CONDITION_DRUNK)
condition:setParameter(CONDITION_PARAM_TICKS, 3000)
combat:addCondition(condition)

local function executeCombat(cid, var)
    local creature = Creature(cid)
    if not creature then
        return
    end
    return combat:execute(creature, var)
end

local spell = Spell("instant")

function spell.onCastSpell(creature, var)
    creature:getPosition():sendMagicEffect(CONST_ME_GHOST_SMOKE)
    addEvent(executeCombat, 2000, creature:getId(), var)
    return true
end

spell:name("soulwars fear")
spell:words("###611")
spell:isAggressive(true)
spell:blockWalls(true)
spell:needTarget(true)
spell:needLearn(false)
spell:register()