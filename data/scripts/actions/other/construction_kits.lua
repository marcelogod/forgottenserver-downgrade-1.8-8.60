local constructionKits = Action()

if not houseAutowrapItems then
	houseAutowrapItems = {}
	for i = 1, 50000 do
		local it = ItemType(i)
		if it and it:getId() ~= 0 then
			local w = it:getWrapableTo()
			if w and w ~= 0 then
				houseAutowrapItems[w] = i
			end
		end
	end
end

function constructionKits.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local kit = houseAutowrapItems[item.itemid]
	if not kit then
		return false
	end

	if fromPosition.x == CONTAINER_POSITION then
		player:sendTextMessage(MESSAGE_FAILURE, "Put the construction kit on the floor first.")
	elseif not Tile(fromPosition):getHouse() then
		player:sendTextMessage(MESSAGE_FAILURE, "You may construct this only inside a house.")
	else
		local kitId = item.itemid
		item:transform(kit)
		-- Store the kit ID so it can be wrapped back later
		item:setAttribute("wrapid", kitId)
		fromPosition:sendMagicEffect(CONST_ME_POFF)
	end
	return true
end

for id, _ in pairs(houseAutowrapItems) do
	constructionKits:id(id)
end

constructionKits:register()
