local distFromMaster = 7

local globalEvent = GlobalEvent("FamiliarTeleport")
function globalEvent.onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		local playerPos = player:getPosition()
		for _, summon in ipairs(player:getSummons()) do
			local summonPos = summon:getPosition()
			if summonPos.z ~= playerPos.z or summonPos:getDistance(playerPos) > distFromMaster then
				summon:teleportTo(playerPos)
				summon:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			end
		end
	end
	return true
end

globalEvent:interval(2000)
globalEvent:register()
