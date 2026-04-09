local talkaction = TalkAction("/unspy")

function talkaction.onSay(player, words, param)
	if not Game.stopSpy(player:getId()) then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "You are not spying anyone.")
	end
	return false
end

talkaction:accountType(ACCOUNT_TYPE_GOD)
talkaction:access(true)
talkaction:register()
