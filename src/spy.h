// Copyright 2026 - Spy System for TFS 1.8 Downgrade
// Allows GOD/ADMIN to silently observe any player in real-time.
// Architecture: spy GOD protocols are added to target's ProtocolSpectator
// (similar to cast spectators). Each send method forwards to spy clients.
// GOD's ProtocolGame has spyActive_ mode which redirects canSee() to the
// target's viewport position, enabling correct creature/tile rendering.

#ifndef FS_SPY_H
#define FS_SPY_H

#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

class Player;
class ProtocolGame;
class Container;

using ProtocolGame_ptr = std::shared_ptr<ProtocolGame>;

struct SpySession {
	uint32_t godPlayerId = 0;
	uint32_t targetPlayerId = 0;
	std::weak_ptr<ProtocolGame> godProtocol;

	SpySession(uint32_t godId, uint32_t targetId, ProtocolGame_ptr godProto)
		: godPlayerId(godId), targetPlayerId(targetId),
		  godProtocol(godProto) {}
};

using SpySessionPtr = std::shared_ptr<SpySession>;

class SpySystem {
public:
	SpySystem() = default;

	SpySystem(const SpySystem&) = delete;
	SpySystem& operator=(const SpySystem&) = delete;

	bool startSpy(Player* god, Player* target);
	bool stopSpy(Player* god);
	bool spyInventory(Player* god, Player* target);

	void onPlayerDisconnect(uint32_t playerId);

	bool isSpying(uint32_t godPlayerId) const;
	uint32_t getSpyTarget(uint32_t godPlayerId) const;

	static void checkAndLogPrivateMessage(const std::string& senderName,
	                                       const std::string& receiverName,
	                                       std::string_view text);

private:

	std::unordered_map<uint32_t, SpySessionPtr> godToSession_;
	std::unordered_map<uint32_t, std::vector<SpySessionPtr>> targetToSessions_;

	mutable std::mutex mutex_;

	void removeSessionInternal(const SpySessionPtr& session);
};

extern SpySystem g_spy;

#endif // FS_SPY_H
