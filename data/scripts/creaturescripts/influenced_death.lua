local CONFIG = {
    dustItemId       = 37160,
    starLevels = {
        [1] = { dustMin = 1,  dustMax = 3  },
        [2] = { dustMin = 2,  dustMax = 6  },
        [3] = { dustMin = 3,  dustMax = 9  },
        [4] = { dustMin = 4,  dustMax = 12 },
        [5] = { dustMin = 5,  dustMax = 15 },
    },
}

local blockedNameParts = {
    "trainer",
    "training",
    "dummy",
}

local function hasBlockedName(name)
    local lowerName = name:lower()
    for _, part in ipairs(blockedNameParts) do
        if lowerName:find(part, 1, true) then
            return true
        end
    end
    return false
end

local function isCommonForgeMonster(monster)
    if not monster or monster:getMaster() then
        return false
    end

    local monsterType = monster:getType()
    if not monsterType then
        return false
    end

    if monsterType:isBoss() or monsterType:isRewardBoss() then
        return false
    end

    if not monsterType:isAttackable() or not monsterType:isHostile() then
        return false
    end

    if monsterType:experience() <= 0 then
        return false
    end

    return not hasBlockedName(monster:getName())
end

local influencedDeath = CreatureEvent("InfluencedDeath")
function influencedDeath.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    if not configManager.getBoolean(configKeys.FORGE_SYSTEM_ENABLED) then
        return true
    end

    if not creature or not creature:isMonster() then
        return true
    end

    local monster = creature:getMonster()
    if not monster or not monster:isInfluenced() then
        return true
    end

    if not isCommonForgeMonster(monster) then
        return true
    end

    local player = nil
    if mostDamageKiller and mostDamageKiller:isPlayer() then
        player = mostDamageKiller:getPlayer()
    elseif killer and killer:isPlayer() then
        player = killer:getPlayer()
    end

    if not player then
        return true
    end

    local level = monster:getInfluencedLevel()
    if level < 1 or level > 5 then
        level = 1
    end

    local starData = CONFIG.starLevels[level]
    local dustAmount = math.random(starData.dustMin, starData.dustMax)

    local currentDust = player:getStorageValue(PlayerStorageKeys.forgeDust)
    if not currentDust or currentDust < 0 then
        currentDust = 0
    end

    local dustLimit = player:getStorageValue(PlayerStorageKeys.forgeDustLimit)
    if not dustLimit or dustLimit <= 0 then
        dustLimit = 100
    end

    if currentDust >= dustLimit then
        player:sendTextMessage(MESSAGE_EVENT_ORANGE,
            "[Forge] Você atingiu o limite máximo de dust!")
        return true
    end

    if currentDust + dustAmount > dustLimit then
        dustAmount = dustLimit - currentDust
    end

    player:setStorageValue(PlayerStorageKeys.forgeDust, currentDust + dustAmount)

    if corpse and corpse:isContainer() then
        corpse:addItem(CONFIG.dustItemId, dustAmount)
    end

    local monsterName = monster:getName()
    local playerName = player:getName()
    local pos = creature:getPosition()

    local spectators = Game.getSpectators(pos, false, true, 7, 7, 5, 5)
    local msg = string.format(
        "[Sistema] Uma criatura influenciada foi derrotada! %s recebeu %d dust.",
        playerName, dustAmount)
    for _, spec in ipairs(spectators) do
        if spec:isPlayer() then
            spec:sendTextMessage(MESSAGE_EVENT_ORANGE, msg)
        end
    end

    return true
end
influencedDeath:register()
