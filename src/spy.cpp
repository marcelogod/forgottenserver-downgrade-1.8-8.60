// Copyright 2026 - Spy System for TFS 1.8 Downgrade by Mateuszkl 08/04/2026
// Allows GOD/ADMIN to silently observe any player in real-time.

#include "otpch.h"
#include "spy.h"

#include "game.h"
#include "player.h"
#include "container.h"
#include "protocolgame.h"
#include "protocolspectator.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <filesystem>
#include <fstream>

extern Game g_game;
SpySystem g_spy;

// ─── Keywords for PM logging ────────────────────────────────────────────
static const std::vector<std::string> SPY_KEYWORDS = {
	"pix", "cpf", "chave", "transfere", "transferencia",
	"deposita", "pagamento", "real", "reais", "conta", "banco",
	"paypal", "mercadopago", "nubank", "picpay"
};

bool SpySystem::startSpy(Player* god, Player* target) {
	if (!god || !target || god == target) {
		return false;
	}

	if (god->getAccountType() < ACCOUNT_TYPE_GOD) {
		return false;
	}

	auto godClient = god->client;
	auto targetClient = target->client;
	if (!godClient || !targetClient) {
		return false;
	}

	auto godProto = godClient->protocol();
	if (!godProto) {
		return false;
	}

	if (isSpying(god->getID())) {
		stopSpy(god);
	}

	auto session = std::make_shared<SpySession>(
		god->getID(), target->getID(), godProto);

	{
		std::lock_guard<std::mutex> lock(mutex_);
		godToSession_[god->getID()] = session;
		targetToSessions_[target->getID()].push_back(session);
	}

	targetClient->addSpyClient(godProto);

	godProto->setSpyMode(true, target->getPosition(), target->getID());

	godProto->knownCreatureSet.clear();
	godProto->sendMapDescription(target->getPosition());

	for (uint8_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
		godProto->sendInventoryItem(static_cast<slots_t>(slot),
			target->getInventoryItem(static_cast<slots_t>(slot)));
	}

	for (const auto& [cid, openContainer] : target->getOpenContainers()) {
		if (openContainer.container) {
			bool hasParent = (dynamic_cast<const Container*>(openContainer.container->getParent()) != nullptr);
			godProto->sendContainer(cid, openContainer.container, hasParent, openContainer.index);
		}
	}

	god->sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Now spying: " + target->getName() + ". Type /unspy to stop.");

	return true;
}

bool SpySystem::stopSpy(Player* god) {
	if (!god) {
		return false;
	}

	SpySessionPtr session;
	uint32_t targetPlayerId = 0;
	{
		std::lock_guard<std::mutex> lock(mutex_);
		auto it = godToSession_.find(god->getID());
		if (it == godToSession_.end()) {
			return false;
		}
		session = it->second;
		targetPlayerId = session->targetPlayerId;
	}

	Player* target = g_game.getPlayerByID(targetPlayerId);
	if (target && target->client) {
		auto godProto = session->godProtocol.lock();
		if (godProto) {
			target->client->removeSpyClient(godProto);
		}
	}

	auto godProto = session->godProtocol.lock();
	if (godProto) {
		godProto->setSpyMode(false);
		godProto->knownCreatureSet.clear();
		godProto->sendMapDescription(god->getPosition());
	}

	{
		std::lock_guard<std::mutex> lock(mutex_);
		removeSessionInternal(session);
	}

	god->sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Spy stopped.");
	return true;
}

bool SpySystem::spyInventory(Player* god, Player* target) {
	if (!god || !target) {
		return false;
	}

	if (god->getAccountType() < ACCOUNT_TYPE_GOD) {
		return false;
	}

	auto godClient = god->client;
	if (!godClient) {
		return false;
	}

	auto godProto = godClient->protocol();
	if (!godProto) {
		return false;
	}

	for (uint8_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
		godProto->sendInventoryItem(static_cast<slots_t>(slot),
			target->getInventoryItem(static_cast<slots_t>(slot)));
	}

	for (const auto& [cid, openContainer] : target->getOpenContainers()) {
		if (openContainer.container) {
			bool hasParent = (dynamic_cast<const Container*>(openContainer.container->getParent()) != nullptr);
			godProto->sendContainer(cid, openContainer.container, hasParent, openContainer.index);
		}
	}

	if (target->getOpenContainers().empty()) {
		Item* bpItem = target->getInventoryItem(CONST_SLOT_BACKPACK);
		if (bpItem) {
			Container* bp = bpItem->getContainer();
			if (bp) {
				godProto->sendContainer(0, bp, false, 0);
			}
		}
	}

	god->sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Viewing inventory of: " + target->getName());
	return true;
}

