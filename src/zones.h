// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_ZONES_H
#define FS_ZONES_H

#include "position.h"

#include <cstdint>
#include <filesystem>
#include <map>
#include <memory>
#include <vector>

using ZoneId = uint16_t;

class Zone
{
public:
	explicit Zone(ZoneId id, std::vector<Position> positions = {});

	ZoneId getId() const { return id; }
	const std::vector<Position>& getPositions() const { return positions; }

private:
	ZoneId id;
	std::vector<Position> positions;
};

class Zones
{
public:
	using ZonePtr = std::shared_ptr<Zone>;

	static bool load();
	static void clear();
	static bool reload();

	static size_t count();
	static std::vector<ZonePtr> getAll();
	static ZonePtr getZone(ZoneId id);
	static ZonePtr createZone(ZoneId id, std::vector<Position> positions);
	static std::vector<ZoneId> getZonesByPosition(const Position& position);

private:
	static bool registerZone(const ZonePtr& zone);
	static bool loadFile(const std::filesystem::path& path);
};

#endif // FS_ZONES_H
