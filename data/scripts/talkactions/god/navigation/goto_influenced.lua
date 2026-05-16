local gotoInfluenced = TalkAction("/gotoinfluenced")
function gotoInfluenced.onSay(player, words, param)
    local influencedList = Game.getInfluencedCreatures()

    if #influencedList == 0 then
        player:sendTextMessage(MESSAGE_EVENT_ORANGE,
            "[GM] There are no active influenced creatures at the moment.")
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
            "[GM] There are no active influenced creatures at the moment.")
        return false
    end

    local destPos = closest:getPosition()
    player:teleportTo(destPos)
    destPos:sendMagicEffect(CONST_ME_TELEPORT)

    player:sendTextMessage(MESSAGE_EVENT_ORANGE,
        string.format("[GM] Teleported to %s.", closest:getName()))

    return false
end
gotoInfluenced:separator(" ")
gotoInfluenced:accountType(6)
gotoInfluenced:access(true)
gotoInfluenced:register()
