local event = Event()
event.onLook = function(self, thing, position, distance, description)
	local minDist = 5
	if thing:isCreature() and thing:isNpc() and distance <= minDist then
		self:say("hi", TALKTYPE_PRIVATE_PN, false, thing)
		self:say("trade", TALKTYPE_PRIVATE_PN, false, thing)
		return false
	end

	local description = "You see "

	if thing:isItem() then
		description = description .. thing:getDescription(distance)
		
	else
		description = description .. thing:getDescription(distance)
		
		-- Familiar summon time display
		if thing:isCreature() and configManager.getBoolean(configKeys.FAMILIAR_SYSTEM_ENABLED) then
			local master = thing:getMaster()
			if master then
				local isFamiliar = false
				local ok, famName = pcall(function() return master:getFamiliarName() end)
				if ok and famName and famName ~= "" then
					isFamiliar = (thing:getName():lower() == famName:lower())
				else
					local summons = { "sorcerer familiar", "knight familiar", "druid familiar", "paladin familiar", "monk familiar" }
					isFamiliar = table.contains(summons, thing:getName():lower())
				end
				if isFamiliar then
					local familiarSummonTime = master:getStorageValue(STORAGE_FAMILIAR_SUMMON_TIME) or 0
					local remainingSeconds = math.floor((familiarSummonTime - os.mtime()) / 1000)
					description = description .. " (Master: " .. master:getName() .. "). \z
						It will disappear in " .. Game.getTimeInWords(remainingSeconds)
				end
			end
		end
	end

	if self:getGroup():getAccess() then
		if thing:isItem() then
			local itemType = thing:getType()
			
			description = string.format("%s\nItem ID: %d", description, thing:getId())

			local actionId = thing:getActionId()
			if actionId ~= 0 then
				description = string.format("%s, Action ID: %d", description, actionId)
			end

			local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
			if uniqueId > 0 and uniqueId < 65536 then
				description = string.format("%s, Unique ID: %d", description, uniqueId)
			end

			if thing:hasItemUID() then
				description = string.format("%s\nHASH: %s", description, thing:getItemUID())
			end

			local transformEquipId = itemType:getTransformEquipId()
			local transformDeEquipId = itemType:getTransformDeEquipId()
			if transformEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onEquip)", description, transformEquipId)
			elseif transformDeEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onDeEquip)", description, transformDeEquipId)
			end

			local decayId = itemType:getDecayId()
			if decayId ~= -1 then
				description = string.format("%s\nDecays to: %d", description, decayId)
			end
			
		elseif thing:isCreature() then
			local str = "%s\nHealth: %d / %d"
			if thing:isPlayer() and thing:getMaxMana() > 0 then
				str = string.format("%s, Mana: %d / %d", str, thing:getMana(), thing:getMaxMana())
			end
			description = string.format(str, description, thing:getHealth(), thing:getMaxHealth()) .. "."
		end

		local position = thing:getPosition()
		description = string.format(
			"%s\nPosition: %d, %d, %d",
			description, position.x, position.y, position.z
		)

		if thing:isCreature() then
			if thing:isPlayer() then
			    description = string.format("%s\nGUID: %s", description, thing:getGuid())
				description = string.format("%s\nIP: %s.", description, Game.convertIpToString(thing:getIp()))
			end
		end
	end
	return description
end
event:register()