void SpySystem::onPlayerDisconnect(uint32_t playerId) {
	std::lock_guard<std::mutex> lock(mutex_);

	auto godIt = godToSession_.find(playerId);
	if (godIt != godToSession_.end()) {
		auto& session = godIt->second;
		Player* target = g_game.getPlayerByID(session->targetPlayerId);
		if (target && target->client) {
			auto godProto = session->godProtocol.lock();
			if (godProto) {
				target->client->removeSpyClient(godProto);
				godProto->setSpyMode(false);
			}
		}
		removeSessionInternal(session);
	}

	auto targetIt = targetToSessions_.find(playerId);
	if (targetIt != targetToSessions_.end()) {
		auto sessions = targetIt->second; // copy to iterate safely
		for (auto& session : sessions) {
			auto godProto = session->godProtocol.lock();
			if (godProto) {
				godProto->setSpyMode(false);
				Player* godPlayer = g_game.getPlayerByID(session->godPlayerId);
				if (godPlayer) {
					godProto->knownCreatureSet.clear();
					godProto->sendMapDescription(godPlayer->getPosition());
					godPlayer->sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
						"Spy target disconnected.");
				}
			}
			removeSessionInternal(session);
		}
	}
}

bool SpySystem::isSpying(uint32_t godPlayerId) const {
	std::lock_guard<std::mutex> lock(mutex_);
	return godToSession_.find(godPlayerId) != godToSession_.end();
}

uint32_t SpySystem::getSpyTarget(uint32_t godPlayerId) const {
	std::lock_guard<std::mutex> lock(mutex_);
	auto it = godToSession_.find(godPlayerId);
	if (it == godToSession_.end()) {
		return 0;
	}
	return it->second->targetPlayerId;
}

void SpySystem::removeSessionInternal(const SpySessionPtr& session) {
	godToSession_.erase(session->godPlayerId);

	auto it = targetToSessions_.find(session->targetPlayerId);
	if (it != targetToSessions_.end()) {
		auto& vec = it->second;
		vec.erase(std::remove(vec.begin(), vec.end(), session), vec.end());
		if (vec.empty()) {
			targetToSessions_.erase(it);
		}
	}
}

void SpySystem::checkAndLogPrivateMessage(const std::string& senderName,
                                           const std::string& receiverName,
                                           std::string_view text) {
	std::string lower(text);
	std::transform(lower.begin(), lower.end(), lower.begin(),
		[](unsigned char c) { return static_cast<char>(std::tolower(c)); });

	bool matched = false;
	for (const auto& kw : SPY_KEYWORDS) {
		if (lower.find(kw) != std::string::npos) {
			matched = true;
			break;
		}
	}

	if (!matched) {
		return;
	}

	auto now = std::chrono::system_clock::now();
	auto timeT = std::chrono::system_clock::to_time_t(now);
	struct tm tmBuf;
#ifdef _WIN32
	localtime_s(&tmBuf, &timeT);
#else
	localtime_r(&timeT, &tmBuf);
#endif

	char dateStr[11];
	char timeStr[9];
	std::strftime(dateStr, sizeof(dateStr), "%Y-%m-%d", &tmBuf);
	std::strftime(timeStr, sizeof(timeStr), "%H:%M:%S", &tmBuf);

	std::error_code ec;
	std::filesystem::create_directories("data/log/spy", ec);

	std::string logPath = "data/log/spy/private_" + std::string(dateStr) + ".log";

	std::ofstream logFile(logPath, std::ios::app);
	if (logFile.is_open()) {
		logFile << "[" << dateStr << " " << timeStr << "] "
		        << "[PRIVATE] " << senderName
		        << " -> " << receiverName
		        << ": \"" << text << "\"\n";
	}
}
