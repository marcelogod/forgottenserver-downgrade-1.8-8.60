local colorNames = {
	"white",
	"red",
	"green",
	"blue",
	"orange",
	"yellow",
	"pink",
	"purple",
	"teal",
	"gold",
}

local colors = {
	white = TEXTCOLOR_WHITE,
	red = TEXTCOLOR_RED,
	green = TEXTCOLOR_GREEN,
	blue = TEXTCOLOR_BLUE,
	orange = TEXTCOLOR_ORANGE,
	yellow = TEXTCOLOR_YELLOW,
	pink = TEXTCOLOR_PINK,
	purple = TEXTCOLOR_PURPLE,
	teal = TEXTCOLOR_TEAL,
	gold = TEXTCOLOR_GOLD,
}

local damageColor = TalkAction("/damagecolor")
function damageColor.onSay(player, words, param)
	local colorName = param:lower():gsub("^%s*(.-)%s*$", "%1")
	local color = colors[colorName]
	if not color then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /damagecolor <color>. Available colors: " .. table.concat(colorNames, ", ") .. ".")
		return false
	end

	player:setStorageValue(STORAGE_DAMAGE_COLOR, color)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Damage color changed to " .. colorName .. ".")
	return false
end
damageColor:separator(" ")
damageColor:register()
