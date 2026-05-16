local findInfluenced = TalkAction("/findinfluenced", "!findinfluenced")
local cooldowns = {}

function findInfluenced.onSay(player, words, param)
    local influencedList = Game.getInfluencedCreatures()

    if #influencedList == 0 then
        player:sendTextMessage(MESSAGE_EVENT_ORANGE,
            "There are no active influenced creatures at the moment.")
        return false
    end

    local playerPos = player:getPosition()
    local closest = nil
    local closestDist = math.huge

    for _, monster in ipairs(influencedList) do
        local mPos = monster:getPosition()
        local dist = math.abs(playerPos.x - mPos.x) + math.abs(playerPos.y - mPos.y)
                   + math.abs(playerPos.z - mPos.z) * 10
        if dist < closestDist then
            closestDist = dist
            closest = monster
        end
    end

    if not closest then
        player:sendTextMessage(MESSAGE_EVENT_ORANGE,
            "There are no active influenced creatures at the moment.")
        return false
    end

    local mPos = closest:getPosition()
    local dx = mPos.x - playerPos.x
    local dy = mPos.y - playerPos.y
    local sqmDist = math.max(math.abs(dx), math.abs(dy))

    local direction = ""
    if math.abs(dy) > math.abs(dx) then
        direction = dy < 0 and "North" or "South"
    elseif math.abs(dx) > math.abs(dy) then
        direction = dx > 0 and "East" or "West"
    else
        if dy < 0 then
            direction = dx > 0 and "Northeast" or "Northwest"
        else
            direction = dx > 0 and "Southeast" or "Southwest"
        end
    end

    local playerId = player:getId()
    local cooldown = cooldowns[playerId]
    if cooldown and cooldown > os.time() then
        local remaining = cooldown - os.time()
        player:sendCancelMessage(string.format("You must wait %d second%s before using this again.", remaining, remaining > 1 and "s" or ""))
        return false
    end

    cooldowns[playerId] = os.time() + 6

    local monsterName = closest:getName()

    player:sendTextMessage(MESSAGE_INFO_DESCR,
        string.format(
            "The nearest influenced creature: %s is to the %s, approximately %d SQMs from you.",
            monsterName, direction, sqmDist))
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
    return false
end
findInfluenced:register()
