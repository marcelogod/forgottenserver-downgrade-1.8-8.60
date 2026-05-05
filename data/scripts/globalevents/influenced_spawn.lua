local CONFIG = {
    maxInfluenced    = 4,
    spawnInterval    = 270,   -- 4min30s entre spawns
    expireTime       = 3600,  -- 1 hora sem morte = expira
    starLevels = {
        [1] = { hpMult = 1.50, dmgMult = 1.35, dustMin = 1,  dustMax = 3  },
        [2] = { hpMult = 1.65, dmgMult = 1.45, dustMin = 2,  dustMax = 6  },
        [3] = { hpMult = 1.80, dmgMult = 1.55, dustMin = 3,  dustMax = 9  },
        [4] = { hpMult = 1.95, dmgMult = 1.65, dustMin = 4,  dustMax = 12 },
        [5] = { hpMult = 2.10, dmgMult = 1.75, dustMin = 5,  dustMax = 15 },
    },
}

local function getFreeTile(pos, radius)
    for r = 1, radius do
        for dx = -r, r do
            for dy = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local testPos = Position(pos.x + dx, pos.y + dy, pos.z)
                    local tile = Tile(testPos)
                    if tile and not tile:hasFlag(TILESTATE_BLOCKSOLID) and not tile:getTopCreature() then
                        return testPos
                    end
                end
            end
        end
    end
    return nil
end

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

local influencedSpawn = GlobalEvent("InfluencedSpawn")
function influencedSpawn.onThink(interval)
    local influencedList = Game.getInfluencedCreatures()
    local now = os.time()

    for _, monster in ipairs(influencedList) do
        local spawnTime = monster:getStorageValue(PlayerStorageKeys.influencedSpawnTime)
        if spawnTime and spawnTime > 0 and (now - spawnTime) >= CONFIG.expireTime then
            monster:setInfluenced(false)
            monster:remove()
        end
    end

    influencedList = Game.getInfluencedCreatures()
    local count = #influencedList

    if count >= CONFIG.maxInfluenced then
        return true
    end

    local allMonsters = Game.getMonsters()
    if #allMonsters == 0 then
        return true
    end

    local candidates = {}
    for _, m in ipairs(allMonsters) do
        if not m:isInfluenced() and isCommonForgeMonster(m) then
            candidates[#candidates + 1] = m
        end
    end

    if #candidates == 0 then
        return true
    end

    local source = candidates[math.random(#candidates)]
    local sourcePos = source:getPosition()
    local freePos = getFreeTile(sourcePos, 2)

    if not freePos then
        return true
    end

    local monsterName = source:getName()
    local newMonster = Game.createMonster(monsterName, freePos, true, true)
    if not newMonster then
        return true
    end

    local level = math.random(1, 5)
    newMonster:setInfluenced(true)
    newMonster:setInfluencedLevel(level)
    newMonster:setStorageValue(PlayerStorageKeys.influencedSpawnTime, now)

    local starData = CONFIG.starLevels[level]
    local baseHP = newMonster:getMaxHealth()
    local newHP = math.floor(baseHP * starData.hpMult)
    newMonster:setMaxHealth(newHP)
    newMonster:setHealth(newHP)

    newMonster:registerEvent("InfluencedDeath")

    return true
end
influencedSpawn:interval(CONFIG.spawnInterval * 1000)
influencedSpawn:register()
