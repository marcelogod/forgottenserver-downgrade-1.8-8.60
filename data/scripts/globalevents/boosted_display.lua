local BOOSTED_DISPLAY_POS = Position(998, 992, 7)
local BOOSTED_DISPLAY_ID = 0

local function removeBoostedDisplay()
	local monster = Monster(BOOSTED_DISPLAY_ID)
	if monster then
		monster:remove()
	end
	BOOSTED_DISPLAY_ID = 0
end

local function spawnBoostedDisplay()
	removeBoostedDisplay()
	local boosted = Game.getBoostedCreature()
	if boosted == "" then
		return
	end

	local monster = Game.createMonster(boosted, BOOSTED_DISPLAY_POS, false, true)
	if not monster then
		return
	end

	monster:setDropLoot(false)
	monster:changeSpeed(-monster:getSpeed())
	BOOSTED_DISPLAY_ID = monster:getId()
end

local startupEvent = GlobalEvent("BoostedDisplayStartup")
function startupEvent.onStartup()
	addEvent(spawnBoostedDisplay, 3000)
	return true
end
startupEvent:register()

local REFRESH_INTERVAL = 60 * 1000
local midnightCheck = GlobalEvent("BoostedDisplayRefresh")

midnightCheck:interval(REFRESH_INTERVAL)
function midnightCheck.onThink(interval)
	local boosted = Game.getBoostedCreature()
	if boosted == "" then
		return true
	end

	local needRefresh = true
	local monster = Monster(BOOSTED_DISPLAY_ID)
	if monster and monster:getName():lower() == boosted:lower() then
		needRefresh = false
	end

	if needRefresh then
		spawnBoostedDisplay()
	end
	return true
end
midnightCheck:register()
