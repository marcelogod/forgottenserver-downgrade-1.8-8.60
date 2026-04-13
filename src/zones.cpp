// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "zones.h"

#include "configmanager.h"
#include "logger.h"
#include "pugicast.h"
#include "tools.h"

namespace {
std::map<ZoneId, Zones::ZonePtr> g_zones;
std::multimap<Position, ZoneId> g_positionZones;
}

Zone::Zone(ZoneId id, std::vector<Position> positions) : id(id), positions(std::move(positions)) {}

bool Zones::registerZone(const Zones::ZonePtr& zone)
{
	if (!zone) {
		return false;
	}

	if (zone->getId() == 0) {
		LOG_WARN("[Warning - Zones::registerZone] Zone id 0 is not allowed.");
		return false;
	}

	if (zone->getPositions().empty()) {
		LOG_WARN("[Warning - Zones::registerZone] Zone {} has no positions and was skipped.", zone->getId());
		return false;
	}

	const auto [it, inserted] = g_zones.emplace(zone->getId(), zone);
	if (!inserted) {
		LOG_WARN("[Warning - Zones::registerZone] Duplicate zone id {} skipped.", zone->getId());
		return false;
	}

	for (const Position& position : zone->getPositions()) {
		g_positionZones.emplace(position, zone->getId());
	}

	return true;
}

bool Zones::loadFile(const std::filesystem::path& path)
{
	pugi::xml_document doc;
	const auto result = doc.load_file(path.string().c_str());
	if (!result) {
		printXMLError("Zones::loadFile", path.string(), result);
		return false;
	}

	auto parseZoneNode = [&path](const pugi::xml_node& zoneNode) {
		const auto idAttribute = zoneNode.attribute("id");
		if (!idAttribute) {
			LOG_WARN("[Warning - Zones::loadFile] Missing zone id in '{}'.", path.string());
			return;
		}

		const auto zoneId = pugi::cast<ZoneId>(idAttribute.value());
		if (zoneId == 0) {
			LOG_WARN("[Warning - Zones::loadFile] Zone id 0 is invalid in '{}'.", path.string());
			return;
		}

		std::vector<Position> positions;
		for (const auto& positionNode : zoneNode.children("position")) {
			const auto xAttribute = positionNode.attribute("x");
			const auto yAttribute = positionNode.attribute("y");
			const auto zAttribute = positionNode.attribute("z");

			if (!xAttribute || !yAttribute || !zAttribute) {
				LOG_WARN("[Warning - Zones::loadFile] Zone {} in '{}' has a position with missing coordinates.",
				         zoneId, path.string());
				continue;
			}

			positions.emplace_back(pugi::cast<uint16_t>(xAttribute.value()), pugi::cast<uint16_t>(yAttribute.value()),
			                       pugi::cast<uint8_t>(zAttribute.value()));
		}

		registerZone(std::make_shared<Zone>(zoneId, std::move(positions)));
	};

	if (const auto root = doc.child("zones")) {
		for (const auto& zoneNode : root.children("zone")) {
			parseZoneNode(zoneNode);
		}
		return true;
	}

	if (const auto zoneNode = doc.child("zone")) {
		parseZoneNode(zoneNode);
		return true;
	}

	LOG_ERROR("[Zones::loadFile] Invalid root node in '{}'. Expected <zones> or <zone>.", path.string());
	return false;
}

bool Zones::load()
{
	clear();

	const std::string mapName{ConfigManager::getString(ConfigManager::MAP_NAME)};
	const auto xmlFile = std::filesystem::path("data/world") / (mapName + "-zones.xml");
	const auto xmlDirectory = std::filesystem::path("data/world") / (mapName + "-zones");

	bool loadedAny = false;
	bool success = true;

	if (std::filesystem::exists(xmlFile) && std::filesystem::is_regular_file(xmlFile)) {
		loadedAny = true;
		success = loadFile(xmlFile) && success;
	}

	if (std::filesystem::exists(xmlDirectory) && std::filesystem::is_directory(xmlDirectory)) {
		std::vector<std::filesystem::path> files;
		for (const auto& entry : std::filesystem::recursive_directory_iterator(xmlDirectory)) {
			if (entry.is_regular_file() && entry.path().extension() == ".xml") {
				files.emplace_back(entry.path());
			}
		}

		std::sort(files.begin(), files.end());
		for (const auto& file : files) {
			loadedAny = true;
			success = loadFile(file) && success;
		}
	}

	if (!loadedAny) {
		LOG_INFO(">> No zone definition file found for map '{}'.", mapName);
		return true;
	}

	LOG_INFO(">> Loaded {} zone(s).", count());
	return success;
}

void Zones::clear()
{
	g_zones.clear();
	g_positionZones.clear();
}

bool Zones::reload()
{
	clear();
	return load();
}

size_t Zones::count() { return g_zones.size(); }

std::vector<Zones::ZonePtr> Zones::getAll()
{
	std::vector<Zones::ZonePtr> zones;
	zones.reserve(g_zones.size());

	for (const auto& [id, zone] : g_zones) {
		(void)id;
		zones.emplace_back(zone);
	}

	return zones;
}

Zones::ZonePtr Zones::getZone(ZoneId id)
{
	if (const auto it = g_zones.find(id); it != g_zones.end()) {
		return it->second;
	}
	return nullptr;
}

Zones::ZonePtr Zones::createZone(ZoneId id, std::vector<Position> positions)
{
	if (id == 0) {
		LOG_WARN("[Warning - Zones::createZone] Zone id 0 is not allowed.");
		return nullptr;
	}

	if (const auto existingZone = getZone(id)) {
		return existingZone;
	}

	const auto zone = std::make_shared<Zone>(id, std::move(positions));
	if (!registerZone(zone)) {
		return nullptr;
	}

	return zone;
}

std::vector<ZoneId> Zones::getZonesByPosition(const Position& position)
{
	std::vector<ZoneId> zoneIds;
	const auto [begin, end] = g_positionZones.equal_range(position);
	for (auto it = begin; it != end; ++it) {
		zoneIds.emplace_back(it->second);
	}

	std::sort(zoneIds.begin(), zoneIds.end());
	return zoneIds;
}
